plot.macros <-
function(x, z, relfak, pc = 0.1, ...) {
  
pos.mac <- relfak > 1              # matrix of logicals indicating macropore position
maccols <- apply(pos.mac, 2, any)  # vector of column indices with macropores



# plot profile
plot(range(x), range(z), type="n", ann=FALSE)
  lines(x, z[1,], ...); lines(x, z[nrow(z), ], ...)
  
mac <- as.vector(pos.mac)
 zcor <- as.vector(z) 
  xcor <- rep(x, each = nrow(pos.mac) )

vecdat <- cbind(xcor,zcor,mac)

points(vecdat[,"xcor"],vecdat[,"zcor"], col = vecdat[,"mac"], 
      pch = 20, cex = pc, ...) 
       
return( invisible(vecdat) )
}

