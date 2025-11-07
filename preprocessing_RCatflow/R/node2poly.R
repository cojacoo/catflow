node2poly <-
function( xv = sko, yv = hko, sel ) { 
        ##                    # take all or selection of columns  
        ## takes matrices of node coordinates 
        ## and generates coordinates polygons around nodes
                            
if(missing(sel)) {sko <- xv               # make selection
                    hko <- yv
  } else { sko <- xv[,sel]
            hko <- yv[,sel]  }
            
# number of nodes
eta <- nrow (sko); xsi <- ncol(sko)

# area of nodes
A <- matrix(nrow = eta,ncol = xsi)

node.area <- function(x, y)   
    { # calculates area of convex quadrilateral from x and y coordinates
      #             1--4
      #             |  |
      #             2--3
        A <- 1/2*abs((x[1]-x[3])*(y[1]-y[3]) - (x[4]-x[2])*(y[4]-y[2]))
     return(A)
    }

# boundaries of nodes (at midpoint)
# lateral midpoints
 latg <-  t(apply(sko,1,diff)/2)
   xx <-  cbind(sko[,1], sko[,-ncol(sko)] + latg, sko[,ncol(sko)] )

 verg <- t(apply(hko,1,diff)/2)
   yy <- cbind(hko[,1],  hko[,-ncol(hko)] + verg , hko[,ncol(hko)] )

### + vertical midpoints
 lath <- apply(xx,2,diff)/2
   xxx <-  rbind(xx[1,], xx[-nrow(xx),] + lath, xx[nrow(xx),] )

 verh <- apply(yy,2,diff)/2
  yyy <- rbind(yy[1,],  yy[-nrow(yy),] + verh , yy[nrow(yy),] )

# polygon boundaries
for (j in 1:(xsi)) {
for (k in 1:(eta) ){  
      # index <- c(k,k+1,k+eta+1,k+eta)+eta*(j-1)
        if ((k == 1 & j == 1)) {
          a2 <- c(xxx[c(k,k+1),j], xxx[c(k+1,k),j+1])
          b2 <- c(yyy[c(k,k+1),j], yyy[c(k+1,k),j+1])
        } else {      # NA to seperate polygons
          a2 <- c(a2, NA, c(xxx[c(k,k+1),j], xxx[c(k+1,k),j+1]))        
          b2 <- c(b2, NA, c(yyy[c(k,k+1),j], yyy[c(k+1,k),j+1]))
          }
   A[k, j] <- node.area(x = c(xxx[c(k,k+1),j], xxx[c(k+1,k),j+1]),
                        y = c(yyy[c(k,k+1),j], yyy[c(k+1,k),j+1]))
}  }

return((list("hor" = a2, "vert"  = b2, "area" = A)))
} 

