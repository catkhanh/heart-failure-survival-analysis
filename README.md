# Heart Failure Survival Analysis

A reproducible survival-analysis project using the Heart Failure Clinical Records dataset. The aim is to describe mortality during follow-up and evaluate baseline factors associated with the hazard of death.

## Data

- **Dataset:** [Heart Failure Clinical Records](https://archive.ics.uci.edu/dataset/519/heart+failure+clinical+records), UCI Machine Learning Repository
- **Participants:** 299 patients with heart failure
- **Outcome:** all-cause death during follow-up (`DEATH_EVENT`: 1 = death, 0 = censored)
- **Follow-up:** `time`, measured in days; observed range 4 to 285 days
- **Source paper:** Chicco D, Jurman G. *Machine learning can predict survival of patients with heart failure from serum creatinine and ejection fraction alone.* BMC Medical Informatics and Decision Making. 2020;20:16. [https://doi.org/10.1186/s12911-020-1023-5](https://doi.org/10.1186/s12911-020-1023-5)

The file `df.csv` is the analysis dataset. Variable definitions are available on the UCI dataset page.

## Methods

1. Audit missing data and produce descriptive summaries.
2. Draw histograms for the continuous predictors used in the main model.
3. Estimate overall survival with Kaplan-Meier, treating patients without a recorded death as right-censored at their observed follow-up time.
4. Fit an adjusted Cox proportional-hazards model with age, sex, anaemia, diabetes, ejection fraction, serum creatinine, and serum sodium.
5. Check the proportional-hazards assumption using Schoenfeld residuals.

This is a **prognostic association** analysis. It does not estimate causal effects of treatment or disease characteristics.

## Preliminary Results

The current run included 299 patients and 96 recorded deaths.

### Kaplan-Meier survival

| Follow-up day | Estimated survival | 95% CI |
| ---: | ---: | ---: |
| 30 | 0.882 | 0.846 to 0.920 |
| 90 | 0.763 | 0.715 to 0.813 |
| 180 | 0.654 | 0.596 to 0.719 |
| 240 | 0.594 | 0.524 to 0.673 |

### Adjusted Cox model

| Predictor | Hazard ratio | 95% CI | p-value |
| --- | ---: | ---: | ---: |
| Age, per year | 1.047 | 1.028 to 1.066 | <0.001 |
| Male vs female | 0.832 | 0.542 to 1.276 | 0.399 |
| Anaemia, yes vs no | 1.494 | 0.990 to 2.254 | 0.056 |
| Diabetes, yes vs no | 1.147 | 0.745 to 1.768 | 0.533 |
| Ejection fraction, per percentage point | 0.953 | 0.933 to 0.973 | <0.001 |
| Serum creatinine, per recorded unit | 1.384 | 1.201 to 1.596 | <0.001 |
| Serum sodium, per recorded unit | 0.962 | 0.919 to 1.008 | 0.101 |

The apparent concordance of the Cox model was 0.727. This is not external validation and should not be presented as expected performance in a new population.

The global proportional-hazards test was not statistically significant (p = 0.347), but ejection fraction had an individual test p-value of 0.043. Its diagnostic plot should therefore be inspected before treating the simple Cox model as final.

## Reproduce

Open R in this folder and run:

```r
source("heart_failure.R")
```

Required packages:

```r
install.packages(c("ggplot2", "survival"))
```

The script creates tables and figures in `outputs/`. It does not require `survminer` or `gtsummary`.

## Project Structure

```text
.
├── df.csv
├── heart_failure.R
├── README.md
└── outputs/
```
