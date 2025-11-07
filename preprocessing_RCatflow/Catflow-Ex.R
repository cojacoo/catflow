pkgname <- "Catflow"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
options(pager = "console")
library('Catflow')

assign(".oldSearch", search(), pos = 'CheckExEnv')
cleanEx()
nameEx("assign.mac.soil")
### * assign.mac.soil

flush(stderr()); flush(stdout())

### Name: assign.mac.soil
### Title: Write a file with node-wise assignment of soil identifiers
### Aliases: assign.mac.soil
### Keywords: utilities

### ** Examples

  ## Not run: 
##D   set.seed(-80)
##D   
##D   assign.mac.soil(output.file = "soil_horizons.bod", 
##D                   macgrid= matrix(rnorm(30, mean=3, sd=1), nrow=5, ncol=6),
##D                   thresh = 4, soil.matrix = 1, soil.macro = 2, numh = 1)
##D   
##D   file.show("soil_horizons.bod")
##D   
##D   ## maybe you like to delete the produced file
##D      unlink("soil_horizons.bod")
##D   
## End(Not run)



cleanEx()
nameEx("catf.batch.cleanup")
### * catf.batch.cleanup

flush(stderr()); flush(stdout())

### Name: catf.batch.cleanup
### Title: Batch cleanup after CATFLOW simulation
### Aliases: catf.batch.cleanup
### Keywords: utilities

### ** Examples

 ## Not run: 
##D   # some input files
##D     test.files <- c("del.me.dat", "del.me.in", "del.me.geo")
##D   # make dummy simulation directory
##D     dir.create("./TEST.CATFLOW")
##D   # produce dummy test files in simulation directory
##D     sapply( test.files, function (nam) {
##D             cat("Test file 1 for function 'catf.batch.cleanup' (package CATFLOW)", 
##D             file= paste("./TEST.CATFLOW", nam, sep="/1") )    
##D             return("written")})
##D   ## make dummy input subdirectory
##D     dir.create("./TEST.CATFLOW/test.in")  
##D   ## produce dummy test files in input subdirectory
##D     sapply( test.files, function (nam) {
##D             cat("Test file 2 for function 'catf.batch.cleanup' (package CATFLOW)", 
##D             file= paste("./TEST.CATFLOW/test.in", nam, sep="/2") )    
##D             return("written")})
##D 
##D   print(dir("TEST.CATFLOW", rec=T))
##D 
##D   # ... and delete the dummy files, keeping '1del.me.dat' and '2del.me.geo'
##D   catf.batch.cleanup("./TEST.CATFLOW", indir = "./test.in", interact = FALSE)
##D 
##D   print(dir("TEST.CATFLOW", rec=T))
##D    
##D ## delete the produced dummy simulation directory with all contents
##D   unlink("./TEST.CATFLOW", rec=T)
##D  
## End(Not run)



cleanEx()
nameEx("del.files")
### * del.files

flush(stderr()); flush(stdout())

### Name: del.files
### Title: Delete unnecessary simulation results
### Aliases: del.files
### Keywords: utilities

### ** Examples

  ## Not run: 
##D     # make dummy simulation directory
##D       dir.create("./TEST.CATFLOW")
##D     # make dummy results subdirectory
##D       dir.create("./TEST.CATFLOW/test.out")  
##D     # some unnecessary concentration results
##D       test.files <- c("ve.out", "vx.out", "c.out")
##D     # produce dummy test files
##D       sapply( test.files, function (nam) {
##D               cat("Test file for function 'del.files' (package CATFLOW)", 
##D               file= paste("./TEST.CATFLOW/test.out", nam, sep="/") )    
##D               return("written")})
##D   
##D     print(dir("TEST.CATFLOW", rec=T))
##D     
##D     # ... and delete the dummy files
##D     del.files("./TEST.CATFLOW", file2del=test.files)
##D   
##D   ## delete the produced dummy simulation directory with all contents
##D      unlink("./TEST.CATFLOW", rec=T)
##D   
## End(Not run)



cleanEx()
nameEx("discretize.mak")
### * discretize.mak

flush(stderr()); flush(stdout())

