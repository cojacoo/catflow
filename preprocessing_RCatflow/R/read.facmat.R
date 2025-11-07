read.facmat <-
function(input.file) {
  val <-scan(input.file)
       headr= list("ID"=val[1],"eta"=val[2],"xsi"=val[3])
  val <- val[-(1:3)]  
  val <- matrix(val,nrow = headr$eta, ncol=headr$xsi, byrow=T)   
  return(val)
}

