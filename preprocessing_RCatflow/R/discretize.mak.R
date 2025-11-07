discretize.mak <-
function(sim, steph=1,stepv=1, maxdists, dimfaks, top = 1:3, reg = TRUE, plottin=TRUE){
  # make xsi vector/ lateral discretization
  # keep fine resolution at macropores locations +/- 'steps'
  # with maximum gap size of 'max.dist' columns (defaults to 2.5 % of dimension) 
                   
  # make eta vector / vertical discretization
  # keep fine resolution at macropores endings +/- 'steps' and at top (default 3 rows)
  # with maximum gap size of 'max.dist' rows (defaults to 5.0 % of dimension) 
        
relfak <- sim[["relfak"]]
  lmac <- sim[["lmac"]]

if(missing(maxdists)) {                
    if(missing(dimfaks) ) { # if both are missing, use defaults
                            xsi_new <- discretize.xsi(relfak, steps = steph, reg = reg)
                            eta_new <- discretize.eta(lmac[2,], relfak = sim[[1]], 
                                             steps = stepv, reg = reg, top = top)
     
     } else {    # missing maxdists: use dimfaks, eventually duplicating single entry
                 if(length(dimfaks) < 2) dimfaks <- rep(dimfaks[1],2)           
                            xsi_new <- discretize.xsi(relfak, steps = steph, 
                                              dimfak = dimfaks[1], reg = reg)
                            eta_new <- discretize.eta(lmac[2,], relfak = sim[[1]], 
                                              steps = stepv, reg = reg,  
                                              dimfak = dimfaks[2], top = top)   
             }
    # use maxdists, eventually duplicating single entry
 } else {        if(length(maxdists) < 2) maxdists <- rep(maxdists[1],2)                    
                            xsi_new <- discretize.xsi(relfak, steps = steph, 
                                               max.dist = maxdists[1], reg = reg)
                            eta_new <- discretize.eta(lmac[2,], relfak = sim[[1]], 
                                               steps = stepv, reg = reg,
                                               max.dist = maxdists[2], top = top)
 }

  #Scaling relfak into new grid
  # use mac.grid()


if( plottin ){
      plot(0:1,0:1,t="n", ann=FALSE)
      abline(v = xsi_new, col=8)
      image(t(relfak>1)[,nrow(relfak):1], col=0:1, add=TRUE)
       abline(h = c(0,1) )
       abline(h = eta_new, col=3)
      }

return(list(xsi = xsi_new, eta = eta_new ))
}