### Name: discretize.mak
### Title: Make new discretization for simulated vertical macropores
### Aliases: discretize.mak
### Keywords: utilities

### ** Examples

 # some slope line
 test.slope <- data.frame(xp = seq(0, by=0.614, length=20) ,
                          yp = seq(0, by=0.1, length=20) ,
                          zp = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                          width = rep(1,20) )
                          
 # new simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.05, dz.max = 0.05)
 
 # simulate vertical macropores
 sim <- sim.mak(test.sim.grid$x, test.sim.grid$z, test.sim.grid$width, x.step=10)
 
 # plot slope profile with simulated structures
 plot.macros(test.sim.grid$x, test.sim.grid$z, sim$relfak)
 
 # new xsi- and eta vectors
 disc <- discretize.mak(sim, maxdists = c(5,3), plottin = TRUE)




cleanEx()
nameEx("discretize.pipe")
### * discretize.pipe

flush(stderr()); flush(stdout())

### Name: discretize.pipe
### Title: Make new discretization for a simulated pipe
### Aliases: discretize.pipe
### Keywords: utilities

### ** Examples

 # some slope line
 test.slope <- data.frame(xp = seq(0, by=0.614, length=20) ,
                          yp = seq(0, by=0.1, length=20) ,
                          zp = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                          width = rep(1,20) )
                          
 # new simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.05, dz.max = 0.05)
 
 # simulate vertical macropores
 sim <- sim.pipe(test.sim.grid$x, test.sim.grid$z, test.sim.grid$width, 
                 start.depth = 1)
                  
 # plot slope profile with simulated structures
 plot.macros(test.sim.grid$x, test.sim.grid$z, sim$relfak)
 
 # new xsi- and eta vectors
 disc <- discretize.pipe(sim, maxdists = c(10,2), plottin = TRUE)



cleanEx()
nameEx("discretize.rect")
### * discretize.rect

flush(stderr()); flush(stdout())

### Name: discretize.rect
### Title: Make new discretization for connected macropores
### Aliases: discretize.rect
### Keywords: utilities

### ** Examples

 # some slope line
 test.slope <- data.frame(xp = seq(0, by=0.614, length=20) ,
                          yp = seq(0, by=0.1, length=20) ,
                          zp = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                          width = rep(1,20) )
                          
 # new simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.05, dz.max = 0.05)
 
 # simulate vertical macropores
 sim <- sim.rectmak(test.sim.grid$x, test.sim.grid$z, test.sim.grid$width, x.step=10)
 
 # plot slope profile with simulated structures
 plot.macros(test.sim.grid$x, test.sim.grid$z, sim$relfak)
 
 # new xsi- and eta vectors
 disc <- discretize.rect(sim, maxdists = c(5,3), plottin = TRUE)




cleanEx()
nameEx("fromArcGIS")
### * fromArcGIS

flush(stderr()); flush(stdout())

### Name: fromArcGIS
### Title: Import slope geometry from ArcGIS CATFLOW wizard
### Aliases: fromArcGIS
### Keywords: utilities

### ** Examples

### example File !!



cleanEx()
nameEx("get.realworld.coords")
### * get.realworld.coords

flush(stderr()); flush(stdout())

### Name: get.realworld.coords
### Title: Compute real-world coordinates of computational nodes.
### Aliases: get.realworld.coords
### Keywords: utilities

### ** Examples

 ## Not run: 
##D   # example slope
##D   simple.slope <- list(
##D                       xh = seq(1,11, length=20),
##D                       yh = seq(2,8, length=20),
##D                       zh = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
##D                       bh = rep(1,20),
##D                       tot.area = 12 ,
##D                       htyp = 1, 
##D                       dyy = 2,
##D                       xsi = seq(0,1,length=11),
##D                       eta = seq(0,1,length= 6),
##D                       out.file="test.geo"    
##D                       # other parameters may take default values here
##D                       )
##D 
##D    # generate CATFLOW geometry and write file 'test.geo'
##D    test.slope <- make.geometry(simple.slope, make.output=T, plotting=F)
##D   
##D    # read the produced file and plot profile line (map view)
##D    test.rw.coords <- get.realworld.coords("test.geo")   
##D     matplot(test.rw.coords$Re, test.rw.coords$Ho, xlab="easting", 
##D             ylab="northing", main="Profile line ('simple slope')")
##D 
##D    # finally, you may like to delete the produced file and objects
##D     unlink("test.geo"); rm(simple.slope, test.slope, test.rw.coords)
##D  
## End(Not run)



