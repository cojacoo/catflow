read.geofile <-
function(geofile) {
   
fid <- file(geofile, open="r")
 eta <-   scan(fid, n=1,quiet=T)       #no. of vertical points
  xsi <-  scan(fid, n=1,quiet=T)       #no. of lateral points
   g.aniso <- scan(fid, n=1,quiet=T)    # angle of global anisotropy against horizontal
    nhs <- scan(fid, n=1,quiet=T)      # hilllsope number (ID)
     eta.val <- scan(fid, n =eta, skip =3,quiet=T)
close(fid)

xsi.val <- read.table(geofile, nrows =xsi, skip =3+eta) 
 slope.width <- xsi.val[,4]
  realworld.coords <- xsi.val[,2:3]; names(realworld.coords) <- c("Re", "Ho")
   xsi.val <- xsi.val[,1]
    
simgrid <- read.table(geofile, skip=3+eta+xsi)[,-7]   # reads coordinates, 
                                                      # 7th column is dummy
  names(simgrid) <- unlist(strsplit("y, x, fe, fx, angle_xsi, angle_aniso", ", "))
        
hko <-  matrix(simgrid[,1], nrow=eta)[eta:1,]    # matrix of vertical coordinates
 sko <- matrix(simgrid[,2], nrow=eta)[eta:1,]     # matrix of lateral coordinates
  
return(list("hko"=hko, "sko"=sko, "xsi"=xsi.val, "eta" =eta.val, 
            "slope.width" = slope.width, "realworld.coords"=realworld.coords))
  }

