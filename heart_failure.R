# Heart failure survival analysis
#
# Outcome: all-cause death during follow-up (DEATH_EVENT = 1).
# People with DEATH_EVENT = 0 are right-censored at their recorded follow-up
# time.

library(gtsummary)
library(survival)

data_file <- "df.csv"
output_dir <- "outputs"
dir.create(output_dir, showWarnings = FALSE)

df <- read.csv(data_file)

# Keep the variables used in Table 1 and the survival models.
analysis_data <- df[c(
  "age", "sex", "anaemia", "diabetes", "ejection_fraction",
  "serum_creatinine", "serum_sodium", "time", "DEATH_EVENT"
)]

# Labels to make the regression output and descriptive tables easier to read.
analysis_data$sex <- factor(analysis_data$sex, levels = c(0, 1),
                            labels = c("Female", "Male"))
analysis_data$anaemia <- factor(analysis_data$anaemia, levels = c(0, 1),
                                labels = c("No", "Yes"))
analysis_data$diabetes <- factor(analysis_data$diabetes, levels = c(0, 1),
                                 labels = c("No", "Yes"))

# Simple histograms for the initial descriptive review.
hist(analysis_data$age, main = "Age", xlab = "Years", breaks = 10)
hist(analysis_data$ejection_fraction,
     main = "Ejection fraction", xlab = "Percent", breaks = 10)
hist(analysis_data$serum_creatinine,
     main = "Serum creatinine", xlab = "Recorded value", breaks = 10)
hist(analysis_data$serum_sodium,
     main = "Serum sodium", xlab = "Recorded value", breaks = 10)

# Table 1: baseline patient characteristics.
table1 <- tbl_summary(
  data = analysis_data[c(
    "age", "sex", "anaemia", "diabetes",
    "ejection_fraction", "serum_creatinine", "serum_sodium"
  )],
  statistic = list(
    all_continuous() ~ "{median} ({p25}, {p75})",
    all_categorical() ~ "{n} ({p}%)"
  ),
  label = list(
    age ~ "Age, years",
    sex ~ "Sex",
    anaemia ~ "Anaemia",
    diabetes ~ "Diabetes",
    ejection_fraction ~ "Ejection fraction, %",
    serum_creatinine ~ "Serum creatinine",
    serum_sodium ~ "Serum sodium"
  )
)

table1 <- bold_labels(table1)
print(table1)

# Save a simple version of Table 1 that can be viewed on GitHub.
table1_csv <- as_tibble(table1)
write.csv(table1_csv, file.path(output_dir, "table1_baseline_characteristics.csv"), row.names = FALSE)

# Follow-up time is not a baseline characteristic, so it is reported separately.
follow_up_summary <- data.frame(
  variable = "follow_up_time_days",
  median = median(analysis_data$time),
  q1 = quantile(analysis_data$time, 0.25),
  q3 = quantile(analysis_data$time, 0.75)
)
write.csv(follow_up_summary, file.path(output_dir, "follow_up_summary.csv"), row.names = FALSE)

# Kaplan-Meier survival curve.
surv_object <- Surv(time = analysis_data$time, event = analysis_data$DEATH_EVENT)
km_fit <- survfit(surv_object ~ 1, data = analysis_data)

plot(
  km_fit,
  xlab = "Follow-up time (days)",
  ylab = "Probability of survival",
  main = "Overall Kaplan-Meier survival curve",
  conf.int = TRUE
)

# Cox proportional-hazards model.
cox_model <- coxph(
  surv_object ~ age + sex + anaemia + diabetes +
    ejection_fraction + serum_creatinine + serum_sodium,
  data = analysis_data
)

summary(cox_model)
