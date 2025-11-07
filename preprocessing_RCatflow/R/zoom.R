zoom <-
function (fun , ...) 
{   on.exit(par(oldpar))
  oldpar <- par(err = -1)
    
  fun(...)
     cat(paste("","Click mouse at corners of desired zoom area.\n",
          "Double-click to restore full extent;", 
          "click 'Stopp' or hit 'Esc' to stop zooming.\n", sep=" ") )
     flush.console()
  while (TRUE) {
      #bringToTop()
      p <- locator(n = 2)
      # enable stop
        if (is.null(p$x) || length(p$x) != 2)    break
      ## zoom out
        if(diff(range(p$x)) < 1e-12) {  fun(...) 
          cat("\tZooming out to original extent\n")
       # zoom in
        } else {
            xlim <- range(p$x)
            ylim <- range(p$y)
            cat("\tZooming: xlim =", signif(xlim,3), "; ylim=", signif(ylim,3), "\n")
            fun(..., xlim = xlim, ylim = ylim)
        }    
      flush.console()
    }
return(invisible())
}

