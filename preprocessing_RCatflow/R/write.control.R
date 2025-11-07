write.control <-
function(output.file,
          project.path = NULL ,
                    start.date = "01.01.2004 01:00:00.00",  
                    end.date =   "31.12.2004 23:00:00.00",  
                    offset =      0.0            ,#offset 
                    method =      "pic"          ,# computation method 
                    dtbach =      1200.          ,# max. time step drainage network
                    qtol   =      1.e-6          ,# threshold drainage network [cbm/s]   
                    dt_max =      1200.          ,# [s] max. time step 
                    dt_min =      0.001          ,# [s] min. time step          
                    dt_ini =      30.00          ,# [s] initial time step
                    d_Th_opt =    0.003          ,# optimum change of soil moisture  
                    d_Phi_opt =   0.001          ,# optimum change of suction head
                    n_gr      =   3              ,# threshold for reducing time step 
                    it_max   =    10             ,# max. number of Picard-iterations
                    piceps   =    5.e-4          ,# convergence criterium Picard iter.
                    cgeps    =    5.e-7          ,# convergence criterium cg method
                    rlongi   =    15.            ,# reference longitude for time (CET)
                    longi    =    9.746          ,# longitude of catchment
                    lati     =    47.35          ,# latitude of catchment
                    istact   =    0              ,# number of solutes accounted for 
                    Seed     =    -80            ,# Seed for random number generator
                    interact =  "noiact"         ,# simulation of interaction
                                                  # subsurface/ channel water 
                                                  # (Y=simact, N=noiact)
                    print.flag = "0 0 1  0 0 0  0 0 0  1 0 0 0 0 0 0 0 0",
                   # print output to file: (1) every time step; (0) printout times  
                # Output files                                                  
                    output.path=  "out"          ,# path for output
                    outfile.list = list(             
                      log.file =    "log.out"      ,# Log-file        
                      soil.prop.tab = "vg_tab.out" ,# tables of soil hydraulic properties
                      balance.file = "bilanz.csv"  ,# water balance file 
                      theta.file = "theta.out"     ,# soil water content  
                      psi.file    = "psi.out"      ,# suction head 
                      psi.fin     = "psi.fin"      ,# final state (suction head)
                      fl_xsi.file = "fl_xsi.out"   ,# water flux in xsi-direction (lateral)
                      fl_eta.file = "fl_eta.out"   ,# water flux in eta-dir. (vertical) 
                      sink.file   = "senken.out"   ,# sinks [qm/s] 
                      surfflow.file = "qoben.out"  ,# Surface runoff[cbm/s]
                      evapo.file =  "evapo.out"    ,# Evapotranspiration  
                      channel.file = "gang.out"    ,# channel flow  
                      vel.eta.file = "ve.out"      ,# pore water velocity in eta-direction 
                      vel.xsi.file = "vx.out"      ,# pore water velocity in xsi-direction
                      conc.file = "c.out"          ,# residual solute concentrations 
                      hko.file = "hko.out"         ,# vertical coordinates (grid nodes)
                      sko.file = "sko.out"         ,# lateral coordinates (grid nodes)
                      relsat.file = "relsat.out"    # relative Saturation    
                     ),
                    input.path= "in"             ,# path for input         
                # Input files I    
                    global.in.list = list(  
                      soildef.file= "soils.def"    ,# soil type definitions
                      timeser.file = "timeser.def" ,# time series definitions
                      lu.file="landuse/lu_file.def",# landuse parameterization
                      winddir.file = "winddir.def"  # wind direction id's
                     ),
                # Input files II: list of same length as number of hillslopes
                    slope.in.list = list(
                      slope1 = list(       
                        geo.file= "hang1_sim1.geo" ,# slope geometry     
                        soil.file= "soilnodes.bod" ,# soil type assignment
                        ks.fac = "ksmult.dat"      ,# multipliers for Ks
                        ths.fac = "thsmult.dat"    ,# multipliers for theta_s 
                        macro.file = "profil.mak"  ,# macropore multipliers
                        cv.file = "cont_vol.cv"    ,# control volumes
                        ini.file = "soil_hyd.ini"  ,# initial conditions (theta/psi)
                        print.file = "printout.prt",# printout times
                        surf.file = "surface.pob"  ,# surface attributes
                        bc.file = "boundary.rb"     # boundary conditions
                       )
                     )
                
                ) 
{ # start of function body

if(!is.null(project.path)) output.file <- file.path(project.path, output.file) 
   
fid <- file(output.file, open="w")
   
# write header (according to width requirements)
write(file=fid,paste(start.date, "          % start time") ) 
  write(file=fid,paste(end.date, "          % end time    "))
    write(file=fid,  paste(offset, "                               % offset  "))
      write(file=fid,  paste(method, 
          "                             % computation method "))
        write(file=fid,  paste(dtbach, 
        "                            % dtbach [s] maximum time step for drainage network "))
          write(file=fid,  paste(qtol, "                          ",
          "% qtol  threshold for starting drainage network computation [cbm/s]"))
            write(file=fid,  paste(dt_max, 
            "                            % dt_max [s] max. time step")) 
             write(file=fid,  paste(dt_min, 
             "                           % dt_min [s] min. time step   "))
              write(file=fid,  paste(dt_ini, 
              "                              % dt [s] initial time step"))
               write(file=fid,  paste(d_Th_opt, 
               "                           % d_Th_opt [-] optimum change of soil moisture"))
                write(file=fid,  paste(d_Phi_opt, 
                "                           % d_Phi_opt [-] optimum change of suction head"))
                 write(file=fid,  paste(n_gr, "                              ",
                 "% n_gr (3) threshold for reducing time step", 
                 "but carrying on the actual iteration" ))
                  write(file=fid,  paste(it_max, 
                  "                              % it_max (7) max. number of Picard-iterations"))
                   write(file=fid,  paste(piceps , 
                   "% piceps [-] (1.e-3) convergence criterium for Picard iteration ",
                    sep="                            "))
                    write(file=fid,  paste(cgeps, 
                    "% cgeps  [m] (5.e-6) convergence criterium for cg method. ", 
                      sep="                            ") )
                     write(file=fid,  paste(rlongi, 
                     "                              % ref. longitude for computation of time "))
                      write(file=fid,  paste(longi, 
                      "                           % longi  reference longitude") )
                       write(file=fid,  paste(lati, 
                       "                           % lati   reference latitude ") )
                        write(file=fid,  paste(istact, 
                        "                               % istact number of solutes"))
                         write(file=fid,  paste(Seed, 
                         "                             % Seed for random number generator" ))
                          write(file=fid,  paste(interact, 
                          "                         ", "% switch for simulation",
                          "of interaction between subsurface and channel water",
                          "(simact -> yes, noiact -> no)"))
          
## output files          
write(file=fid,  length(outfile.list))     # no.out.files

if( sum( nchar(strsplit(print.flag, split="[[:space:]]")[[1]])) != length(outfile.list)){
      stop("Output file list and length of printing flag do not match!") 
} else write(file=fid,  print.flag)
          
output <- lapply(outfile.list, function(x) write(paste(output.path,x, sep="/"), file=fid) )
          
### input files
 # No. of files
 # global input files
 write(file=fid,  length(global.in.list))
  input.g <- lapply(global.in.list, function(x) write(paste(input.path, x, sep="/"), file=fid) )
                          
 # slope-specific files
 # No. of hillslopes
 write(file=fid, length( slope.in.list))         
  input.s <- rapply(slope.in.list, function(x) { 
                    write(file=fid, paste(input.path, x, sep="/")) 
                  })
close(fid)

if(!is.null(project.path)) output.path <- file.path(project.path, output.path) 

     
#### make output directory
if(!file_test("-d", output.path)) { 
            dir.create(output.path, recursive=TRUE)
            print(paste("Generated control file '", output.file, 
            "', and the directory for output files: '", output.path, "'.", sep="") )
} else print(paste("Generated control file '", output.file, "'.",sep="") )

return(invisible())
}

