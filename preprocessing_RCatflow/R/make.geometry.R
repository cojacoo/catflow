make.geometry <-
function( # # # produces a geometry file for the CATFLOW code 
                              slope.list,      # list with input parameters
                              plotting=TRUE,      # plot during execution ?
                              make.output=TRUE,   # write geometry file?
                              thick.tol = 0.2 ,   # tolerance for type 3 (scaling thickness) 
                              project.path = NULL,# directory for outfile (optional)
                              ... ){              # graphical parameters may be specified for the final plot, e.g. col = 1 for black lines, 'plottitle' overrides the default title of the plot
  
  
   ## Input in slope.list:
    #  xh       - x-coordinate of slope profile  
    #  yh       - y-coordinate of slope profile 
    #  zh       - z-coordinate of slope profile
    #  tot.area   - total area of slope
    #  bh       - slope width
    #  dyy      - thickness of profile
    #  xsi      - relative discretization in lateral direction
    #  eta      - relative discretization in vertical direction
   ### parameters which take default values when omitted ###
    #  htyp     - type of geometry: (1) constant thickness, (2) cake-shape
    #  numh     - ID for slope
    #  ho_bez   - point of reference for y-coordinate of slope profile (northing)
    #  re_bez   - point of reference for x-coordinate of slope profile (easting)
    #  z_bez    - point of reference for z-coordinate of slope profile (mean sea level)
    #  w.aniso  - angle of main direction of anisotropy,  positive counterclockwise 
    #  out.file - name for ASCII file (CATFLOW geofile)
    
    
    xh <- slope.list[["xh"]] 
    yh <- slope.list[["yh"]] 
    zh <- slope.list[["zh"]]
    tot.area <- slope.list[["tot.area"]]
    bh <- slope.list[["bh"]]
    dyy <- slope.list[["dyy"]]
    xsi <- slope.list[["xsi"]]
    if(any(xsi>1) | any(xsi<0)) stop("xsi not limited to the interval 0 - 1!")
    eta <- slope.list[["eta"]]
      if(any(eta>1)| any(eta <0)) stop("eta not limited to the interval 0 - 1!")
    # take default values for missing parameters (looking in slope.list)
    
    attach(slope.list, warn.confl=FALSE); on.exit(detach(slope.list))
 
    if(!exists("htyp", where="slope.list")) htyp <- 1 else htyp <- slope.list[["htyp"]]
    if(!exists("numh", where="slope.list"))   numh <- 1  else numh <- slope.list[["numh"]]
    if(!exists("ho_bez", where="slope.list"))   ho_bez <-  0  else ho_bez <- slope.list[["ho_bez"]]
    if(!exists("re_bez", where="slope.list"))   re_bez <-  0  else re_bez <- slope.list[["re_bez"]]
    if(!exists("z_bez", where="slope.list"))    z_bez  <-  0  else z_bez <- slope.list[["z_bez"]]
    if(!exists("w.aniso",where= "slope.list"))  w.aniso <- 0  else w.aniso <- slope.list[["w.aniso"]]
    if(!exists("out.file", where="slope.list")) make.output <- FALSE
   
    if(make.output) { if(!is.null(project.path)){ out.file <- file.path(project.path, out.file) 
                                                if(!file_test("-d", project.path)) dir.create(project.path, recursive=TRUE) }  }
   
      
#-----------------------------------------------------------------------
# Definitions of internal functions #
# --------------------------------

    cspe <- function(
    # cspe: cubic spline interpolation with endconditions (here: first gradient)
              xi,                # xi and yi are vectors 
              yi,                 # (x, y coordinate values)
              valconds ,...){
      #-------------------------------------
      # #  Generate the cubic spline interpolant as piecewise polynomial. 
      #    (e.g. Press et al. 92, Numerical Recipes FORTRAN pp.107ff)
      # returns the cubic spline interpolant (piecewise polynomial) to the given data  (xi,yi)
      # using the specified gradients at the endpoints  with  values  valconds(i) ,
      # with i=1 (i=2) referring to the left (right) endpoint.
      #
      # adapted from MATLAB/Octave function 'csape' [Copyright 1987-2003 C. de Boor and 
      # The MathWorks, Inc. (MATLAB version); Copyright  2000,2001 Kai Habel (Octave version)]
      #
      #-------------------------------------
  
       stopifnot(is.vector(yi))                    # check if y is vector
       stopifnot(length(xi) == length(yi) )         # checks if lengths match
    
        n <- length(yi)  
       
        if(n>2){
         
        # set up the linear system for solving for the slopes at XI.
        dx <- diff(xi)
        locgrad <- diff(yi) /dx
     
        # construct tridiagonal matrix
        cc <- matrix(0,n,n)
        
         # fill interior diagonals for n*n matrices with n>2
        dia.val <-  2*c(0, dx[2:(n-1)]+dx[1:(n-2)],0)    # fill diagonal
          diag(cc) <- dia.val
        ld.val <- dx[2:(n-1)]                            # fill lower
          cc[cbind(2:(n-1) , 1:(n-2))] <- ld.val          # subdiagonal
        ud.val <- dx[1:(n-2)]                            # fill upper
          cc[cbind(2:(n-1), 3:n)] <- ud.val              # subdiagonal
         
        cc[1,1]  <-  cc[n,n] <- 1  
       
        b <- rep(0, n)
        b[2:(n-1)] <- 3*(dx[2:(n-1)]*locgrad[1:(n-2)] + dx[1:(n-2)]*locgrad[2:(n-1)])
      
        # check for given endconditions
         # check if valconds are given, otherwise set to zero
         if (missing(valconds)){    
             # if endslope was not supplied, get it by local interpolation
                b[1] <- locgrad[1]
                b[n] <- locgrad[n-1]
              
                ddf <- (locgrad[2]-locgrad[1])/(xi[3]-xi[1]);
                b[1] <- b[1]-ddf*dx[1]
                ddfn <- (locgrad[n-1]-locgrad[n-2])/(xi[n]-xi[n-2]);
                b[n] <- b[n]+ ddfn*dx[n-1]
                  
              if (n>3){
                ddf2 <- (locgrad[3]-locgrad[2])/(xi[4]-xi[2]);
                  b[1] <- b[1]+(ddf2-ddf)*(dx[1]*(xi[3]-xi[1]))/(xi[4]-xi[1])
                ddf2n <- (locgrad[n-2]-locgrad[n-3])/(xi[n-1]-xi[n-3])
                  b[n] <- b[n] + (ddfn-ddf2n)*(dx[n-1]*(xi[n]-xi[n-2])) /(xi[n]-xi[n-3])
                      }
        }  else   
        # or use given values for first derivative
       { b[1] <- valconds[1]
         b[n] <- valconds[2]  } 
              
        ### solve for the slopes 
        sl <-  solve(cc,b)
              
        # convert to ppform
        c4 <- (sl[1:(n-1)]+sl[2:n]-2*locgrad[1:(n-1)]) /dx
        c3 <- (locgrad[1:(n-1)]-sl[1:(n-1)]) /dx - c4
    
         pp.breaks <- xi
         pp.coefs <- cbind(yi, sl, c(c3,0), c(c4/dx, 0)  )
                                       # add 0 for linear extrapolation
       
       # if(n==2): linear relationship
        } else { pp.breaks <- seq(xi[1],xi[2],length=5)     
                
                 lin <- lm(yi ~xi) 
                  y <- predict(lin,newdata=data.frame(xi=pp.breaks))     # constant
                   if(missing(valconds)){ b <- rep(coef(lin)[2], 5)      # linear - fitted
                  } else                 b <- approx(valconds, n=5)$y   #        - specified
                pp.coefs <- cbind(y,b,0,0)
          }
        
        # Factors are: y constant, b linear, c quadratic, d cubic   
        colnames(pp.coefs) <- c("y","b","c","d")
          rownames(pp.coefs) <- as.character(pp.breaks)
        
        # make spline object with breaks and coefficients
        value <- list(knots = pp.breaks, coefficients = pp.coefs)
        class(value) <- c("npolySpline","polySpline", "spline")
      return( value ) } 

    #-------------------------------------------------------------------------------
      gradient <- function(f, h){
      #  gradient: numerical gradient (difference quotient) of input vector f at locations h
      #  for matrices: use apply and the respective dimension
        n <- length(h)                   # n is length in the dimension considered
          if (n < 2) stop(paste("Function 'gradient': n =",n, "is not enough.") )
          if (length(f)!= n) stop(paste("Function 'gradient': vectors have different lengths!") )
        
        i1 <- 1:2 ; i2 <- (n-1):n        # indices
        # forward differences on left and right edges, central differences where available
        diff.quot <- c( diff(f[i1]) / diff(h[i1]),          
                       (f[-i1] - f[-i2]) / (h[-i1] - h[-i2]),
                         diff(f[i2]) / diff(h[i2]) )
        return(diff.quot)}      

    #-------------------------------------------------------------------------------
      mkpp <- function(x,y, make.poly=FALSE){
    #   mkpp: make piecewise polynomial               
                          # make.poly=T: generate spline object with intercept and zero slope
        if(!is.matrix(y))   y <- matrix( y, ncol = length(y))
         if(is.null(dimnames(y))) dimnames(y) <- list(NULL, c("y","b","c","d")[1:ncol(y)])
        
          if(make.poly){
            if(length(x) <  (2*ncol(y)+1) ){ ### sufficient number of knots
              x <- unique(sort(c( seq(min(x),max(x), length=(2*ncol(y)+1) ), x) ))    
              }                                  
              if (nrow(y)< length(x)){         ### one row per knot
                y  <-  matrix( rep(y, length(x)), byrow=TRUE, nrow=length(x ))
                }
            res <- list(knots=x, coefficients=y)
            class(res) <- c("npolySpline", "polySpline", "spline")     # 
          
          } else res <- list(knots=x, coefficients=y)
    
        return(res) }

    #-------------------------------------------------------------------------------
    #   misc. functions for generating geometry
    ###  
        xa <- function (tau, typ=htyp,...){
               if (typ==1 | typ ==3 ) { xa <- tau*(max_xa-min_xa)+min_xa
                } else if (typ==2) xa <- tau
          return(xa)}
        
        xb <- function(et,typ=htyp,...){
                m <- length(et)
                if (typ==1){
                 xb <- et*(max_xb-min_xb) + min_xb
                } else if (typ==2 | typ ==3 ) xb <-  rep(max_xb, m)
          return(xb)}
           
        xc <-  function (tau,...) tau*(max_xc-min_xc)+min_xc     # used in dycdt
              
        xd <- function(et, typ= htyp,... ){
        # cf. xb(), but here minimum is considered for typ ==2
               m <- length(et)
                if (typ==1){  xd <- et*(max_xd-min_xd)+min_xd
                } else if (typ==2 | typ ==3 ) xd <- rep(min_xd,m)
          return(xd)}
        
        ya <- function(tau, typ= htyp,... ){
                m <- length(tau)
                if (typ==1 | typ ==3 ){    ya <- predict (ppya, xa(tau))$y 
                } else if(typ==2) ya <- rep(min(pyd),m)
          return(ya)}
      
        yb <- function (et, typ= htyp,... ){
                m <- length(et)
                if (typ==1){    yb <- predict (ppyb, xb(et))$y           
                } else if(typ==2 | typ ==3 )  yb <- et*(diff(range(pyb))) + min(pyb)
          return(yb)}
       
        yc <- function(tau, ... )  predict(ppyc, xc(tau))$y    
      
        yd <- function(et, typ= htyp,... ){
                  if (typ==1){    yd <- predict(ppyd, xd(et))$y          
                  } else if (typ==2 | typ ==3 ) yd <- et*(max(pyd)-min(pyd))+min(pyd)
          return(yd)}
    
    #-------------------------------------------------------------------------------
    # functions for case differentiation
         
      dxde <- function (et, max.x,min.x, typ=htyp,...){
      ## derivatives at sides B and D: dxbde.m (max_xb, min_xb) and dxdde.m (max_xd, min_xd)
              m <- length(et)
              if (typ==1) xb <- rep(1, m)*(max.x-min.x) else
               if (typ==2 | typ ==3 )  xb <- rep(0,m)
        return(xb) }
       
      dxbde <- function(et,...) dxde(et, max_xb, min_xb,typ=htyp)
      dxdde <- function(et,...) dxde(et, max_xd, min_xd,typ=htyp)
      
      dybde <- function (et ,  typ=htyp,...){ 
      # at side B: first derivative of ppyb
           m <- length(et)
           if (typ ==1){                                      
             yb <- predict (ppyb, xb(et, typ), deriv=1)$y     ## gradient at location xb(et)
              yb <- yb * dxbde(et, typ)                             
            } else if (typ==2 | typ ==3 ) yb = rep(1, m)   # ppyb defined in vertical direction!
        return(yb)}                                      
          
      dydde <- function (et,  typ=htyp,... ){
      # at side D: first derivative of ppyd
           m <- length(et)
           if (typ ==1){
              yd <-  predict(ppyd, xd(et, typ), deriv=1)$y         
               yd <- yd * dxdde(et, typ)
            } else if (typ==2 | typ ==3 )  yd <- rep(1, m)
        return(yd)}
      
      dxadt <- function (tau, typ=htyp,...){ 
      # lower left corner of side A
            m <- length(tau)
            xa <- rep(1,m)
             if (typ==1 | typ ==3  ) xa <- xa * (max_xa-min_xa)         
        return(xa)}
              
      dxcdt <- function(tau,...) {
            m <- length(tau)
            xc <- rep(1,m) *(max_xc-min_xc)               
        return(xc)}
         
      dycdt <- function(tau,...){
      # first derivative of ppyc at location xc(tau)
            yc <- predict (ppyc, xc(tau), deriv=1)$y      
             yc <- yc * dxcdt(tau)
        return(yc)}
      
      dyadt <- function(tau,typ=htyp,...){
               m <- length(tau)
               if (typ==1 | typ ==3 ){
                  ya <- predict (ppya, xa(tau, typ), deriv=1)$y            
                  ya <- ya * dxadt(tau, typ) 
                } else if(typ==2) ya <- rep(0,m)
        return(ya)}
       
      dyb2de2 <- function(et,typ=htyp,...){         
      # at side B: second derivative of ppyb                                
             m <- length(et)
             if (typ ==1){
               yb <-   predict (ppyb, xb(et, typ), deriv=2)$y      
                 yb <- yb* dxbde(et, typ)                         
              } else if (typ==2 | typ ==3 )  yb <- rep(0, m) # zero slope (vertical)
        return(yb)}                          
           
      dyd2de2 <- function(et,typ=htyp,...){
      # at side D: second derivative of ppyd
             m <- length(et)
             if (typ ==1){
                yd <-  predict (ppyd, xd(et, typ), deriv=2)$y   
                 yd <- yd * dxdde(et, typ)               
              } else if (typ==2 | typ ==3 )  yd <- rep(0, m)
        return(yd)}
    
    #-------------------------------------------------------------------------------
      koor_dbm <- function(eta, tau, tau_anz = 1.5* xsi_anz, ...){
      # koor_dbm. calculates coordinate values
     
        if(missing(tau)) tau <- seq(xsi_1, xsi_n , length= tau_anz )
        
        eta_anz <- length(eta)       ### length of (local) eta
                      
        # Vorfaktoren zur Berechnung von hd und hd und hdb
        f_xsi_n = (xsi_n - tau) / (xsi_n - xsi_1)
        f_xsi_1 = (tau - xsi_1) / (xsi_n - xsi_1)
        f_eta_m = (eta_m - eta) / (eta_m - eta_1)
        f_eta_1 = (eta - eta_1) / (eta_m - eta_1)
    
        #--------------------------------------------
        # Berechnung der Vektoren hd(eta) und hb(eta)
        hb_x <- (xd(eta)-xb(eta)) +
               f_eta_m * ( diff(xa(range(xsi))) - 
                           (xsi_n-xsi_1)* ( dxadt(xsi_n) - lam_ab * dybde(eta) )) +
               f_eta_1 * ( diff(xc(range(xsi))) -
                          (xsi_n-xsi_1)*(dxcdt(xsi_n) - lam_bc*dybde(eta)))
        
        hd_x <- (xd(eta)-xb(eta)) +
               f_eta_m * ( diff(xa(range(xsi))) - 
                            (xsi_n-xsi_1)* ( dxadt(xsi_1) - lam_da*dydde(eta) ) ) +
               f_eta_1 * ( diff(xc(range(xsi))) -
                            (xsi_n-xsi_1) *( dxcdt(xsi_1) - lam_cd*dydde(eta) ) )
        
        hb_y <- (yd(eta)-yb(eta)) +
               f_eta_m * ( diff(ya(range(xsi))) -
                         (xsi_n-xsi_1)* (dyadt(xsi_n) + lam_ab*dxbde(eta)) ) +
               f_eta_1 * ( diff(yc(range(xsi))) -
                         (xsi_n-xsi_1)*(dycdt(xsi_n) + lam_bc*dxbde(eta)) )
        
        hd_y <- (yd(eta)-yb(eta)) +
               f_eta_m * ( diff(ya(range(xsi))) -
                          (xsi_n-xsi_1)*(dyadt(xsi_1) + lam_da*dxdde(eta)) ) +
               f_eta_1 * ( diff(yc(range(xsi))) -
                          (xsi_n-xsi_1)*(dycdt(xsi_1) + lam_cd*dxdde(eta)) )
        
        #-----------------------------
        # Berechnung von h_db(tau,eta)         
        hdb_x <- f_xsi_n %o% xd(eta) + f_xsi_1 %o% xb(eta) +
                (xa(tau) - f_xsi_n*xa(xsi_1) - f_xsi_1*xa(xsi_n)) %o% f_eta_m +
                (xc(tau) - f_xsi_n*xc(xsi_1) - f_xsi_1*xc(xsi_n)) %o% f_eta_1
        hdb_y <- f_xsi_n %o% yd(eta) + f_xsi_1 %o% yb(eta) +
                (ya(tau) - f_xsi_n * ya(xsi_1) - f_xsi_1*ya(xsi_n)) %o% f_eta_m +
                (yc(tau) - f_xsi_n * yc(xsi_1) - f_xsi_1*yc(xsi_n)) %o% f_eta_1
        
        #-------------------------
        # Berechnung der eta-Linien
                                               
        x_db  <- hdb_x + (f_xsi_1*(f_xsi_n^2)) %o% hd_x -
                         (f_xsi_n*(f_xsi_1^2)) %o% hb_x
        
        y_db  <- hdb_y + (f_xsi_1*(f_xsi_n^2)) %o% hd_y -
                        (f_xsi_n*(f_xsi_1^2)) %o% hb_y
       
        dhb_x_de <- (dxdde(eta)-dxbde(eta)) +
                 f_eta_m * ( -(xsi_n-xsi_1)*(-lam_ab*dyb2de2(eta))) -
                 ( (xa(xsi_n)-xa(xsi_1)) - (xsi_n-xsi_1)*(dxadt(xsi_n) -
                    lam_ab*dybde(eta))) +
                 f_eta_1 * ( -(xsi_n-xsi_1)*(-lam_bc*dyb2de2(eta))) +
                 ( (xc(xsi_n)-xc(xsi_1)) - (xsi_n-xsi_1)*(dxcdt(xsi_n) - lam_bc*dybde(eta)))
          
        dhd_x_de <- (dxdde(eta)-dxbde(eta)) +
                 f_eta_m * ( -(xsi_n-xsi_1)*(-lam_da*dyd2de2(eta))) -
                 ( (xa(xsi_n)-xa(xsi_1)) - (xsi_n-xsi_1)*(dxadt(xsi_1) - 
                    lam_da*dydde(eta))) +
                 f_eta_1 * ( -(xsi_n-xsi_1)*(-lam_cd*dyd2de2(eta))) +
                 ( (xc(xsi_n)-xc(xsi_1)) - (xsi_n-xsi_1)*(dxcdt(xsi_1) - lam_cd*dydde(eta)))
          
        dhb_y_de <- (dydde(eta)-dybde(eta)) +
                 f_eta_m * ( -(xsi_n-xsi_1)*( lam_ab*0 * eta)) -
                 ( (ya(xsi_n)-ya(xsi_1)) - (xsi_n-xsi_1)*(dyadt(xsi_n) +
                    lam_ab*dxbde(eta))) +
                 f_eta_1 * ( -(xsi_n-xsi_1)*( lam_bc* 0 *eta)) +
                 ( (yc(xsi_n)-yc(xsi_1)) - (xsi_n-xsi_1)*(dycdt(xsi_n) + lam_bc*dxbde(eta)))
          
        dhd_y_de <- (dydde(eta)-dybde(eta)) +
               f_eta_m * ( -(xsi_n-xsi_1)*( lam_da*0*eta)) -
               ( (ya(xsi_n)-ya(xsi_1)) - (xsi_n-xsi_1)*(dyadt(xsi_1) + 
                    lam_da*dxdde(eta))) +
               f_eta_1 * ( -(xsi_n-xsi_1)*( lam_cd*0*(eta))) +
               ( (yc(xsi_n)-yc(xsi_1)) - (xsi_n-xsi_1)*(dycdt(xsi_1) + lam_cd*dxdde(eta)))
       
        dhdb_xdt <- rep(1,length(tau)) %o% (-xd(eta) + xb(eta)) +
                   (dxadt(tau) + xa(xsi_1) - xa(xsi_n)) %o% f_eta_m +
                   (dxcdt(tau) + xc(xsi_1) - xc(xsi_n)) %o% f_eta_1
        
        dhdb_ydt <- rep(1,length(tau)) %o% (-yd(eta) + yb(eta)) +
                   (dyadt(tau) + ya(xsi_1) - ya(xsi_n)) %o% f_eta_m +
                   (dycdt(tau) + yc(xsi_1) - yc(xsi_n)) %o% f_eta_1
        
        dhdb_xde <- f_xsi_n %o% dxdde(eta) + f_xsi_1 %o% dxbde(eta) -
                   (xa(tau) - f_xsi_n*xa(xsi_1) - 
                      f_xsi_1*xa(xsi_n)) %o% rep(1, eta_anz) +
                   (xc(tau) - f_xsi_n*xc(xsi_1) - f_xsi_1*xc(xsi_n)) %o% rep(1, eta_anz)
        
        dhdb_yde = f_xsi_n %o% dydde(eta) + f_xsi_1 %o% dybde(eta) -
                   (ya(tau) - f_xsi_n*ya(xsi_1) - 
                      f_xsi_1*ya(xsi_n)) %o% rep(1, eta_anz) +
                   (yc(tau) - f_xsi_n*yc(xsi_1) - f_xsi_1*yc(xsi_n)) %o% rep(1, eta_anz) 
        
        dx_db_dt  <- dhdb_xdt + (f_xsi_n^2 - 2*f_xsi_1*f_xsi_n) %o% hd_x -
                               (f_xsi_1^2 - 2*f_xsi_1*f_xsi_n) %o% hb_x
        
        dy_db_dt  <- dhdb_ydt + (f_xsi_n^2 - 2*f_xsi_1*f_xsi_n) %o% hd_y -
                               (f_xsi_1^2 - 2*f_xsi_1*f_xsi_n) %o% hb_y
        
        dx_db_de  <- dhdb_xde + (f_xsi_1*(f_xsi_n^2)) %o% dhd_x_de -
                               (f_xsi_n*(f_xsi_1^2)) %o% dhb_x_de
        
        dy_db_de  <- dhdb_yde + (f_xsi_1*(f_xsi_n^2)) %o% dhd_y_de -
                               (f_xsi_n*(f_xsi_1^2)) %o% dhb_y_de
    
       res <- list(x_db, y_db, dx_db_dt, dx_db_de, dy_db_dt, dy_db_de)
         names(res) <- c("x_db", "y_db", "dx_db_dt", "dx_db_de", "dy_db_dt", "dy_db_de")
      return(res)
      } 

    #---------------------------------------------------------------------------
      drhodeta <- function (tt ,y ,...){
      #   derivatives with respect to eta for ivp
            coords <-  koor_dbm(eta=tt, tau=y, ...)    
            rhodot <-   with(coords, 
                    -(dx_db_dt * dx_db_de + dy_db_dt * dy_db_de) / (dx_db_dt^2 + dy_db_dt^2)
                 )
      return( list(as.vector(rhodot)) )    
      }
 
    #-------------------------------------------------------------------------------      
      write.geofile <- function( outfile, w_fix=0 , ...){   
      #   write CATFLOW geometry file
          fid <- file(outfile, open="w")
          # three header lines
          write(sprintf("%6i %6i %7.4f %5i  (%3i Punkte)" ,eta_anz, xsi_anz, w_fix, 
                        numh, punkteh), fid)
          write( sprintf('%12.2f %12.2f %8.2f'  ,re_bez, ho_bez, z_bez), fid)
          write( sprintf('%12.2f %10.4f %10.4f'  ,tot.area, breite, laenge), fid)
          # column with eta values
          write( sprintf('%10.8f', eta), fid)
          # four columns with xsi, real-world coords of slope, slope width
          write( sprintf('%10.8f %12.4f %12.4f %12.4f' ,xsi, re, ho, varbr) ,fid)
          # seven columns with y, x, fe, fx, angle of xsi, angle anisotropy, 1
          write( sprintf('%10.4f %10.4f %14.8f %14.8f %12.8f %8.4f %i', 
                          as.vector(y), 
                            as.vector(x),
                              as.vector(t(sqrt(g_eta))), 
                                as.vector(t(sqrt(g_xsi))),
                                  as.vector(t(ws)),  
                                    as.vector(t(wh)), 
                                      1) ,fid)
          close(fid)
        return(invisible(NULL))  }

#-------------------------------------------------------------------------------

    plofun <- function(plottitle="Model geometry (zoom enabled)", ...) {
    # plotting function 
              matplot(x,y, t="l", pch="", main=plottitle, ...)
              matlines(t(x),t(y), t="l", pch="",...)
              return(invisible())}
  
#-------------------------------------------------------------------------------
## end of definitions of internal functions

################################################################################
# Start of geometry routine
################################################################################
   on.exit(return(res), add=TRUE)
 
  tik <- Sys.time()

################################################################################
################################################################################
##  
  #-----------------------------------------------------------------------
  #  Generate net of orthogonal coordinates from 
  #  coordinates of slope line 'C' and thickness dyy
  #-----------------------------------------------------------------------
  #
  #      e ^                                 predefined functions:
  #      t |
  #      a      C                            XA(tau) XA'(tau)   --> xa(tau) dxadt(tau)
  #         ---------                        YA(tau) YA'(tau)
  #        |         |                       XC(tau) XC'(tau)
  #       D|         |B                      YC(tau) YC'(tau)
  #        |         |                       XB(eta) XB'(eta) XB''(eta)
  #   y ^   ---------   --> xsi, tau         YB(eta) YB'(eta) YB''(eta)
  #     |       A                            XD(eta) XD'(eta) XD''(eta)
  #      -->                                 YD(eta) YD'(eta) YD''(eta)
  #       x
  #
  # Sides A and D determine the coordinates
  #-----------------------------------------------------------------------
 
  #-----------------------------------------------------------------------
  #  Generate:  upper boundary (C) pxc, pyc, rec, hoc
  #             lower boundary (A) pxa, pya
  #-----------------------------------------------------------------------
  
    # xsi, eta: start/ end values, length of vectors
    xsi_1 <- xsi[1]; xsi_n <- xsi[length(xsi)]; xsi_anz <- length(xsi)
     eta_1 <- eta[1]; eta_m <- eta[length(eta)]; eta_anz <- length(eta) 
      punkteh <- length(xh)
                        
    br  <- bh             # slope widths                                          
    rec <- xh             # eastings of slope line                                
    hoc <- yh             # northings of slope line                               
    pyc <- zh             # elevations of slope line => y-coordinate              
 
  # calculate horizontal distances between points of slope line
    dre <- diff(rec)
    dho <- diff(hoc)
    dx <- sqrt(dre^2+dho^2)

  #####################
  #  gr: gradient at left side; gre: gradient at right side
  gr <- (pyc[1]-pyc[2])/dx[1]                                   # -> both gr + gre positive
   gre <- (pyc[length(pyc)-1]-pyc[length(pyc)])/dx[length(dx)]  # order correct?
                                                                # gre only used in check below
                                                                
      # checking tangents at boundaries
      if ((gr==0) && (htyp==1)){  
       stop('Constant thickness, but tangents are horizontal. Please use different geometry!')
          }   # zero gradient causes problems in construction of supplement point
      if ((!(gr==0) || !(gre==0)) && htyp==2){ 
       warning('Cake shape-geometry, but tangents are not horizontal. Please check geometry!')
          }    ## not critical, but geometry maybe useless 

  
  ##########################################################
  # Defining coordinates for upper and lower boundaries C,A 
  # for specified type of geometry
  ##########################################################
  
    #-----------------------------------------------------------------
    # Type 1: constant thickness; tangents at endpoints not horizontal
    if (htyp==1){
    
     mm <- length(pyc)                       # counter for no. of points
  
      ## Shifting upper boundary perpendicular to tangent at boundary point
      
      #  x-coordinate of side A (lower boundary)
      pxa <- c(0,  cumsum(dx))        

      dxx <- -dyy* (pyc[2]-pyc[1]) / (pxa[2]-pxa[1])
  
      pya <- pyc-dyy                      
                                          
      if (dxx > 0)  {                     
        pxc <-  pxa + dxx                 
       } else {                           
        pxc <- pxa                        
        pxa <- pxc-dxx                    
        }
    
    #-------------------------------------------
    ## Type 2: "Cake shape"; tangents horizontal
    } else if (htyp == 2){      
                pya <- rep(min(pyc)-dyy, length(pyc) )
                pxc <- c(0, cumsum(dx))
                pxa <- pxc
                mm <- length(pxc)            
    #-------------------------------------------
    ## Type 3: lower boundary as smooth spline ; tangents horizontal
    
    } else if( htyp==3){             
      
      #  Extrapolation of supplementary points: repeating first and last value
      #  y-coordinates of side C (upper boundary) + supplementary points
      pyc <- c(pyc[1], pyc, pyc[punkteh])                                     # 
      
      mm <- length(pyc)                       # counter for no. of points
  
      br  <- c(br[1], br, br[punkteh])         # repeat first and last value of widths
      
      # complete eastings/northings for supplement point, using 0.1% of total length
      rec <- c(rec[1]-diff(range(rec))/1000, rec, rec[punkteh]+diff(range(rec))/1000)           
      hoc <- c(hoc[1]-diff(range(hoc))/1000, hoc, hoc[punkteh]+diff(range(hoc))/1000)     
      
      dre <- diff(rec); dho <- diff(hoc)
      dx <- sqrt(dre^2+dho^2)

      #  x-coordinates of side C (upper boundary); starting from zero
        pxc <- c(0,  cumsum(dx))        
     
     #  coordinates of side A (lower boundary) : two endpoints at each side with y = const  
      
     ## Spline 
      pxa <- pxc[c(1:2,(mm-1):mm)]
      pya <- rep(pyc[c(1,mm)], each=2) - dyy
    
       side.a <- interpSpline(pxa,pya)
     
    ### Possibly: thickness is not kept
       # check if predicted pya is higher than pyc
       if( any(pyc- predict(side.a, pxc)$y < (1-thick.tol) * dyy) | 
            any(pyc- predict(side.a, pxc)$y > (1+ thick.tol)* dyy) ){
   
        # iterative method
        i <- 1
        # refine if minimum thickness (two-third) is not reached   
        while(any(pyc- predict(side.a, pxc)$y < (1-thick.tol) * dyy) |
               any(pyc- predict(side.a, pxc)$y >  (1+ thick.tol)* dyy) ) {         
                                                
              midp <- unique(as.integer(seq(1,(2^i)-1)* 1/ 2^i  *mm)      )
                      ###
                      # 1     mm/2
                      # 2     mm/4 mm*2/4 mm*3/4
                      # 3     mm/8, mm*2/8, 3/8*mm, mm*4/8, mm*5/8, mm*6/8, mm*7/8 
                      # 4     ...
              midp <- subset(midp, !midp %in% c(0:2, (mm-1):mm))
              
              if(length(midp) > length(pxc))  {i= i-1; break()}   # if too long, reset and stop
              
              pxa <- pxc[c(1:2, midp, (mm-1):mm)]

              pya <- c(rep(pyc[1], 2), pyc[midp],rep(pyc[mm], 2)) - dyy 
              
              side.a <- interpSpline(pxa,pya)
              i <- i+1      
              }
     }  # end if 
      
      pxa <- pxc
      pya <- predict(side.a, pxc)$y
          
  }  # end if type == 3    
  #-----------------------------------------------------------------
  ###  end case differentiation by type of geometry 
            
  ###
  # Slope length and slope width
  laenge <- diff(range(pxc))
  breite <- tot.area / laenge                       # 'average width' of slope  

  ##--------------------------------------------

  # Coordinates of left boundary D (endpoints)
    pxd <- c(pxa[1], pxc[1])
    pyd <- c(pya[1], pyc[1])

  # Coordinates of right boundary B (endpoints)
    pxb <- c(pxa[mm], pxc[mm])
    pyb <- c(pya[mm], pyc[mm])

#########################################################################
#########################################################################

#-----------------------------------------------------------------------
#  Calculating values of simulation grid coordinates   
#-----------------------------------------------------------------------
 
 min_xa <- min_xd <- min(pxa)
 max_xa <- min_xb <- max(pxa)
 min_xc <- max_xd <- min(pxc)
 max_xc <- max_xb <- max(pxc)

  ##
  #   Differentiation by type of geometry
  ##
  if (htyp==1){
    
    #-----------------------------------------------------------------------
    #  Boundaries as polynomials
    #-----------------------------------------------------------------------
    
    # straight line through endpoints of sides B and D
    grad_b <- lm(pyb~pxb)     #= gradient(pyb,pxb)
    grad_d <- lm(pyd~pxd)     #= gradient(pyd,pxd)
    
    # slope of line
    grad_ba <- coef(grad_b)[2]
    grad_da <- coef(grad_d)[2]
    
    # plotting
     if(plotting){
      matplot(cbind(pxa,pxc),cbind(pya,pyc), t="l", main="Geometry boundaries")
      matpoints(cbind(pxb, pxd),cbind(pyb,pyd), pch=21)
      # original slope line 
      matpoints(sqrt((xh - xh[1])^2 + (yh - yh[1])^2) + dxx,zh, col=3, t="l")
        
       legend("topright", "Original slope line", col=3, lty=3, pch=20, bty="n")
       abline(grad_b,  col=1); abline(grad_d, col=2) 
       #if(interactive()) bringToTop(which =  dev.cur())
       }
    
    #----------------------------------------------------------------------------------
    # splines of sides A,C,B,D
    # cspe:	Cubic spline interpolation with end-conditions.
    #------------------------------------------------------------------------------------
      ppya <-  cspe(pxa, pya, c(-1/grad_da, -1/grad_ba))
      ppyc <-  cspe(pxc, pyc, c(-1/grad_da, -1/grad_ba))
      ppyb <-  cspe(pxb, pyb, c(grad_ba, grad_ba))          # pyb, pxb
      ppyd <-  cspe(pxd, pyd, c(grad_da, grad_da))          # pyd, pxd
      #                         |         |
      #                         |         |  end-condition for right side
      #                         |              (here: slope of side B)
      #                         |  end-condition for left side
      #                             (here: slope of side D)

   #----------------------------------------------------------------------
   # Type 2: "Cake shape"
   } else if (htyp==2)
   {
        # mkpp makes pp object with knots (x-coord) and coefficients: intercept, slope, ... 
        ppya <- mkpp(c(pxa[1], pxa[length(pxa)]) , c(pya[1], 0) , make.poly=TRUE) 
         ppyc <- cspe(pxc, pyc, c(0, 0) )
          ppyb <- mkpp(pyb, c(pxb[1], 0) , make.poly=TRUE)    # order y,x at 
            ppyd <- mkpp(pyd, c(pxd[1], 0) , make.poly=TRUE)  # sides B, D (reversed)!
                
   #----------------------------------------------------------------------
   # Type 3: lower boundary as smooth spline
   } else if(htyp==3) 
      { ppya <- cspe(pxa, pya, c(0, 0) )
         ppyc <- cspe(pxc, pyc, c(0, 0) )
          ppyb <- mkpp(pyb, c(pxb[1], 0) , make.poly=TRUE)    
            ppyd <- mkpp(pyd, c(pxd[1], 0) , make.poly=TRUE)
      }
  ##----------------------------------------------------------------------------
   
 ###############################################################################
   
#-------------------------------------------------------------------------------
# Case differentiation (cf. Kiefer et al.,  p.33)  
#-----------------------------------------------------------------------
  
 if ( abs(dybde(eta[1])) >= abs(dxbde(eta[1])) ) {
          lam_ab <- dxadt(xsi[length(xsi)])/dybde(eta[1])
    } else lam_ab <- -dyadt(xsi[length(xsi)])/dxbde(eta[1])

  if ( abs(dybde(eta[length(eta)])) >= abs(dxbde(eta[length(eta)]))){
          lam_bc <-  dxcdt(xsi[length(xsi)])/dybde(eta[length(eta)])
    } else lam_bc <- -dycdt(xsi[length(xsi)])/dxbde(eta[length(eta)])

  if ( abs(dydde(eta[length(eta)])) >= abs(dxdde(eta[length(eta)])) ){
         lam_cd <-  dxcdt(xsi[1])/dydde(eta[length(eta)])
    } else  lam_cd <- -dycdt(xsi[1])/ dxdde(eta[length(eta)])

  if ( abs(dydde(eta[1])) >= abs(dxde(eta[1], max_xd, min_xd)) ){
          lam_da <-  dxadt(xsi[1])/dydde(eta[1])
     } else lam_da <- -dyadt(xsi[1])/dxde(eta[1], max_xd, min_xd)

##-----------------------------------------------------------------------
##  Calculate vertical set of curves
##-----------------------------------------------------------------------
  rho <- matrix(xsi, nrow=1)
  tic <- Sys.time()
  #start loop over eta
  cat("Calculating eta:") ;   #if(interactive())  bringToTop(-1)
  
   for ( i in 1:(eta_anz-1)){
          # info on console       
          if( i %% 6 == 0){ cat(sprintf("\t[%2.2f...%2.2f]\n\t\t", eta[i], eta[i+1]))  
          } else cat(sprintf("\t[%2.2f...%2.2f]", eta[i] , eta[i+1]))  
          flush.console()
        
    ### numerical solution of ivp with ode
      erg <- ode(y=rho[i,], t=eta[i:(i+1)], drhodeta, parms= NULL,  method="ode23")
      rho <- rbind(rho , erg[-1,-1])    # second row, without 'time' column
  } 
  # end loop along eta
  
  cat(paste("\n  ... eta has been calculated in", format(Sys.time()-tic, digits=3),"\n\n")) 
  
  attr(rho, "dimnames") <- NULL    # drop char vector with row numbers

#-----------------------------------------------------------------------
#  Calculate metric coefficients and inclination of coordinates
#-----------------------------------------------------------------------
  drhodxsi <- apply(rho,1,gradient, h = xsi)    
 
  g_eta <- g_xsi <- dx_dxsi <- dy_dxsi <- x <- y <- array(dim=c(xsi_anz,eta_anz))
 
   # loop along eta: fill columns of x, y, g_eta, g_xsi, dx_dxsi, dy_dxsi
   tic <- Sys.time() 
   cat("Calculating metric coefficients for eta:"); flush.console()
  
  for (i in seq(along=eta)){       
                 # info on console
                 if( i %% 9  == 0){ cat(sprintf("\t%2.2f\n\t\t\t\t\t", eta[i]))  
                  } else  cat(sprintf("\t%2.2f", eta[i]))
                 flush.console()
      
      # list of variables from koor_dbm                  
      temp <- koor_dbm(eta[i], tau=rho[i,], typ=htyp)      
        sq <- with(temp, (dx_db_dt^2 + dy_db_dt^2))
          g_eta[,i] <- with(temp, ((dx_db_dt * dy_db_de - dx_db_de * dy_db_dt)^2)) / sq
            g_xsi[,i] <- sq *(drhodxsi[,i]^2)  
              dx_dxsi[,i] <-temp$dx_db_dt      # [dx_dxsi dy_dxsi] are the tangent vectors
                dy_dxsi[,i] <-temp$dy_db_dt    # for eta=const
                  x[,i] <- temp$x_db 
                    y[,i] <- temp$y_db 
    }
    # end loop over eta
    cat(paste("\n  ... metric coefficients have been calculated in", 
        format(Sys.time()-tic,digits=3),"\n\n"))
 ###
 
  re <-  approx(pxc, rec, x[,length(eta)], rule=2)$y       
   ho <- approx(pxc, hoc, x[,length(eta)], rule=2)$y  
      
  # slope width
  varbr <- approx(pxc,br,x[,length(eta)], rule=2)$y
  
  # ws: angle of xsi against x, positive counterclockwise
    ws <- -atan2(dy_dxsi,dx_dxsi);
  # wh: angle of main direction of anisotropy, positive counterclockwise
    wh <- array(w.aniso, dim(ws))
  
  # transpose x, y  to get eta,xsi dimensions for later functions
    x <- t(x)
    y <- t(y)
    
##-----------------------------------------------------------------------
## end of calculations
##----------------------------------------------------------------------- 
#########################################################################
         
  #-----------------------------------------------------------------------
  #  Saving the geometry file as ASCII file for CATFLOW   
  #-----------------------------------------------------------------------             
  if(make.output) { write.geofile(outfile = out.file)
                    cat(paste("Done! Total time:", format(Sys.time()-tik,digits=3),
                            "\nGenerated geometry file", out.file,"\n\n") )
  } else cat(paste("Done! Total time:", format(Sys.time()-tik,digits=3),"\n\n") )
   #if(interactive())  bringToTop(-1)
  ## -----------------------------------------------------------------------

 ## -----------------------------------------------------------------------
 # collect calculated values for return()
  res <- list(numh, eta, xsi, y, x, re, ho, varbr, re_bez, ho_bez, z_bez,  tot.area, breite, laenge)
  names(res) <- unlist(strsplit("ID, eta, xsi, hko, sko, re, ho, var.width, re_bez, ho_bez, z_bez, tot.area, width, length", ", ") )
 
  ## flipping matrices for later use (to get first row on top)
  
  res$hko <- res$hko[length(eta):1,]
  res$sko <- res$sko[length(eta):1,]
 
 ## -----------------------------------------------------------------------


  ## -----------------------------------------------------------------------
  ##  Plot the geometry
  ## -----------------------------------------------------------------------
   if(plotting){     
    try(zoom(plofun,asp=1,...) )
    }
   # -----------------------------------------------------------------------

 
 
 
  return( invisible(res) )
 }
 