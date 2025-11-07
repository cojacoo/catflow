read.surfrun.out <-
function(filename) {
      start.date <- read.table(filename, nrow=1)        # currently unused
      
      hdr <- read.table(filename, nrow=1, skip=1)
      
      qo <- read.table(filename, skip=2)
        names(qo) <- c("ihg", "time", "time+dt","Neff", "q", "cum.q")
        qo <-  qo[, c("time", "time+dt","Neff", "q", "cum.q","ihg" )]
        
      qconv <- vector("numeric", nrow(qo))                         
      for( i in 1:ncol(qo) )  qconv <- cbind(qconv, hdr[[i]] * qo[,i]  )
        
        if(nrow(qo) > 1 ) { qconv <- data.frame(qconv[,-1])
          } else             qconv <- qconv[,-1]
        
        names(qconv) <- names(qo)
      
      print(paste(filename, "read sucessfully."))
      
      return(list("orig"=qo, "converted" = qconv))   

# read.surfrun.old  <-
#      function(filename) {
#         
#    start.date <- read.table(filename, nrow=1)        # currently unused
#    
#    hdr <- read.table(filename, nrow=1, skip=1)
#    
#    qo <- read.table(filename, skip=2)
#      names(qo) <- c("ihg", "time", "Neff", "q", "cum.q")
#      qo <-  qo[, c("time", "Neff", "q", "cum.q","ihg" )]
#      
#    qconv <- vector("numeric", nrow(qo))                         
#    for( i in 1:ncol(qo) )  qconv <- cbind(qconv, hdr[[i]] * qo[,i]  )
#      
#      if(nrow(qo) > 1 ) { qconv <- data.frame(qconv[,-1])
#        } else             qconv <- qconv[,-1]
#      
#      names(qconv) <- names(qo)
#    
#    print(paste(filename, "read sucessfully."))
#    
#    return(list("orig"=qo, "converted" = qconv))
#      }

}

