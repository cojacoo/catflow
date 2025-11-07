read.channelflow.out <-
function(filename, plotting=T) {

qo <- read.table(filename)
  names(qo) <- c("time", "icour", "cum.q", "totvol", "rain", "qmax.ls")

#  write(io(12),2500) t_neu,icour,qpegel,totvol,regen*1000.*3600., qpmax,
#     &    (qb(igang(ib)), yb(igang(ib)), vb(igang(ib)), ib=iacgng,1,-1)


 qconv <- qo[,c("time","cum.q")]
  qconv$q.ls <- c(qconv[1,"cum.q"]/qconv[1,"time"], diff(qconv[,"cum.q"])/diff(qconv[,"time"]))*1000
   qconv$time.d <- qconv$time/86400
   qconv <- qconv[,c("time.d", "q.ls") ]

 if(plotting) plot(qconv)

print(paste(filename, "read sucessfully."))

return(list("orig"=qo, "converted" = qconv))
 }