cleanEx()
nameEx("mac.grid")
### * mac.grid

flush(stderr()); flush(stdout())

### Name: mac.grid
### Title: Position of macropores for new discretization vectors
### Aliases: mac.grid
### Keywords: utilities

### ** Examples

 # some slope line
 test.slope <- data.frame(xp = seq(0, by=0.614, length=20) ,
                          yp = seq(0, by=0.1, length=20) ,
                          zp = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                          width = rep(1,20) )
                          
 # new simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.1, dz.max = 0.1)
 
 # simulate vertical macropores
 sim <- sim.mak(test.sim.grid$x, test.sim.grid$z, test.sim.grid$width, x.step=10)
 
 # new xsi- and eta vectors
 disc <- discretize.mak(sim, maxdists = c(5,3), plottin = TRUE)

 # macropore matrix
 new.grid <-  mac.grid(relfak = sim[[1]], xnew = test.sim.grid$x, znew = test.sim.grid$z,
                       xsi_new = disc$xsi, eta_new = disc$eta, plottin = TRUE)



cleanEx()
nameEx("make.geometry")
### * make.geometry

flush(stderr()); flush(stdout())

### Name: make.geometry
### Title: Generate geometry for CATFLOW
### Aliases: make.geometry
### Keywords: utilities

### ** Examples

  ## Not run: 
##D      simple.slope <- list(
##D                       xh = seq(1,11, length=20),
##D                       yh = seq(2,8, length=20),
##D                       zh = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
##D                       bh = rep(1,20),
##D                       tot.area = 12 ,
##D                       htyp = 1, 
##D                       dyy = 2,
##D                       xsi = seq(0,1,length=11),
##D                       eta = seq(0,1,length= 6),
##D                       out.file="test.geo"    
##D                         # other parameters may take default values here
##D                         # no output file generated when 'out.file' 
##D                         # is not in list, or when make.output=FALSE
##D                       )
##D                       
##D      test.geom <- make.geometry(simple.slope, make.output=FALSE)                 
##D   
## End(Not run)                    



cleanEx()
nameEx("make.simgrid")
### * make.simgrid

flush(stderr()); flush(stdout())

### Name: make.simgrid
### Title: Make a fine grid for macropore simulation
### Aliases: make.simgrid
### Keywords: utilities

### ** Examples

 # some slope line
 test.slope <- data.frame( xh = seq(1,11, length=20),
                           yh = seq(2,8, length=20),
                           zh = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                           bh = rep(1,20) )
                          
 # simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.1, dz.max = 0.1)
 



cleanEx()
nameEx("plot.catf.bal")
### * plot.catf.bal

flush(stderr()); flush(stdout())

### Name: plot.catf.bal
### Title: Plot a CATFLOW simulation balance
### Aliases: plot.catf.bal
### Keywords: utilities

### ** Examples

### TO DO ###
## problem: file to read ##
## Not run: 
##D bla <- plot.catf.bal("F:/CATF/Projekte/Code_test/min.surf.run/out/bilanz.csv") 
## End(Not run)



cleanEx()
nameEx("plot.catf.grid")
### * plot.catf.grid

flush(stderr()); flush(stdout())

### Name: plot.catf.grid
### Title: Plots a CATFLOW simulation grid
### Aliases: plot.catf.grid
### Keywords: utilities

### ** Examples

 ## Not run: 
