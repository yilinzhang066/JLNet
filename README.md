# JLNet: A Joint Learning for Analyzing a National Geriatric Centralized Networks

![](man/figures/workflow.png)

**Background**: Centralized networks such as Medicare administrative claim data can directly pool deidentified patient-centered data across centers/institutions and store them in centralized data warehouses. A growing number of studies use Medicare claims data to conduct patient-centered research and inform personalized care for older adults. However, traditional methods are not capable of addressing challenges inherent to the complex hierarchical data structure,  including absent or inadequate integration of hospital-level data, non-normal outcome distributions, informative patient dropout (due to insurance changes, mortality, etc.), and high computational load when analyzing large-scale datasets. A new method is needed to handle these challenges and support valid inference and interpretability.

**JLNet** is a novel analytical framework integrating multiple statistical and machine learning techniques, including propensity score weighting, projection methods, regularized regression, and unsupervised learning. It offers several unique features not available in existing toolkits, including the flexible identification of high-dimensional patient-level factors associated with care outcomes (potentially with time-varying effects), the computationally efficient detection of latent hospital clusters, and the ability to handle real-world data complexities, such as patient dropout and non-normally distributed outcomes. 

After installing the \textit{JLNet} package, the simulated data \emph{simdata} can be loaded and viewed using the code:
``` r
library(JLNet)
set.seed(12345)
data("simdata", package = "JLNet")
head(simdata)

     id   hosp visit   subj_x_1    subj_x_2  subj_x_3 
1 10001    1     1     7.779783        1     4.918035
2 10001    1     2     7.603686        1     4.918035
3 10001    1     3     7.700258        1     4.918035
4 10001    1     4     7.474295        1     4.918035
5 10001    1     5     7.912472        1     4.918035
6 10001    1     6     6.660966        1     4.918035
```

Users can specify a dropout model and use the function \emph{miss} to construct inverse probability weights:
```r
models <- R_i~subj_x_1+subj_outcome_lag
mis.fit <- miss(models=models, data=simdata, visit="visit", subj.id="id", family="binomial")
weight <- mis.fit$weight
```
Note that one requirement of using \emph{miss} is that all patients have identical number of observations in the dataset, thus the row containing missing values should not be discarded.

To identify patient-level variables that are predictive of longitudinal outcomes, first format the data into matrix structures:
```r
x.data <- as.matrix(simdata[, c(3:8,18:217)])
y.data <- as.matrix(ifelse(is.na(simdata$subj_outcome_obs), 0, simdata$subj_outcome_obs))
```
Then run the function \emph{tran} to generate transformed versions of the original outcomes and covariates to profile out hospital-level effects, and run the function \emph{beta.est} to identify patient-level variables that are predictive of longitudinal outcomes:
```r
star.fit <- trans(x.data=x.data, y.data=y.data, weight=weight, hosp.id=simdata[, "hosp"])
beta.est <- coef_est(id=simdata[,"id"], x=star.fit$x_star, y=star.fit$y_star, weights=weight, nfolds=5, nvisit=6)$beta.est
```

# Installation

``` r
if (!require("devtools")) {
  install.packages("devtools")
}
devtools::install_github("yilinzhang066/JLNet")
```
