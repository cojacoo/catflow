mac.grid <-
function(relfak, xnew, znew, xsi_new, eta_new, plottin = FALSE ) {
        ## position of macropores in terms of eta and xsi
        ## from "factor" matrix

rocol <- which(relfak > 1, arr.ind = TRUE)             # rows and cols in relfak
 xii <- xnew [ rocol[,2] ]
 eti <- znew[relfak > 1]   

# relative coordinates
 as.xsi <- (xii - min(xnew)) / diff(range(xnew))
 
 as.eta <- array(dim = dim(znew))                 # min is different for each column!
 
 for(i in 1:ncol(znew))  as.eta[, i] <- (znew[, i] - min(znew[, i]))/diff(range(znew[, i]))
 
 as.eta <- as.eta[relfak > 1] 
  
## find indices (round rel. coords to same number of digits as xsi and eta vector)
 # adding small number to avoid numerical problem

 xi <- findInterval((as.xsi + 1e-7),  xsi_new)             
  ei <- findInterval((as.eta + 1e-7 ),  eta_new)
 
### make grid ### grid of values instead logicals???
 macgrid <- array(FALSE , dim = c(length(eta_new), length(xsi_new)))

 for(i in seq(along = xi))   macgrid[ei[i], xi[i]] <- TRUE

  if(plottin)  image(t(macgrid))

  macgrid <- macgrid[nrow(macgrid):1,]         # need to flip matrix (row 1 is bottom)
                                                # (done here because image would require flipping again)
return(macgrid)
}

