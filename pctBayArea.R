# devtools::install_github("ATFutures/geoplumber")

##install.packages("remotes")
#pkgs = c(
##  "mapview",
##  "stats19",
##  "tidyverse",
##  "devtools",
##  "lwgeom",
#  "simpleCache",
#  "leaflet.providers",
#  "leaflet",
#  "rgeos",
#  "cyclestreets",
#  "pct",
#  "sf",
#  "geojsonsf"
#)
#remotes::install_cran(pkgs, lib="~/local/lib/R")
#pkgs = c(
#  "boeleman/stplanr"
#)
#remotes::install_github(pkgs, lib="~/local/lib/R")


# Load libraries
library(cyclestreets     , lib.loc="~/local/lib/R")
library(htmlwidgets                               )
library(geojsonsf        , lib.loc="~/local/lib/R")
library(simpleCache      , lib.loc="~/local/lib/R")
library(stplanr          , lib.loc="~/local/lib/R")
library(leaflet          , lib.loc="~/local/lib/R")
library(leaflet.providers, lib.loc="~/local/lib/R")
library(pct              , lib.loc="~/local/lib/R")
library(sf                                        )

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

# People going home
bayArea_do <- bayArea_od
bayArea_do[1:2] <- bayArea_do[2:1]
bayArea_od <- rbind(bayArea_od,bayArea_do)

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

# Filter data to only length < 20000m
bayArea_lines  <- bayArea_lines[bayArea_lines$length < 20000, ]

## Select only part of the data
#bayArea_lines <- bayArea_lines[1:10000,]

# Compute length and av_incline of routes
#mytoken <- readLines("~/.cyclestreets/api-key")
#Sys.setenv(CYCLESTREET = mytoken)
Sys.setenv(GRAPHHOPPER = "NULL")

cacheDir = "."
setCacheDir(cacheDir)

simpleCache("bayArea_routes", {
    bayArea_routes <- stplanr::line2route(bayArea_lines, route_fun = route_graphhopper, vehicle = "bike", base_url = "http://localhost:8989")
#    bayArea_routes <- stplanr::line2route(bayArea_lines, route_fun = route_graphhopper, vehicle = "allbike", base_url = "http://localhost:8989")
})

# Compute distance
bayArea_lines$length     <- bayArea_routes$length
bayArea_lines$av_incline <- bayArea_routes$av_incline

# Filter NA
bayArea_lines  <- bayArea_lines[complete.cases(bayArea_lines$length), ]
bayArea_routes <- bayArea_routes[complete.cases(bayArea_routes$length), ]

# Filter data to only length < 25000m
bayArea_lines  <- bayArea_lines[bayArea_lines$length < 25000, ]
bayArea_routes <- bayArea_routes[bayArea_routes$length < 25000, ]

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


simpleCache("rnet", {
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
})

# Replace values larger than 1000
rnet$godutch_slc[rnet$godutch_slc > 2000 ] <- 2000

# Only select ways with an increase > 400
rnet <- rnet[rnet$godutch_slc > 399, ]

## Plot density map of routes
#plot(rnet, lwd = log(rnet$godutch_slc / mean(rnet$godutch_slc)))

#pal = colorNumeric(palette = "RdYlBu", domain = c(0, max(rnet$godutch_slc)), reverse = TRUE)
pal = colorNumeric(palette = "RdYlBu", domain = rnet$godutch_slc, reverse = TRUE)
m <-  leaflet(data = rnet) %>% 
    addPolylines(color = ~ pal(godutch_slc)) %>% 
    addLegend(pal = pal, values = ~godutch_slc) %>% 
    addProviderTiles(providers$CartoDB.Positron)

saveWidget(m, file="bayArea.html")