##D  # ... a simple slope
##D  simple.slope <- list(xh = seq(1,11, length=20),
##D                       yh = seq(2,8, length=20),
##D                       zh = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
##D                       bh = rep(1,20),
##D                       tot.area = 12 ,
##D                       htyp = 1, 
##D                       dyy = 2,
##D                       xsi = seq(0,1,length=11),
##D                       eta = seq(0,1,length= 6)
##D                       ) # other parameters may take default values here
##D                       
##D  # generate CATFLOW geometry                     
##D  test.geom <- make.geometry(simple.slope, make.output=FALSE, plotting=FALSE)            
##D 
##D  # plot CATFLOW geometry and color-code the nodes according to elevation
##D  plot.catf.grid(test.geom$sko, test.geom$hko, val=test.geom$hko, plotpoints=TRUE)
##D  
## End(Not run)



cleanEx()
nameEx("plot.catf.movie")
### * plot.catf.movie

flush(stderr()); flush(stdout())

### Name: plot.catf.movie
### Title: Plot CATFLOW results sequently
### Aliases: plot.catf.movie
### Keywords: utilities

### ** Examples

  ## TODO
  # PROBLEM: result file needed
  ## Not run: 
##D  #geometry 
##D   geof <- read.geofile(file.path(.libPaths(), "Catflow", "Catflow-TEST", "in", "test.geo") )
##D  #relative saturation 
##D   res <- read.catf.resultmat(file.path(.libPaths(), "Catflow", "Catflow-TEST", "out", "relsat.out") )   
##D  
##D  # plot on screen  
##D   plot.catf.movie(res, geof,  sel =12:22,  
##D   colorsForCuts = c("pink",brewer.pal(8,"Blues")))   
##D   
##D  # plot to file  
##D   plot.catf.movie(res, geof, 
##D   SCREENPLOT = F, filename = "test.pdf",
##D   outputPath = ".",                                # current dir
##D   colorsForCuts = c("pink",brewer.pal(8,"Blues")))   
##D   
##D  # open pdf
##D  shell.exec( paste(getwd(), "Catflowtest.pdf", sep="/") )
##D  
##D  ## delete the produced file
##D   file.remove("Catflowtest.pdf")
##D   
## End(Not run)



cleanEx()
nameEx("plot.macros")
### * plot.macros

flush(stderr()); flush(stdout())

### Name: plot.macros
### Title: Plot simulated macropores
### Aliases: plot.macros
### Keywords: utilities

### ** Examples

 # some slope line
 test.slope <- data.frame(xp = seq(0, by=0.614, length=20) ,
                          yp = seq(0, by=0.1, length=20) ,
                          zp = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                          width = rep(1,20) )
                          
 # new simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.1, dz.max = 0.1)
 
 # simulate vertical macropores
 sim <- sim.mak(test.sim.grid$x, test.sim.grid$z, test.sim.grid$width, x.step=10)
 ## Not run: 
##D  # plot slope profile with simulated structures
##D  plot.macros(test.sim.grid$x, test.sim.grid$z, sim$relfak)
##D  
## End(Not run)



cleanEx()
nameEx("read.catf.balance")
### * read.catf.balance

flush(stderr()); flush(stdout())

### Name: read.catf.balance
### Title: Read CATFLOW balance file
### Aliases: read.catf.balance
### Keywords: utilities

### ** Examples


 ## Not run: 
##D         example.balance <- read.catf.balance(file.path(.libPaths(), "Catflow", "Catflow-TEST", "out", "bilanz.csv"),
##D                                   plottin = T,  differences=T, cex=0.7) 
##D  
## End(Not run)



cleanEx()
nameEx("read.catf.resultmat")
### * read.catf.resultmat

flush(stderr()); flush(stdout())

### Name: read.catf.resultmat
### Title: Read a single result file in matrix form
### Aliases: read.catf.resultmat
### Keywords: utilities

### ** Examples

  ## TODO
  # PROBLEM: result file needed



cleanEx()
nameEx("read.catf.results")
### * read.catf.results

flush(stderr()); flush(stdout())

### Name: read.catf.results
### Title: Read all results of a CATFLOW simulation
### Aliases: read.catf.results
### Keywords: utilities

### ** Examples

## TO DO 
## PROBLEM: result files



cleanEx()
nameEx("read.channelflow.out")
### * read.channelflow.out

flush(stderr()); flush(stdout())

