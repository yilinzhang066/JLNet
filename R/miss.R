#' @title Drop-out missing model
#'
#' @description Generate inverse probability weight (IPW) for longitudinal data with drop-out situation
#'
#' @param models A formula object describing the missing mechanism.
#' @param data   A data frame containing the variables in the model.
#' @param visit  The variable of longitudinal information.
#' @param id     The individual level ID.
#' @param family The distribution family that the missing indicator belongs to.
#'
#' @return A list with two items: The estimated coefficients of the missing model and inverse probability weights

#' @export

miss<-function(models, data, visit, subj.id, family)
{
  vis.idx <- which(colnames(data) == visit)
  subj.id.idx <- which(colnames(data) == subj.id)
  nvisit<-length(unique(data[, vis.idx]))
  if (length(unique(data[, subj.id.idx]))!=nrow(data)/nvisit)
    stop("the total visit for each subjects must be identical")

  nsub<-nrow(data)/nvisit
  mis.Ri<-get_all_vars(models, data)[,1]
  H_ij <- cbind(x1=rep(1,nrow(data)),get_all_vars(models, data)[,-1])
  H_ij<-apply(H_ij, 2, function(x) {ifelse(is.na(x), 0, x)})

  mis.data<-subset(data,data[,vis.idx]!=1)
  misfit<-glm(models, data = mis.data, family = family)
  alpha<-misfit$coefficients

  #mis.Li<-matrix(rep(0),nrow=nsub*nvisit,ncol = length(alpha))
  #Li.sub<-matrix(rep(0),nrow=nsub,ncol = length(alpha))
  mis.weight<-mis.lambda<-rep(1,nsub*nvisit)
  #Li.square.sum<-Li.partial.sum<-matrix(rep(0),nrow=length(alpha),ncol = length(alpha))
  for (misi in 1:nsub) {
    for (misj in 2:nvisit) {
      mis.lambda[misj+nvisit*(misi-1)]<-1/(1+exp(-t(H_ij[misj+nvisit*(misi-1),])%*%alpha))
      #mis.Li[misj+nvisit*(misi-1),]<-mis.Ri[misj+nvisit*(misi-1)-1]*(mis.Ri[misj+nvisit*(misi-1)]-mis.lambda[misj+nvisit*(misi-1)])*H_ij[misj+nvisit*(misi-1),]
      if (misj==2) {
        mis.weight[misj+nvisit*(misi-1)]<-mis.lambda[misj+nvisit*(misi-1)]
        #mis.Li.partial<-mis.Ri[misj+nvisit*(misi-1)-1]*(H_ij[misj+nvisit*(misi-1),])%*%t(H_ij[misj+nvisit*(misi-1),])*mis.lambda[misj+nvisit*(misi-1)]*(1-mis.lambda[misj+nvisit*(misi-1)])
      } else {
        mis.weight[misj+nvisit*(misi-1)]<-mis.weight[misj+nvisit*(misi-1)-1]*mis.lambda[misj+nvisit*(misi-1)]
        # mis.Li.partial<-mis.Li.partial+mis.Ri[misj+nvisit*(misi-1)-1]*(H_ij[misj+nvisit*(misi-1),])%*%t(H_ij[misj+nvisit*(misi-1),])*mis.lambda[misj+nvisit*(misi-1)]*(1-mis.lambda[misj+nvisit*(misi-1)])
      }
    }
    #Li.sub[misi,]<-apply(mis.Li[(nvisit*(misi-1)+1):(nvisit*(misi-1)+6),], 2, sum, na.rm=T)
    #Li.square.sum<-Li.square.sum+Li.sub[misi,]%*%t(Li.sub[misi,])
    #Li.partial.sum<-Li.partial.sum+mis.Li.partial
  }


  mis_list<-list("coefficients"=alpha,
                 "weight"=ifelse(mis.Ri==0, 0, 1/(mis.weight)))

  return(mis_list)
  #var.alpha<-solve(Li.partial.sum)%*%(Li.square.sum)%*%t(solve(Li.partial.sum))
}
