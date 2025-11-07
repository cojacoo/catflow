catf.batch.cleanup <-
## cleans up in simulation directories
function( fol,                     # directory with Catflow run to 'clean'
          indir = "./in",          # subdirectory with input files
          tardir="./Preproc",      # new subdirectory for input files to keep
          interact=TRUE )          # logical: interactive use?
{
        
work.dir <- getwd()
 on.exit(setwd(work.dir))

setwd(fol)
print(getwd() )    # print current dir

 
   # copy files to keep into directory "preproc"              
    copy.files <- function(quelle , ziel = tardir)  {
            if(length(quelle) >0 ) { 
             if(any(file.exists(quelle))) {
                  if(!file.exists(ziel)) dir.create(ziel)
                  file.copy(quelle, ziel)
               }   }
               return(invisible(quelle))   }
  
  # save geometry and distribution of soil types, using wildcard's
   file.list <- list( Sys.glob(file.path(indir, "*.geo")),
                        Sys.glob(file.path(indir, "*.bod")),
                    #      Sys.glob(file.path(indir, "*.obj")),
                           Sys.glob("*.dat"),                # angles.dat, boden.dat
                            Sys.glob("*.obj")  )                # R geometry objects
   fils <- lapply(file.list, copy.files)
   cat(paste("Copied:", paste(unlist(fils), collapse=", "), "\n to ", tardir, "\n")) 
  
  # delete unnecessary stuff
    # delete input dir
     del.indir <- function(in.dir){
       #bringToTop(-1)
        frage <- readline(paste("Really delete directory", in.dir, 
        "and all files therein ? ") )
     
        if(frage == "y" | frage == "Y") { unlink(in.dir, rec=TRUE)     
             print(paste("Directory", in.dir, "and all files therein deleted" ) )
           } else print(".. cancelled by user")
       return(invisible(frage))
     }

  if(interact) del.indir(indir)   else  {unlink(indir, rec=TRUE)
                                      print(paste("Directory", indir, 
                                      "and all files therein deleted" ) ) }
  
    # delete ALL files (but not directories)
      del.all.files <- function(tar.dir){
         #bringToTop(-1)
        frage <- readline(paste("Really delete all files in ", tar.dir, "? ") )
       
        if(frage == "y" | frage == "Y") { file.remove(Sys.glob(file.path("*.*")) )      
             print(paste("All files in", tar.dir, "deleted" ) )
           } else print(".. cancelled by user")
       return(invisible(frage))
       }
  
  if(interact) del.all.files(fol)    else { file.remove(Sys.glob(file.path("*.*")) )
                                        print(paste("All files in", fol, 
                                        "deleted" ) )}

return(invisible(paste(fol, "cleaned"))) 
}

