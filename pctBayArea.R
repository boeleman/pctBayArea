# devtools::install_github("ATFutures/geoplumber")

##install.packages("remotes")
#pkgs = c(
##  "mapview",
##  "stats19",
##  "tidyverse",
##  "devtools",
##  "lwgeom",
#  "cyclestreets",
#  "pct",
#  "stplanr",
#  "sf",
#  "geojsonsf"
#)
#remotes::install_cran(pkgs, lib="~/local/lib/R")


# Load libraries
library(cyclestreets, lib.loc="~/local/lib/R")
library(geojsonsf, lib.loc="~/local/lib/R")
library(stplanr, lib.loc="~/local/lib/R")
library(pct, lib.loc="~/local/lib/R")
library(sf, lib.loc="~/local/lib/R")


# Read all flow/od data
AlamedaCountyBayArea_od      <- readr::read_delim("pct-inputs/02_intermediate/02_flow_data/AlamedaCounty-BayArea_od.csv"     , delim =",")
ContraCostaCountyBayArea_od  <- readr::read_delim("pct-inputs/02_intermediate/02_flow_data/ContraCostaCounty-BayArea_od.csv" , delim =",")
MarinCountyBayArea_od        <- readr::read_delim("pct-inputs/02_intermediate/02_flow_data/MarinCounty-BayArea_od.csv"       , delim =",")
NapaCountyBayArea_od         <- readr::read_delim("pct-inputs/02_intermediate/02_flow_data/NapaCounty-BayArea_od.csv"        , delim =",")
SanFranciscoCountyBayArea_od <- readr::read_delim("pct-inputs/02_intermediate/02_flow_data/SanFranciscoCounty-BayArea_od.csv", delim =",")
SanMateoCountyBayArea_od     <- readr::read_delim("pct-inputs/02_intermediate/02_flow_data/SanMateoCounty-BayArea_od.csv"    , delim =",")
SantaClaraCountyBayArea_od   <- readr::read_delim("pct-inputs/02_intermediate/02_flow_data/SantaClaraCounty-BayArea_od.csv"  , delim =",")
SolanoCountyBayArea_od       <- readr::read_delim("pct-inputs/02_intermediate/02_flow_data/SolanoCounty-BayArea_od.csv"      , delim =",")
SonomaCountyBayArea_od       <- readr::read_delim("pct-inputs/02_intermediate/02_flow_data/SonomaCounty-BayArea_od.csv"      , delim =",")

# Combine data
bayArea_od <- rbind(AlamedaCountyBayArea_od, ContraCostaCountyBayArea_od )
bayArea_od <- rbind(bayArea_od             , MarinCountyBayArea_od       )
bayArea_od <- rbind(bayArea_od             , NapaCountyBayArea_od        )
bayArea_od <- rbind(bayArea_od             , SanFranciscoCountyBayArea_od)
bayArea_od <- rbind(bayArea_od             , SanMateoCountyBayArea_od    )
bayArea_od <- rbind(bayArea_od             , SantaClaraCountyBayArea_od  )
bayArea_od <- rbind(bayArea_od             , SolanoCountyBayArea_od      )
bayArea_od <- rbind(bayArea_od             , SonomaCountyBayArea_od      )


# Read zones data
bayArea_zones <- geojson_sf("pct-inputs/02_intermediate/01_geographies/bayArea_zones.GeoJson")


# Compute desire lines
bayArea_lines = stplanr::od2line(flow = bayArea_od, zones = bayArea_zones)


## Filter data to only All > 100
#bayArea_lines <- bayArea_lines[bayArea_lines$all > 100, ]
#
## Plot data
#plot(bayArea_zones$geometry, lwd=0.05)
#plot(bayArea_lines["all"], lwd = bayArea_lines$all/250, add = TRUE)


# Assume hilliness is zero for now
bayArea_lines$hilliness = 0

# Compute distance
bayArea_lines$distance = as.numeric(sf::st_length(bayArea_lines))

# Filter data to only distance < 30000
bayArea_lines <- bayArea_lines[bayArea_lines$distance < 30000, ]


# Compute uptake
bayArea_lines$godutch_pcycle = uptake_pct_godutch(distance = bayArea_lines$distance, gradient = 0)

# Compute correlation between current and potential levels of cycling. 
cor(x = bayArea_lines$bicycle, y = bayArea_lines$godutch_pcycle)


## Plot data
##plot(x = bayArea_lines$bicycle, y = bayArea_lines$godutch_pcycle)
#plot(x = bayArea_lines$distance, y = bayArea_lines$godutch_pcycle, ylim = c(0, 1))


##mytoken <- readLines("~/Dropbox/dotfiles/cyclestreets-api-key-rl") Sys.setenv(CYCLESTREETS = mytoken)
##
##bayArea_routes_cs = stplanr::line2route(bayArea_lines)
#
#
### Filter data to only bicycle > 15
##bayArea_lines <- bayArea_lines[bayArea_lines$bicycle > 15, ]
##
### Plot data
##plot(bayArea_zones$geometry, lwd=0.05)
##plot(bayArea_lines["bicycle"], lwd = bayArea_lines$bicycle/100, add = TRUE)