### Name: read.channelflow.out
### Title: Read CATFLOW channel flow output
### Aliases: read.channelflow.out
### Keywords: utilities

### ** Examples


#### FILE does not exist yet
## Not run: 
##D         example.channelflow <- read.channelflow.out(file.path(.libPaths(), "Catflow", "Catflow-TEST", "out", "gang.out") ) 
##D  
## End(Not run)



cleanEx()
nameEx("read.climate")
### * read.climate

flush(stderr()); flush(stdout())

### Name: read.climate
### Title: Read a CATFLOW climate record
### Aliases: read.climate
### Keywords: utilities

### ** Examples

 ## Not run: 
##D  # some climate record
##D   climadat <- data.frame(
##D               "hours" = seq(0,48, by=0.5),
##D               "GlobRad" =  ifelse(0 + 800 * sin((seq(0,48, by=0.5) - 8)*pi/12) > 0,
##D                                   0 + 800 * sin((seq(0,48, by=0.5) - 8)*pi/12),  0),
##D               "NetRad" = NA ,
##D               "Temp" = 4 +  sin((seq(0,48, by=0.5) - 12)*pi/12)  ,
##D               "RelHum" = 70 + 10* sin((seq(0,48, by=0.5))*pi/12) ,
##D               "vWind"  =  rlnorm(97, 0,1) ,
##D               "dirWind" = runif(97, 0, 359) 
##D               )
##D                       
##D  # write a climate file for CATFLOW
##D  write.climate(climadat, "TEST.clima.dat", start.time= "01.01.2004 00:00:00" )
##D                 
##D  # ... and read it again
##D  clima <- read.climate("TEST.clima.dat")
##D 
##D  ## maybe you like to delete the produced file
##D    unlink("TEST.clima.dat")
##D  
## End(Not run) 



cleanEx()
nameEx("read.evapo.out")
### * read.evapo.out

flush(stderr()); flush(stdout())

### Name: read.evapo.out
### Title: Read CATFLOW evapo-transpiration output
### Aliases: read.evapo.out
### Keywords: utilities

### ** Examples

### TO DO ###
## problem: file to read ##



cleanEx()
nameEx("read.facmat")
### * read.facmat

flush(stderr()); flush(stdout())

### Name: read.facmat
### Title: Read matrix file for CATFLOW
### Aliases: read.facmat
### Keywords: utilities

### ** Examples

  ## Not run: 
##D   # Example discretization: eta (vertical), xsi (lateral)
##D    eta <- 1:6
##D     xsi <- 1:11
##D    
##D   # Multipliers for some exponential decrease of saturated hydraulic conductivity with depth
##D    exp.dec <- exp(seq(0, -3, length=length(eta) ))
##D     exp.dec <- rep(round(exp.dec,3), length(xsi) ) 
##D   
##D   # Produce some ks multiplier file
##D   write.facmat(output.file="ksmult.dat", fac=exp.dec)
##D      file.show("ksmult.dat")
##D   
##D   read.facmat("ksmult.dat")
##D   
##D   ## maybe you like to delete the produced file
##D      unlink("ksmult.dat")  
##D   
## End(Not run)



cleanEx()
nameEx("read.geofile")
### * read.geofile

flush(stderr()); flush(stdout())

### Name: read.geofile
### Title: Reads a CATFLOW geometry file
### Aliases: read.geofile
### Keywords: utilities

### ** Examples

  ## Not run: 
##D     # example slope
##D     simple.slope <- list(
##D                         xh = seq(1,11, length=20),
##D                         yh = seq(2,8, length=20),
##D                         zh = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
##D                         bh = rep(1,20),
##D                         tot.area = 12 ,
##D                         htyp = 1, 
##D                         dyy = 2,
##D                         xsi = seq(0,1,length=11),
##D                         eta = seq(0,1,length= 6),
##D                         out.file="test.geo"    
##D                           # other parameters may take default values here
##D                           )
##D   
##D     # generate CATFLOW geometry and write file 'test.geo'                   
##D     test.slope <- make.geometry(simple.slope, make.output=T, plotting=F)
##D     
##D     # read the produced file and plot computational nodes
##D     test.geom <- read.geofile("test.geo")
##D       with(test.geom, plot(sko, hko, t="p"))
##D    
##D     ## finally, delete the produced file and objects
##D     unlink("test.geo"); rm(simple.slope, test.slope, test.geom)
##D   
## End(Not run)                



