#' @title Hospital-level effect initial estimation.
#'
#' @description   This function is designed to obtain the initial estimate of hospital-level effect.
#'
#' @param x       The covariate matrix.
#' @param y       The outcome variable.
#' @param subj.id The subject level ID.
#' @param hosp.id The hospital level ID.
#' @param data    The original dataset.
#' @param beta    The estimation of individual-level effect
#' @param weights The weight used to adjust for drop-out
#'
#' @return        A list of two items: the initial estimate of hospital-level effect and the standard error of the estimation.
#' @import        geepack

#' @export


theta_est <- function(x, y, subj.id, hosp.id, data, beta, weights){
  y_starstar_all<-(data[,y]-as.matrix(x)%*%c(beta[-1]))[weights>0]
  data_used<-data[weights>0,]
  weight_used<-weights[weights>0]
  hosp.id.idx <- which(colnames(data)==hosp.id)
  subj.id.idx <- which(colnames(data)==subj.id)
  fit<-geeglm(y_starstar_all~as.factor(data_used[,hosp.id.idx])-1,
              weights = weight_used,id=data_used[,subj.id.idx])
  thetahat<-fit$coefficients
  sigma_k<-summary(fit)
  sigma_all<-sigma_k$coefficients[,2]
  return(list(thetahat=thetahat, sigma_all=sigma_all))
}
