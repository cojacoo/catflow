make.simgrid <-
function( slope,                # dataframe with four col`s (x,y,z,width)
                                # or single values:
                slope.xp,       # coordinates of slope line
                slope.yp,              
                slope.zp,              
                slope.width,    # width of profile (uniform value 
                                #               or as long as xp
          prof.depth,           # desired depth of profil [m]
          dx.max = 0.01,        # desired maximal resolution [m]
         dz.max = 0.01         #  e.g. 0.01 m
          ){
    
  if(missing(slope) & missing(slope.xp)) stop(paste("Please specify coordinates!",
  "Either as dataframe(xp, yp, zp, width), or as separate values for xp, yp, zp, and width"))

  if(missing(slope.xp)) {slope.xp <- slope[,1]
                          slope.yp <- slope[,2]
                           slope.zp <- slope[,3]
                            slope.width <- slope[,4]} 

    # calculate horizontal distances between points of slope line
    dre <- diff(slope.xp)
    dho <- diff(slope.yp)
    dx <- sqrt(dre^2+dho^2)
    dx <- c(0,  cumsum(dx))     

  
  ## interpolate points of slope line - spaced equally along x 
  prof.length <- diff(range(dx))   
  nuprof <- approx(dx,slope.zp, n = 1 +ceiling(prof.length/ dx.max) )
  
    # new local x coordinate       
    xnew <- nuprof[["x"]]
  
   # check dx.max
   if( any( round(diff(xnew), format.info(dx.max)[2]) > dx.max) ) { 
                                  warning("Check results! dx.max does not hold")}
  
  ## regular grid
  
   # z coordinate: discretize each x column  in dz.max intervals
    dz <-  matrix(seq(0, prof.depth, dz.max) )
    znew <- apply(t(nuprof[["y"]]), 2, function(z) z <- z - dz )
      names(dim(znew)) <- c("eta", "xsi")
  
   # interpolating slope width at new x locations
   if( length(slope.width)!= length(dx) ) {
      if(length(slope.width)== 1) slope.width <- rep(slope.width, length(dx)) else (stop())
      } 
    slope.width <- approx(dx, slope.width, xout = xnew)$y

   ### back calculate northings and eastings 
   
      re <-  approx(dx, slope.xp, xout=xnew, rule=2)$y       
      ho <- approx(dx, slope.yp,  xout=xnew, rule=2)$y   

    
  return(list("xnew"=xnew,"znew"=znew, "width"=slope.width, "east"= re, "north" = ho))}

