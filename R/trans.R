#' @title transform function
#'
#' @description Transform predictor matrix and response variable
#'
#' @param x.data   The original predictor matrix
#' @param y.data   The original response variable
#' @param weight   weights
#' @param hosp.id  The hospital ID.
#'
#' @return A list with two items: The transformed predictor matrix and the transformed response variable

#' @export

trans<-function(x.data, y.data, weight, hosp.id)
{
  #############pipi-estimate########################
  x.matrix<-as.matrix(x.data)
  y.matrix<-as.matrix(ifelse(is.na(y.data), 0, y.data))

  y_star<-ZTZ<-rep()
  x_star<-matrix(rep(0),nrow = nrow(x.matrix), ncol = ncol(x.matrix))
  hosp.list<-unique(hosp.id)
  n.hos.total<-length(hosp.list)

  for (dd in 1:n.hos.total) {
    ZTZ[dd]<-sum(weight[which(hosp.id==hosp.list[dd])])
    S_hat<-matrix(rep(1/ZTZ[dd]*weight[which(hosp.id==hosp.list[dd])],length(which(hosp.id==hosp.list[dd]))),
                  byrow = T, nrow = length(which(hosp.id==hosp.list[dd])))
    I_matrix<-diag(1,ncol = length(which(hosp.id==hosp.list[dd])), nrow = length(which(hosp.id==hosp.list[dd])))

    y_star[which(hosp.id==hosp.list[dd])]<-(I_matrix-S_hat)%*% y.matrix[which(hosp.id==hosp.list[dd])]
    x_star[which(hosp.id==hosp.list[dd]),]<-(I_matrix-S_hat)%*% x.matrix[which(hosp.id==hosp.list[dd]),]
  }

  trans_list<-list("x_star"=x_star,
                   "y_star"=y_star)

  return(trans_list)
}