cleanEx()
nameEx("read.precip")
### * read.precip

flush(stderr()); flush(stdout())

### Name: read.precip
### Title: Read a CATFLOW precipitation record
### Aliases: read.precip
### Keywords: utilities

### ** Examples

 ## Not run: 
##D  # some rainfall data
##D   raindat <- data.frame("hours" = seq(0,48, by=0.5),
##D                         "precip" = c(rep(0,30), 1, rep(3,4), rep(2,3), 
##D                                       rep(0,25), rep(1,4), rep(0,30)) ) 
##D                       
##D  # write a CATFLOW rainfall file
##D  write.precip(raindat, "TEST.rain.dat", start.time= "01.01.2004 00:00:00" )
##D   file.show("TEST.rain.dat")
##D  
##D  # ... and read it again
##D  rain <- read.precip(file.nam = "TEST.rain.dat", plotting=T)
##D  
##D  ## maybe you like to delete the produced file
##D  #  unlink("TEST.rain.dat")
##D  
## End(Not run)



cleanEx()
nameEx("read.soil.mat")
### * read.soil.mat

flush(stderr()); flush(stdout())

### Name: read.soil.mat
### Title: Read soil ID assignment
### Aliases: read.soil.mat
### Keywords: utilities

### ** Examples

### TO DO ###
## problem: file to read ##
 ## Not run: 
##D  bla <- read.soil.mat("F:/CATF/Projekte/HalfProf/boden.dat") 
##D  
## End(Not run)



cleanEx()
nameEx("read.surfrun.out")
### * read.surfrun.out

flush(stderr()); flush(stdout())

### Name: read.surfrun.out
### Title: Read CATFLOW surface runoff output
### Aliases: read.surfrun.out
### Keywords: utilities

### ** Examples

### TO DO ###
## problem: file to read ##



cleanEx()
nameEx("sim.mak")
### * sim.mak

flush(stderr()); flush(stdout())

### Name: sim.mak
### Title: Simulate vertical macropores
### Aliases: sim.mak
### Keywords: utilities

### ** Examples

 # some slope line
 test.slope <- data.frame(xp = seq(0, by=0.614, length=20) ,
                          yp = seq(0, by=0.1, length=20) ,
                          zp = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                          width = rep(1,20) )
                          
 # new simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.1, dz.max = 0.1)
 
 # simulate vertical macropores
 sim <- sim.mak(test.sim.grid$x, test.sim.grid$z, test.sim.grid$width, x.step=10)
 ## Not run: 
##D  # plot slope profile with simulated structures
##D  plot.macros(test.sim.grid$x, test.sim.grid$z, sim$relfak)
##D  
## End(Not run)



cleanEx()
nameEx("sim.pipe")
### * sim.pipe

flush(stderr()); flush(stdout())

### Name: sim.pipe
### Title: Simulate horizontal macropores
### Aliases: sim.pipe
### Keywords: utilities

### ** Examples

 # some slope line
 test.slope <- data.frame(xp = seq(0, by=0.614, length=20) ,
                          yp = seq(0, by=0.1, length=20) ,
                          zp = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                          width = rep(1,20) )
                          
 # new simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.1, dz.max = 0.1)
 
 # simulate pipe
 sim <- sim.pipe(test.sim.grid$x, test.sim.grid$z, test.sim.grid$width, 
                 start.depth = 1)
 
 ## Not run: 
##D  # plot slope profile with simulated structure
##D  plot.macros(test.sim.grid$x, test.sim.grid$z, sim$relfak , pc = 1  )  
##D  
## End(Not run)



cleanEx()
nameEx("sim.rectmak")
### * sim.rectmak

flush(stderr()); flush(stdout())

### Name: sim.rectmak
### Title: Simulate a grid of macropores
### Aliases: sim.rectmak
### Keywords: utilities

