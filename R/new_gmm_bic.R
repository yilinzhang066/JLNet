#' @title new_gmm_bic
#'
#' @description  This function is supposed to pinpoint the model minimizing the BIC
#'
#' @param k          The number of clusters.
#' @param thetahat   The initial estimate of facility-level effect.
#' @param sigma_all  The standard error of thetahat.
#' @param nstart     The number of random sets chosen for clustering.
#'
#' @return Bayesian information criterion (BIC) of the fitted model.

#' @export

new_gmm_bic<-function(k, thetahat, sigma_all, nstart = 25)
{
  km.res <- kmeans(thetahat, k, nstart = nstart)
  pi_all<-prop.table(table(km.res$cluster))

  mu_all<-km.res$centers

  epi1<-1e-04
  epi2<-1e-04


  repeat{
    ####step 2 e-step
    r_nk_num<-as.matrix(do.call(cbind, lapply(1:k, function (x)
    {
      pi_all[x]*dnorm(thetahat,mu_all[x],sigma_all)
    }
    )))
    r_nk_denom<-apply(r_nk_num,1,sum)
    r_nk_denom<-ifelse(r_nk_denom==0,1e-20,r_nk_denom)
    r_nk<-r_nk_num/r_nk_denom
    N_k<-apply(r_nk,2,sum)

    ####step 3 m-step
    mu_all_update<-do.call(cbind, lapply(1:k, function (x)
    {
      sum(r_nk[,x]*thetahat)/N_k[x]
    }
    ))
    pi_all_update<-N_k/sum(N_k)

    if(mean(abs(c(mu_all_update)-c(mu_all)))<epi1 &
       mean(abs(c(pi_all_update)-c(pi_all)))<epi2)
    {break}else{
      mu_all<-mu_all_update
      pi_all<-pi_all_update
    }
  }

  label_gmm<-apply(r_nk,1,which.max)
  fitted_gmm<-unlist(lapply(1:length(thetahat), function(x)
  {
    mu_all[label_gmm[x]]
  }
  ))

  pi_gmm<-unlist(lapply(1:length(thetahat), function(x)
  {
    pi_all_update[label_gmm[x]]
  }
  ))

  wei_sum<-pi_gmm*dnorm(thetahat, mean = fitted_gmm, sd = sigma_all, log =F)
  wei_sum<-ifelse(wei_sum<1e-60,1e-60,wei_sum)
  neg2loglike<--2*sum(log(wei_sum))
  BIC_gmm<-neg2loglike+(2*k)*log(length(thetahat))
  return(BIC_gmm=BIC_gmm)
}
