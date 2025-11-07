get.realworld.coords <-
function(geofile, tol= 1e-3)
    {
     geof <- read.geofile(geofile)
          
     sko <- geof$sko; hko <- geof$hko
      xsi <- geof$xsi; eta <- geof$eta
     re <- geof$realworld.coords$Re
      ho <- geof$realworld.coords$Ho
     
     # prepare matrix with Re / Ho- values
     re.m <- matrix(NA,ncol=length(xsi), nrow=length(eta))
      ho.m <- matrix(NA,ncol=length(xsi), nrow=length(eta))
     
     skn <- sweep(sko,2,sko[1,])               # normalise for upper left point        
    
      x.fac <- diff(range(re))
      y.fac <- diff(range(ho))                                 

     # alpha ist Winkel zur x-Achse (ac) 
     # tan(alpha) = y.fac/x.fac                  /|
     # sin(alpha) = b/c                      c  / |  b
     # cos(alpha) = a/c                        /__|
     #                                          a
     alpha = atan(y.fac/x.fac)              
     
    for(i in 1:length(eta)) { re.m[i,] <-   skn[i,] *  cos(alpha) + re
                               ho.m[i,] <-  skn[i,] *  sin(alpha)  + ho } 
  
    sko.new <- abs( round(sqrt((re.m-min(re.m))^2 + (ho.m- min(ho.m))^2),4)) 
   
    # check: must agree with sko within 1 mm when normalising for lower left corner
    stopifnot(  sko.new - sko  < tol )
     
    return(list(Re = re.m, Ho = ho.m))
    }

