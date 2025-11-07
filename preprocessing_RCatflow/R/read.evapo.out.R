read.evapo.out <-
function(filename) {
   
hdr <- read.table(filename, nrow=2, skip=1, colClasses="character")
evap <- read.table(filename, skip=3)

colnames(evap) <-  apply(hdr, 2, function(x) { 
                    if(grepl("-",x[2])) {  
                        if(grepl("al",x[1]))  "albedo" else x[1] 
                     } else  paste(x[1],x[2],sep="_")} )

print(paste(filename, "read sucessfully."))

return(evap)}

