read.soil.mat <-
function(input.file = "boden.dat") {
    val <- read.table(input.file, skip=1)
    val <- as.matrix(val)
    colnames(val) <- NULL
return(val)
 }

