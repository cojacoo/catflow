read.catf.balance <-
function(res.path, balance.file="bilanz.csv", differences  = FALSE, plottin = FALSE, col.no, ... ) {
 # reads file balance file, takes differences of data,  
 # plots original and differences, 
 # and returns either original data or differences 
 if(missing(res.path))  { filename <- balance.file           # in current dir
  } else { if( "csv" %in% unlist(strsplit(res.path, "\\.")) )               # filename included in path?
              { filename <- res.path                            
            } else filename <- file.path(res.path,balance.file)
          }
      
  datafile <- readLines (filename)
    lang <- length(datafile)         # length of data file
     endtab <- grep("Abschlusstabelle",datafile)
 
  # read header: names and units
    header <- unlist(strsplit (datafile[1], ";"))
    units  <- unlist( strsplit(datafile[2], ";"))         
       namen <-  sub( "kumul.","", header  )  
            namen <- gsub( "[[:punct:]]","", namen  )  
              namen <- paste(namen,units)          # include units
                  namen <-  gsub('[[:space:]]', '', namen)    
 
   
   # read data ; no. of rows: length of file - length of header - final table
    if(length(endtab)>0){
    data <- unlist( strsplit(datafile[3:(endtab-1)], ";")) 
      data[grep( "Infinit", data)]  <- NA          # replace "Infinite" with NA
       data <- matrix(as.numeric( data), nrow = endtab - 2 -2 , byrow = TRUE)
       data <- as.data.frame(data)
    
    } else {  # case of incomplete balance file / stopped during calculation
     data <- unlist( strsplit(datafile[3:(lang)], ";")) 
      data[grep( "Infinit", data)]  <- NA          # replace "Infinite" with NA
       data <- matrix(as.numeric( data), nrow = lang - 2 , byrow = TRUE)
       data <- as.data.frame(data)
      }
      
   # assign column names
    names(data) <-  namen[1:ncol(data)]       
  
    # take differences, because variables cumulated in output
   differenced <- function(x) {   dummy <- rbind(0 ,x)                   # appending 0 for keeping length
                     diffdata <- as.data.frame(apply(dummy, 2, diff))
                     diffdata[,1:3] <- x[,1:3]             # ID and Time not differenced
                     return(diffdata)
   }
  
 
 # check wether there are several slopes
  if(length(unique(data[,grep("Hg", namen)])) > 1) 
    {data <- split(data, data[,grep("Hg", namen)]) 
      if(differences) diffdata <- lapply(data, differenced)
      if(plottin) cat("Balance file with several slopes. No plotting in this case - use 'lapply('result', plot.catf.bal)' instead.\n")        ## JW
  } else  { 
     
    if(differences) diffdata <- differenced(data)
 
    ### Plotting selected columns vs. time [d]
    # 1 "Hg"      2"Zeitschritt"   3"Zeit"          
    #     4"totaleBil"     5"Auffeuchtung"    6 "SummeSenkenfl" 
    #         7"SummeRandfl"   8"Oberrandfl"    9"rechterRandfl"   
    #             10"Unterrandfl"  11"linkerRandfl"  12"OberflAbfl"        
    #                 13"AbflBeiwert"   14"FreilandNied"  15"FreilandNied1" 
    #                     16 "InterzVerd"   17 "Bodenverd"    18 "Transpiration"
    #                     19-21: links, unten, rechts: Verlust Stoff1
    #                     22-24: links, unten, rechts: Verlust Stoff2
    #                     25-27: links, unten, rechts: Verlust Stoff3
    ###########
                         
     # define time vector [column 'Zeit', in s]
        zeit <- data[,3]
   
    if(plottin) {
     if(missing(col.no)) col.no <- 4:ncol(data)
    
        # plot differences 
     if(differences){
        par(mfrow = c(2,1))
        matplot((zeit/3600/24), diffdata[,col.no], type = "l", lty = 1:5, lwd = 1, 
            col = rainbow(length(col.no)), xlab = "time", ylab = "Fluxes",
            main = sub(".csv", "", filename), ...)         
        legend("topl", legend = namen[col.no], lty = 1:5, col = rainbow(length(col.no)), 
              bty = "n", ... )
        # cumulated data (original)
        matplot((zeit/3600/24),data[,col.no], type = "l", lty = 1:5, lwd = 1, 
            col = rainbow(length(col.no)), xlab = "time", ylab = "Cum. Fluxes",
            main = sub(".csv", "", filename), ...)         
        legend("topleft", legend = namen[col.no], lty = 1:5, 
                bty = "n", col = rainbow(length(col.no)), ...)
        
      } else {
          # cumulated data (original)
       matplot((zeit/3600/24),data[,col.no], type = "l", lty = 1:5, lwd = 1, 
          col = rainbow(length(col.no)), xlab = "time", ylab = "Cum. Fluxes",
          main = sub(".csv", "", filename), ...)         
       legend("topleft", legend = namen[col.no], lty = 1:5, 
              bty = "n", col = rainbow(length(col.no)), ...)
        }
     }
    }
       
    print(paste(filename, "read sucessfully."))
  
   if(differences)   return(diffdata) else
   
return(data)
}

