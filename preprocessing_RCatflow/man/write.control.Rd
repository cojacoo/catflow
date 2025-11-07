\name{write.control}
\alias{write.control}

\title{
Write control file for CATFLOW
}
\description{
Writes a project control file for a CATFLOW simulation.
}
\usage{
write.control(output.file, 
project.path = NULL ,
start.date = "01.01.2004 01:00:00.00", 
  end.date = "31.12.2004 23:00:00.00", 
    offset = 0, 
      method = "pic", 
        dtbach = 1200, 
          qtol = 1e-06, 
            dt_max = 1200, 
              dt_min = 0.001, 
                dt_ini = 30, 
                  d_Th_opt = 0.003, 
                    d_Phi_opt = 0.001, 
                      n_gr = 3, 
                        it_max = 10, 
                          piceps = 5e-04, 
                            cgeps = 5e-07, 
                              rlongi = 15, 
                                longi = 9.746, 
                                  lati = 47.35, 
                                    istact = 0,  
                                      Seed = -80,  
                                        interact = "noiact",  
print.flag = "0 0 1  0 0 0  0 0 0  1 0 0 0 0 0 0 0 0",  
  output.path = "out",  
    outfile.list = list( log.file = "log.out", 
                         soil.prop.tab = "vg_tab.out", 
                         balance.file = "bilanz.csv", 
                         theta.file = "theta.out", 
                         psi.file = "psi.out", 
                         psi.fin = "psi.fin", 
                         fl_xsi.file = "fl_xsi.out", 
                         fl_eta.file = "fl_eta.out", 
                         sink.file = "senken.out", 
                         surfflow.file = "qoben.out", 
                         evapo.file = "evapo.out", 
                         channel.file = "gang.out", 
                         vel.eta.file = "ve.out", 
                         vel.xsi.file = "vx.out", 
                         conc.file = "c.out", 
                         hko.file = "hko.out", 
                         sko.file = "sko.out", 
                         relsat.file = "relsat.out"), 
input.path = "in", 
  global.in.list = list( soildef.file = "soils.def", 
                         timeser.file = "timeser.def", 
                         lu.file = "landuse/lu_file.def", 
                         winddir.file = "winddir.def"), 
    slope.in.list = list( slope1 = list( geo.file = "hang1_sim1.geo", 
                                         soil.file = "soilnodes.bod", 
                                         ks.fac = "ksmult.dat", 
                                         ths.fac = "thsmult.dat", 
                                         macro.file = "profil.mak", 
                                         cv.file = "cont_vol.cv", 
                                         ini.file = "soil_hyd.ini",
                                         print.file = "printout.prt", 
                                         surf.file = "surface.pob", 
                                         bc.file = "boundary.rb")) 
 )
}

