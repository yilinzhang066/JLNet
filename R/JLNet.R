#' @title JLNet
#'
#' @description   This function is designed to estimate subject-level coefficients
#'
#' @param x       The covariate matrix.
#' @param y       The observed outcome variable.
#' @param subj.id The subject ID.
#' @param hosp.id The hospital ID.
#' @param visit   The longitudinal information
#' @param data    The original dataset
#' @param models  A formula object describing the missing mechanism.
#' @param family  The distribution family that the missing indicator belongs to.
#' @param nfolds  The number of folds.
#' @param nvisit  The total number of time points.
#' @param k       The number of clusters.
#' @param nstart  The number of random sets chosen for clustering.
#'
#' @return        A list of 1. the estimated individual-level effect, 2. The estimated coefficients for subject level covariates.
#' @import        geepack fossil CatReg randomForest cluster ClusterR fastDummies
#'
#' @export

JLNet <- function(x, y, subj.id, hosp.id, visit, data, models, family, nfolds=5, nvisit, k=c(2:30), nstart=25){
  mis.fit<-miss(models = models, data = data,
                visit=visit, subj.id=subj.id, family = binomial)
  x.data <- as.matrix(data[, x])
  y.idx <- which(colnames(data)==y)
  y.data <- as.matrix(ifelse(is.na(data[, y.idx]), 0, data[, y.idx]))
  weight <- mis.fit$weight
  hosp.id.idx <- which(colnames(data)==hosp.id)
  star.fit<-trans(x.data, y.data, weight, hosp.id=data[,hosp.id.idx])
  x_star<-star.fit$x_star  #transformed data for x
  y_star<-star.fit$y_star  #transformed data for y

  beta.est <- coef_est(data[,subj.id], x_star, y_star, weights=weight, nfolds=nfolds, nvisit=nvisit)$beta.est

  thetaest <- theta_est(x.data, y.idx, subj.id=subj.id, hosp.id=hosp.id, data=data, beta=beta.est, weight=weight)
  thetahat <- thetaest$thetahat
  sigma_all <- thetaest$sigma_all

  avg_sil <- sapply(k,
                    new_gmm_bic, nstart=nstart, thetahat=thetahat, sigma_all=sigma_all)
  opt_num_gmm<-k[which.min(avg_sil)]
  gmm_tot_c<-opt_num_gmm
  # gmm_tot_c
  gmm<-new_gmm(gmm_tot_c,thetahat,nstart = nstart, sigma_all=sigma_all)
  gmm_label<-gmm$label_gmm
  # table(gmm_label)
  # gmm_tot_c<-length(table(gmm_label))


  #gmm_rand<-adj.rand.index(group1=true_label, group2=gmm_label) #use either rand.index or adj.rand.index
  # gmm_rand
  #################################################


  #################################################
  ##summary of variable selection based on patient-level factors
  ###true positive rate
  jlnet_tp<-sum(ifelse(beta.est[2:7]!=0,1,0))/6
  ###false positive rate
  jlnet_fp<-sum(ifelse(beta.est[-c(2:7)]!=0,1,0))/200
  ###bias
  true_beta<-c(0.1,1,0.5,-0.5,0.5,1)
  jlnet_bias_mse<-sqrt(mean((beta.est[2:7]-true_beta)^2))
  return(list(beta.est = beta.est, gmm_tot_c = gmm_tot_c, gmm_label = gmm_label))
}