### ** Examples

 # some slope line
 test.slope <- data.frame(xp = seq(0, by=0.614, length=20) ,
                          yp = seq(0, by=0.1, length=20) ,
                          zp = approx(c(8,5),n=20)$y + sin((0:19)/2)/5 ,
                          width = rep(1,20) )
                          
 # new simulation grid with 2 m depth and 0.1 m resolution
 test.sim.grid <- make.simgrid(test.slope, prof.depth = 2, dx.max=0.1, dz.max = 0.1)
 
 # simulate connected macropores
 sim <- sim.rectmak(test.sim.grid$x, test.sim.grid$z, test.sim.grid$width, x.step=10)
 
 ## Not run: 
##D  # plot slope profile with simulated structures
##D  plot.macros(test.sim.grid$x, test.sim.grid$z, sim$relfak)
##D  
## End(Not run)



cleanEx()
nameEx("use.psi.fin")
### * use.psi.fin

flush(stderr()); flush(stdout())

### Name: use.psi.fin
### Title: Read final matric potential file and write new ini-files
### Aliases: use.psi.fin
### Keywords: utilities

### ** Examples

  ### jw example file



cleanEx()
nameEx("write.CATFLOW.IN")
### * write.CATFLOW.IN

flush(stderr()); flush(stdout())

### Name: write.CATFLOW.IN
### Title: Write a project control file for CATFLOW
### Aliases: write.CATFLOW.IN
### Keywords: utilities

### ** Examples

  ## Not run: 
##D   control.files <- c("test.1strun.in","test.2ndrun.in")
##D   
##D   write.CATFLOW.IN(control.files)
##D   
##D   file.show("CATFLOW.IN")
##D   
##D   ## maybe you like to delete the produced file and directory  
##D   file.remove("CATFLOW.IN")
##D   
## End(Not run)



cleanEx()
nameEx("write.climate")
### * write.climate

flush(stderr()); flush(stdout())

### Name: write.climate
### Title: Write a climate record for CATFLOW
### Aliases: write.climate
### Keywords: utilities

### ** Examples

 ## Not run: 
##D  # some climate record
##D   climadat <- data.frame(
##D               "hours" = seq(0,48, by=0.5),
##D               "GlobRad" =  ifelse(0 + 800 * sin((seq(0,48, by=0.5) - 8)*pi/12) > 0,
##D                                   0 + 800 * sin((seq(0,48, by=0.5) - 8)*pi/12),  0),
##D               "NetRad" = NA ,
##D               "Temp" = 4 +  sin((seq(0,48, by=0.5) - 12)*pi/12)  ,
##D               "RelHum" = 70 + 10* sin((seq(0,48, by=0.5))*pi/12) ,
##D               "vWind"  =  rlnorm(97, 0,1) ,
##D               "dirWind" = runif(97, 0, 359) 
##D               )
##D                                                 
##D  write.climate(climadat, "TEST.clima.dat", start.time= "01.01.2004 00:00:00" )
##D                 
##D  file.show("TEST.clima.dat")
##D                 
##D  ## maybe you like to delete the produced file
##D  unlink("TEST.clima.dat")
##D  
## End(Not run)       



cleanEx()
nameEx("write.control")
### * write.control

flush(stderr()); flush(stdout())

### Name: write.control
### Title: Write control file for CATFLOW
### Aliases: write.control
### Keywords: utilities

### ** Examples

  ## Not run: 
##D     write.control("TEST_CATFLOW.IN", output.path="TEST_CATFLOW_OUT")
##D   
##D     file.show( "TEST_CATFLOW.IN" )
##D     
##D      
##D     ## maybe you like to delete the produced file and directory  
##D       unlink("TEST_CATFLOW.IN")
##D       unlink("TEST_CATFLOW_OUT", recursive=T)
##D   
## End(Not run)



cleanEx()
nameEx("write.facmat")
### * write.facmat

flush(stderr()); flush(stdout())

### Name: write.facmat
### Title: Write matrix file for CATFLOW
### Aliases: write.facmat
### Keywords: utilities

### ** Examples

  ## Not run: 
