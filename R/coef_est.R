#' @title Individual level effect estimation
#'
#' @description   This function is designed to estimate subject-level coefficients
#'
#' @param id      The vector of individual level ID's from the original dataset.
#' @param x       The covariate matrix.
#' @param y       The outcome variable.
#' @param weights Observation weights.
#' @param nfolds  The number of folds.
#' @param nvisit  The total number of time points.
#'
#' @return        The estimated coefficients for subject level covariates.
#' @import        glmnet

#' @export

coef_est <- function(id, x, y, weights, nfolds=5, nvisit=6){
  ##generate fold id
  n.p <- length(unique(id))
  eva<-runif(n.p, 0, 1)

  id_fold<-ceiling(eva * nfolds)

  foldid<-rep(id_fold,each=nvisit)

  #should be patient level CV
  cvfit <-cv.glmnet(x=x, y=y,
                    nfolds=nfolds, alpha=1,
                    weights = weights,intercept=F,
                    foldid=foldid)
  est.parameter.initial<-coef(cvfit, s = "lambda.min")

  cvfit <-cv.glmnet(x=x, y=y,
                    nfolds=nfolds, alpha=1,
                    weights = weights,intercept=F,
                    foldid=foldid,
                    penalty.factor=1/abs(est.parameter.initial[-1]))
  beta.est<-coef(cvfit, s = "lambda.min")
  return(list(beta.est=beta.est))
}
