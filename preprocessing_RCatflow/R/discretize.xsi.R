discretize.xsi <-
function(relfak, steps=1, max.dist, dimfak,  reg=TRUE){
                                             # flag for generating regular grid
                                             #  (using max.dist)
                                    # fraction of dimension to compute missing max.dist
                          # maximum seperation [no. columns]
                             
                  # stepsize for discretization next to macropores
          # matrix of multipliers for conductivity
     
# compute lateral discretization (xsi vector); fine resolution at simulated macropores +- steps
   
  pos.mac <- relfak > 1    # position matrix of macropores
  d <- dim(relfak)[2]      # dimension in consideration (1: no. rows , 2: no. columns)
  
  if(missing(dimfak)) dimfak <- 0.025
  if(missing(max.dist)) max.dist <- dimfak*d      # set to 2.5% of total size
  
  macpos <- apply(pos.mac, 2, any)  # vector of column indices with macropores
 
  if(any(macpos)){
    macpos <- which(macpos)
   
    # include 'steps' adjacent positions 
    macpos <- sapply(macpos, function(x) x + -steps:(steps))  ## jw
    macpos <- unique(as.vector(macpos))                         
    
    if(is.unsorted(macpos)) macpos <- sort(macpos)
    # check if out of range
    macpos <- macpos[macpos>0 & macpos <= d]
    
    # check if endpoints are included
    if(all(macpos!=1)) macpos <- c(1,macpos)
    if(all(macpos!=d)) macpos <- c(macpos,d)
  
  } else macpos <- c(1,d)
    
  ## keeping maximum seperation
  if(reg & any(diff(macpos)> max.dist)) {
    left <- macpos[which(diff(macpos) > max.dist)]
    right <- macpos[which(diff(macpos) > max.dist)+1]
    gap <- cbind(left,right)
     gap <- unlist(apply(gap, 1, 
            function(x) seq(x["left"],x["right"], length=diff(range(x)/max.dist)) ))
    macpos <- unique( sort(c(macpos, as.integer(gap) )) )
    
   } else if(any(duplicated(macpos))) macpos <- unique(macpos)
                                        # check for duplicates
    
  discret <- seq(0,1, length=d)
    
  discret <- sort(discret[macpos])

return(discret)
}

