del.files <-
function(direct, subdir = "out", file2del=c("ve.out", "vx.out", "c.out"))
{  
outdirs <- dir(direct, pattern=subdir)

  for (verz in outdirs) 
  {   success <- FALSE
       ind <-  file.exists(file.path(direct, verz, file2del)  )
       file2del.sel <- file2del[ind]
        success <-file.remove(file.path(direct, verz, file2del.sel) )  
     for(j in seq(along=success)) if(success[j]) cat(file.path(direct, verz, file2del.sel[j]), " deleted!\n")
  }

return(invisible())
}

