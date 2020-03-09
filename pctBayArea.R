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


## Filter data to more than zero bicycle trips
#bayArea_lines <- bayArea_lines[bayArea_lines$bicycle > 0, ]

# Estimate distance
bayArea_lines$length     = as.numeric(sf::st_length(bayArea_lines))
bayArea_lines$av_incline = 0.

# Filter data to only length < 10000m
bayArea_lines  <- bayArea_lines[bayArea_lines$length < 10000, ]

# Select only part of the data
bayArea_lines <- bayArea_lines[1:10000,]

# Compute length and av_incline of routes
mytoken <- readLines("~/.cyclestreets/api-key")
Sys.setenv(CYCLESTREET = mytoken)

bayArea_routes <- stplanr::line2route(bayArea_lines, route_fun = route_cyclestreets, plan = "fastest")

# Compute distance
bayArea_lines$length     <- bayArea_routes$length
bayArea_lines$av_incline <- bayArea_routes$av_incline


# Filter NA
bayArea_lines  <- bayArea_lines[complete.cases(bayArea_lines$length), ]
bayArea_routes <- bayArea_routes[complete.cases(bayArea_routes$length), ]


# Compute current propensity to cycle
breaks <- seq(0.0 , 30000.0, by=500.0)
labels <- seq(250 , 30000  , by=500  )
pcycle <- seq(250 , 30000  , by=500  )

bayArea_lines$bins <- cut(bayArea_lines$length, breaks=breaks, labels=labels)

for(i in 1:length(labels))
{
    pcycle[i] <- with(bayArea_lines, sum(bicycle[bins==labels[i]], na.rm = TRUE))/with(bayArea_lines, sum(all[bins==labels[i]], na.rm = TRUE))
}

# Compute uptake
bayArea_lines$godutch_pcycle = uptake_pct_godutch(bayArea_lines$length, bayArea_lines$av_incline)

# Compute correlation between current and potential levels of cycling. 
cor(x = bayArea_lines$bicycle, y = bayArea_lines$godutch_pcycle)

# Plot propensity to cycle in Bay Area vs the Netherlands     
#plot(x = bayArea_lines$bicycle, y = bayArea_lines$godutch_pcycle)
plot(x = bayArea_lines$length, y = bayArea_lines$godutch_pcycle)
points(x = labels, y = pcycle)


n_lines = 1000
for (i in 1:ceiling(nrow(bayArea_lines)/n_lines))
{
    i_0 = (i-1)*n_lines+1
    i_1 = i    *n_lines

    if (i_1 > nrow(bayArea_lines))
    {
        i_1 = nrow(bayArea_lines)
    }

    cat(i_0, i_1, nrow(bayArea_lines), "\n")

    routes = sf::st_sf(
        cbind(sf::st_drop_geometry(bayArea_routes[i_0:i_1,]),
        sf::st_drop_geometry(bayArea_lines[i_0:i_1,])),
        geometry = bayArea_routes[i_0:i_1,]$geometry
    )

    routes$godutch_slc = round(routes$godutch_pcycle * routes$all)

    rnet0 = stplanr::overline2(routes, "godutch_slc")

    if (i == 1)
    {
        rnet = rnet0
    }
    else
    {
        rnet = rbind(rnet, rnet0)
    }
}

rnet = stplanr::overline2(rnet, "godutch_slc")


# Plot density map of routes
plot(rnet, lwd = log(rnet$godutch_slc / mean(rnet$godutch_slc)))