##D   # Example discretization: eta (vertical), xsi (lateral)
##D    eta <- 1:6
##D     xsi <- 1:11
##D    
##D   # Dummy multipliers for scaling saturated hydraulic conductivity: all one
##D   write.facmat(output.file="ksmult.dat")
##D     file.show("ksmult.dat")
##D       
##D   # Initial conditions: Uniform Psi (soilhyd.ini)
##D   write.facmat(output.file="soilhyd.ini",
##D                headr=paste("PSI   ", 0,  1, length(eta), length(xsi), 1),
##D                fac = 0.8)
##D     file.show("soilhyd.ini")
##D     
##D   # Multipliers for some exponential decrease of saturated hydraulic conductivity with depth
##D    exp.dec <- exp(seq(0, -3, length=length(eta) ))
##D     exp.dec <- rep(round(exp.dec,3), length(xsi) ) 
##D   
##D   write.facmat(output.file="ksmult.dat", fac=exp.dec)
##D      file.show("ksmult.dat")
##D    
##D   ## maybe you like to delete the produced files
##D   unlink(c("ksmult.dat", "soilhyd.ini"))  
##D   
## End(Not run)



cleanEx()
nameEx("write.precip")
### * write.precip

flush(stderr()); flush(stdout())

### Name: write.precip
### Title: Write a precipitation record for CATFLOW
### Aliases: write.precip
### Keywords: utilities

### ** Examples

 ## Not run: 
##D  # some rainfall record
##D   raindat <- data.frame("hours" = seq(0,48, by=0.5),
##D                         "precip" = c(rep(0,30), 1, rep(3,4), rep(2,3), 
##D                                       rep(0,25), rep(1,4), rep(0,30)) ) 
##D                       
##D  write.precip(raindat, "TEST.rain.dat", start.time= "01.01.2004 00:00:00" )
##D  
##D  file.show("TEST.rain.dat")
##D  
##D  ## maybe you like to delete the produced file
##D  unlink("TEST.rain.dat")
##D  
## End(Not run)       



cleanEx()
nameEx("write.printout")
### * write.printout

flush(stderr()); flush(stdout())

### Name: write.printout
### Title: Write printout times file for CATFLOW
### Aliases: write.printout
### Keywords: utilities

### ** Examples

  ## Not run: 
##D   write.printout(output.file = "./in/printout.prt", 
##D                  start.time = "01.01.2004 00:00:00", 
##D                  end.time = "03.01.2004 00:00:00", 
##D                  intervall = 0.5, time.unit = "h",
##D                  flag = 1)
##D                   
##D   file.show( "printout.prt" )
##D 
##D   ## maybe you like to delete the produced file and directory  
##D   file.remove("printout.prt")
##D   
## End(Not run)



cleanEx()
nameEx("write.surface.pob")
### * write.surface.pob

flush(stderr()); flush(stdout())

### Name: write.surface.pob
### Title: Write surface attribute file for CATFLOW
### Aliases: write.surface.pob
### Keywords: utilities

### ** Examples

 ## Not run: 
##D   write.surface.pob(output.file="surface.pob", 
##D                      xs=seq(0,1,length=11), 
##D                       lu=33,
##D                        windid= rbind(matrix(rep(c(2,3,4,5), 5), nrow=5, byrow=T),
##D                                      matrix(rep(c(1,2,3,4),6), nrow=6, byrow=T))
##D                       )
##D   
##D   file.show("surface.pob")
##D   
##D   ## maybe you like to delete the produced file
##D    file.remove("surface.pob")
##D   
## End(Not run)



cleanEx()
nameEx("zoom")
### * zoom

flush(stderr()); flush(stdout())

### Name: zoom
### Title: Zooming for plots
### Aliases: zoom
### Keywords: iplot

### ** Examples

  ## Not run: 
##D   x <- 1:20
##D   y <- runif(20)
##D   
##D   plotfun <- function(...) plot(x,y, t="b",...)
##D   
##D   zoom(fun=plotfun, col=2)
##D   
## End(Not run)



### * <FOOTER>
###
cat("Time elapsed: ", proc.time() - get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
