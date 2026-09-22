# Heart failure survival analysis
#
# Outcome: all-cause death during follow-up (DEATH_EVENT = 1).
# People with DEATH_EVENT = 0 are right-censored at their recorded follow-up
# time. This is a prognostic analysis: hazard ratios are associations, not
# causal treatment effects.

# Install once, if needed:
# install.packages(c("ggplot2", "survival"))

library(ggplot2)
library(survival)

# Run this script with the project folder as the working directory.
data_file <- "df.csv"
output_dir <- "outputs"
dir.create(output_dir, showWarnings = FALSE)

if (!file.exists(data_file)) {
  stop("df.csv was not found. Run the script from the project folder.")
}

df <- read.csv(data_file)

# Check that the source data contain the variables used below.
required_variables <- c(
  "age", "sex", "anaemia", "diabetes", "ejection_fraction",
  "serum_creatinine", "serum_sodium", "time", "DEATH_EVENT"
)

missing_variables <- setdiff(required_variables, names(df))
if (length(missing_variables) > 0) {
  stop("Missing variables: ", paste(missing_variables, collapse = ", "))
}

if (anyNA(df$DEATH_EVENT) || !all(df$DEATH_EVENT %in% c(0, 1))) {
  stop("DEATH_EVENT must be coded 0 (censored) or 1 (death).")
}

# Document missingness before restricting the analysis data.
missingness <- data.frame(
  variable = names(df),
  missing_n = colSums(is.na(df)),
  missing_percent = 100 * colMeans(is.na(df))
)
write.csv(missingness, file.path(output_dir, "missingness.csv"), row.names = FALSE)

analysis_data <- df[, required_variables]
if (anyNA(analysis_data)) {
  stop("The analysis variables contain missing values. Review outputs/missingness.csv first.")
}

# Labels make the regression output and descriptive tables easier to read.
analysis_data$sex <- factor(analysis_data$sex, levels = c(0, 1),
                            labels = c("Female", "Male"))
analysis_data$anaemia <- factor(analysis_data$anaemia, levels = c(0, 1),
                                labels = c("No", "Yes"))
analysis_data$diabetes <- factor(analysis_data$diabetes, levels = c(0, 1),
                                 labels = c("No", "Yes"))

# Median (IQR) is used because several continuous variables are skewed or
# recorded at a limited set of values.
continuous_variables <- c(
  "age", "ejection_fraction", "serum_creatinine", "serum_sodium", "time"
)

continuous_summary <- data.frame(
  variable = continuous_variables,
  median = sapply(analysis_data[continuous_variables], median),
  q1 = sapply(analysis_data[continuous_variables], quantile, probs = 0.25),
  q3 = sapply(analysis_data[continuous_variables], quantile, probs = 0.75)
)
write.csv(continuous_summary, file.path(output_dir, "continuous_summary.csv"), row.names = FALSE)

binary_variables <- c("sex", "anaemia", "diabetes")
categorical_summary <- do.call(rbind, lapply(binary_variables, function(variable) {
  counts <- table(analysis_data[[variable]])
  data.frame(
    variable = variable,
    category = names(counts),
    n = as.integer(counts),
    percent = round(100 * as.integer(counts) / nrow(analysis_data), 1)
  )
}))
write.csv(categorical_summary, file.path(output_dir, "categorical_summary.csv"), row.names = FALSE)

# Histograms for the continuous predictors used in the Cox model.
histogram_widths <- c(
  age = 5,
  ejection_fraction = 5,
  serum_creatinine = 0.2,
  serum_sodium = 1
)

for (variable in names(histogram_widths)) {
  histogram <- ggplot(analysis_data, aes(x = .data[[variable]])) +
    geom_histogram(binwidth = histogram_widths[[variable]], colour = "white") +
    labs(
      title = paste("Distribution of", variable),
      x = variable,
      y = "Number of patients"
    ) +
    theme_minimal()

  ggsave(
    filename = file.path(output_dir, paste0("histogram_", variable, ".png")),
    plot = histogram,
    width = 6,
    height = 4,
    dpi = 300
  )
}

# Kaplan-Meier analysis. The time unit in the source data is days.
surv_object <- Surv(time = analysis_data$time, event = analysis_data$DEATH_EVENT)
km_fit <- survfit(surv_object ~ 1, data = analysis_data)

png(file.path(output_dir, "kaplan_meier_overall.png"), width = 1800, height = 1300, res = 220)
plot(
  km_fit,
  xlab = "Follow-up time (days)",
  ylab = "Probability of survival",
  main = "Overall Kaplan-Meier survival curve",
  conf.int = TRUE,
  mark.time = TRUE
)
dev.off()

km_points <- summary(km_fit, times = c(30, 90, 180, 240), extend = TRUE)
km_milestones <- data.frame(
  time_days = km_points$time,
  n_at_risk = km_points$n.risk,
  survival = km_points$surv,
  lower_95 = km_points$lower,
  upper_95 = km_points$upper
)
write.csv(km_milestones, file.path(output_dir, "kaplan_meier_milestones.csv"), row.names = FALSE)

# Cox model. Continuous predictors are initially modeled linearly on the
# log-hazard scale; proportional-hazards diagnostics are assessed below.
cox_model <- coxph(
  surv_object ~ age + sex + anaemia + diabetes +
    ejection_fraction + serum_creatinine + serum_sodium,
  data = analysis_data
)

cox_summary <- summary(cox_model)
cox_results <- data.frame(
  predictor = rownames(cox_summary$coefficients),
  hazard_ratio = cox_summary$conf.int[, "exp(coef)"],
  lower_95 = cox_summary$conf.int[, "lower .95"],
  upper_95 = cox_summary$conf.int[, "upper .95"],
  p_value = cox_summary$coefficients[, "Pr(>|z|)"],
  row.names = NULL
)
write.csv(cox_results, file.path(output_dir, "cox_model_results.csv"), row.names = FALSE)

# Schoenfeld-residual test for the proportional-hazards assumption.
ph_check <- cox.zph(cox_model)
ph_results <- data.frame(
  predictor = rownames(ph_check$table),
  ph_check$table,
  row.names = NULL,
  check.names = FALSE
)
write.csv(ph_results, file.path(output_dir, "proportional_hazards_check.csv"), row.names = FALSE)

png(file.path(output_dir, "proportional_hazards_diagnostics.png"),
    width = 1800, height = 1600, res = 220)
par(mfrow = c(3, 3))
plot(ph_check)
dev.off()

message("Analysis complete. Results and figures are saved in outputs/.")
