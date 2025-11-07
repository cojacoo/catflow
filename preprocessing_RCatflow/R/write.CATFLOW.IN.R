write.CATFLOW.IN <-
function(control.files, project.path = NULL, flag = 2)
   {
   if(is.null(project.path)) { main.file = "CATFLOW.IN"  
    } else { main.file = file.path(project.path, "CATFLOW.IN") }
   
 controllist <-   list(x=control.files, y = NA )
 
 for (j in seq(along = controllist$x)) controllist$y[j] <- format(paste(flag,".",sep=""), justify="r", width=35-nchar(controllist$x[j])) 
  
  write.table(controllist,  
              file=main.file, row.names=FALSE, col.names=F, quote=F)
   
  print(paste("File '", main.file,"' produced with", length(control.files), "control file(s)." ))

  return(invisible())
}
 