\arguments{
  \item{output.file}{
Name of control file to produce
}
  \item{project.path}{
Name of subdirectory where to produce the control file and the iput/output directories (optional)
}
  \item{start.date}{
Start date for the simulation ("\%d.\%m.\%Y \%H:\%M:\%S.00")
}
  \item{end.date}{
End date for the simulation ("\%d.\%m.\%Y \%H:\%M:\%S.00")
}
  \item{offset}{
Time offset from start date [s]
}
  \item{method}{
Computational method
}
  \item{dtbach}{
Maximum timestep for drainage network [s] (or overall computation, if lower than 'dt.max')
}
  \item{qtol}{
Threshold for initiating of drainage network computation [m^3/s]
}
  \item{dt_max}{
Maximum timestep in [s] 
}
  \item{dt_min}{
Minimum timestep in [s] 
}
  \item{dt_ini}{
Initial timestep in [s] 
}
  \item{d_Th_opt}{
Timestep control parameter: optimal change in water content [-] 
}
  \item{d_Phi_opt}{
Timestep control parameter: optimal change in hydraulic head [-] 
}
  \item{n_gr}{
Desired number of Picard iteration steps
}
  \item{it_max}{
Maximum number of Picard iteration steps
}
  \item{piceps}{
Desired convergence tolerance Picard method [-]
}
  \item{cgeps}{
Desired convergence tolerance CG method [m]
}
  \item{rlongi}{
Longitude of time zone [decimal degrees] (default CET = 15)
}
  \item{longi}{
Longitude of catchment [decimal degrees]
}
  \item{lati}{
Latitude of catchment [decimal degrees] 
}
  \item{istact}{
Number of different solute types (0-3)
}
  \item{Seed}{
Seed for portable random number generator 
}
  \item{interact}{
Switch for subsurface-channel interaction: yes = "simact", or no = "noiact" (default)
}
  \item{print.flag}{
Character string with switches that control writing of output to each output file: 
every timestep = 1, or at specified timesteps (printout.times) = 0 
}
  \item{output.path}{
Directory name for output files, will be created if not existing (default "out")
}
  \item{outfile.list}{
List with output file names:
   \itemize{
    \item log.file: log of simulation 
    \item soil.prop.tab:  tables of soil-hydraulic functions 
    \item balance.file: water balance 
    \item theta.file: soil moisture 
    \item psi.file: suction head 
    \item psi.fin: suction head at final state
    \item fl_xsi.file: flux in xsi-direction (lateral) 
    \item fl_eta.file: flux in eta-direction (horizontal) 
    \item sink.file: sinks
    \item surfflow.file: surface runoff
    \item evapo.file: evapo-Transpiration
    \item channel.file: drainage network hydrographs 
    \item vel.eta.file: generalised pore-water velocity (eta-direction) 
    \item vel.xsi.file: generalised pore-water velocity (xsi-direction) 
    \item conc.file: residual solute concentration in the soil 
    \item hko.file: vertical coordinate of the computational grid
    \item sko.file: horizontal coordinate of the computational grid
    \item relsat.file: relative saturation }}
    
\item{input.path}{
Directory name for input files (default "in")
}
  \item{global.in.list}{
List with global input file names:

 \itemize{
  \item soildef.file: specification of soil types
  \item timeser.file: specification of time series 
  \item lu.file: assigning land-use ID to land-use parameter file
  \item winddir.file: sectors of wind direction	
  }
}
  \item{slope.in.list}{
List that contains a list of slope-specific input file names for every hillslope. 

Default is a single slope: list(slope1), where 

 \itemize{
  \item  slope1: list with input file names for the first slope
    \itemize{
     \item geo.file: hillslope geometry and -discretisation
     \item soil.file: assignment of soil types
     \item ks.fac: matrix of multipliers for hydraulic conductivity
     \item ths.fac: matrix of multipliers for porosity
     \item macro.file: assignment of macropore parameters
     \item cv.file: specification of control volumes
     \item ini.file: initial conditions for soil water dynamics
     \item print.file: specification of printout times
     \item surf.file: assignment of surface attributes  
     \item bc.file: assignment of boundary conditions 
    } 
  }  
   
}
}
\details{
The function 'write.control' is used for its side-effect: writing a project control file in CATFLOW-specific format.
Please note that the sequence of variables and filenames in the project control files is fixed.
 
Some default values exist for the arguments except for 'output.file', see 'usage' section.
}
\value{
No value is returned. A short message indicates which files and directories have been produced.
}
\references{
Maurer, T. and E. Zehe (2007) \emph{CATFLOW User Guide and Program Documentation (Version Catstat)}

}
\author{
Jan \enc{Wienhöfer}{Wienhoefer}
}


\examples{
  \dontrun{
    write.control("TEST_CATFLOW.IN", output.path="TEST_CATFLOW_OUT")
  
    file.show( "TEST_CATFLOW.IN" )
    
     
    ## maybe you like to delete the produced file and directory  
      unlink("TEST_CATFLOW.IN")
      unlink("TEST_CATFLOW_OUT", recursive=T)
  }
}


\keyword{ utilities }
