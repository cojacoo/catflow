fromArcGIS <-
function(filename)
{  
  erg <- list()

  dat <- readLines(filename)
   
  #Dataformat from ArcGis preprocessing:
  #First line: numberOfSlopes (n), maxNumberOfSlopePoints, x_bez, y_bez, z_bez, number of Xsi, number of Eta
    firstLine <- as.numeric(na.exclude(as.numeric(strsplit(dat[1]," ")[[1]])))
      slopeCount = firstLine[1]
      slopePointCount = firstLine[2]
      re_bez = firstLine[3]
      ho_bez = firstLine[4]
      z_bez = firstLine[5]
      xsiCount = firstLine[6]
      etaCount = firstLine[7]
  
  if(slopeCount == 1)
  {
  #line 2 SlopeID
    numh =  as.numeric(dat[2])
  # line 3 SlopeType (Constant Thickness or 'Cake shape')
    htyp = as.numeric(dat[3])
  #line 4 Area
    Area <- as.numeric(dat[4])
  # line 5 Number of points
    noPoints <- as.numeric(dat[5])
  # line 6 Thickness of slope
    Depth <- as.numeric(dat[6])
  # line 7 Eta Values
    eta <- as.numeric(na.exclude(as.numeric(strsplit(dat[7]," ")[[1]])))
  # line 8 Xsi Values
    xsi <- as.numeric(na.exclude(as.numeric(strsplit(dat[8]," ")[[1]])))
  # line 9...8+n x of slopepoints
    Rew <- strsplit(dat[9:(8+slopeCount)]," ")
    Rew <- lapply(Rew, function(x){ x <- as.numeric(na.exclude(as.numeric(x)))})
  # line 9+n...8+2n y of slopepoints
    How <- strsplit(dat[(9+slopeCount):(8+2*slopeCount)]," ")
    How <- lapply(How, function(x){ x <- as.numeric(na.exclude(as.numeric(x)))})
  # line 9+2n...8+3n z of slopepoints
    Elev <- strsplit(dat[(9+2*slopeCount):(8+3*slopeCount)]," ")
    Elev <- lapply(Elev, function(x){ x <- as.numeric(na.exclude(as.numeric(x)))})
  # line 9+3n...8+4n width of slopepoints
    Width <- strsplit(dat[(9+3*slopeCount):(8+4*slopeCount)]," ")
    Width <- lapply(Width, function(x){ x <- as.numeric(na.exclude(as.numeric(x)))})

  ## aggregate to slope list
  erg <- list(  "xh" = Rew[[1]], 
                "yh" = How[[1]],
                "zh" = Elev[[1]], 
                "tot.area" = Area,
                "bh" = Width[[1]], 
                "dyy" = Depth,
                "xsi" = unique(sort(xsi)),
                "eta" = unique(sort(eta)),
                "htyp" = htyp ,
                "numh" = numh,
                "ho_bez" = ho_bez,
                "re_bez" = re_bez,
                "z_bez" = z_bez,
                "out.file" = paste("slope", numh, ".geo", sep="")
              )
  
  ### more than one point
  } else {
    #line 2 SlopeID
    numh =  as.numeric(strsplit(dat[2]," ")[[1]])
  # line 3 SlopeType (Constant Thickness or 'Cake shape')
    htyp = as.numeric(strsplit(dat[3]," ")[[1]])
  #line 4 Area
    Area <- as.numeric(na.exclude(as.numeric(strsplit(dat[4]," ")[[1]])))
  # line 5 Number of points
    noPoints <- as.numeric(strsplit(dat[5]," ")[[1]]) +1    ## one point less in file (?)
  # line 6 Thickness of slope
    Depth <- as.numeric(na.exclude(as.numeric(strsplit(dat[6]," ")[[1]])))
  # line 7 Eta Values
    eta <- as.numeric(na.exclude(as.numeric(strsplit(dat[7]," ")[[1]])))
  # line 8 Xsi Values
    xsi <- as.numeric(na.exclude(as.numeric(strsplit(dat[8]," ")[[1]])))
  # line 9...8+n x of slopepoints
    Rew <- strsplit(dat[9:(8+slopeCount)]," ")
    Rew <- lapply(Rew, function(x){ x <- as.numeric(na.exclude(as.numeric(x)))})
  # line 9+n...8+2n y of slopepoints
    How <- strsplit(dat[(9+slopeCount):(8+2*slopeCount)]," ")
    How <- lapply(How, function(x){ x <- as.numeric(na.exclude(as.numeric(x)))})
  # line 9+2n...8+3n z of slopepoints
    Elev <- strsplit(dat[(9+2*slopeCount):(8+3*slopeCount)]," ")
    Elev <- lapply(Elev, function(x){ x <- as.numeric(na.exclude(as.numeric(x)))})
  # line 9+3n...8+4n width of slopepoints
    Width <- strsplit(dat[(9+3*slopeCount):(8+4*slopeCount)]," ")
    Width <- lapply(Width, function(x){ x <- as.numeric(na.exclude(as.numeric(x)))})

  # aggregate to list with one list per hillslope

   for(i in 1:(slopeCount))
   {  erg[[i]] <- list( "xh" = Rew[[i]][1:noPoints[i]], 
                        "yh" = How[[i]][1:noPoints[i]],
                        "zh" = Elev[[i]][1:noPoints[i]], 
                        "tot.area" = Area[i],
                        "bh" = Width[[i]][1:noPoints[i]], 
                        "dyy" = Depth[i],
                        "xsi" = unique(sort(xsi)),
                        "eta" = unique(sort(eta)),
                        "htyp" = htyp[i] ,
                        "numh" = numh[i],
                        "ho_bez" = ho_bez,
                        "re_bez" = re_bez,
                        "z_bez" = z_bez,
                        "out.file" = paste("slope", numh[i], ".geo", sep="")
                        )
   }
   names(erg) <- paste("slope", numh, sep="")
  }
 return(erg)
}

