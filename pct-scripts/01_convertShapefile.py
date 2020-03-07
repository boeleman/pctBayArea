#!/usr/bin/python3

# This script extracts Traffic Analysis Zone geometries for the Bay Area from
# TIGER/Line Shapefile data from data.gov and converts it to the geojson format

import os
import glob
import zipfile
from osgeo import ogr

# Extract to temporal location
homeDir = os.path.expanduser("~/tmp/")
with zipfile.ZipFile("../pct-inputs/01_raw/01_geographies/tl_2011_06_taz10.zip", "r") as zip_ref:
    zip_ref.extractall(homeDir)

# Bay Area county codes
# 06 001 Alameda County
# 06 013 Contra Costa County
# 06 041 Marin County
# 06 055 Napa County
# 06 075 San Francisco County
# 06 081 San Mateo County
# 06 085 Santa Clara County
# 06 095 Solano County
# 06 097 Sonoma County

field_name_target = "TAZCE10"

inShapeFile = homeDir + "tl_2011_06_taz10.shp"
inDriver = ogr.GetDriverByName("ESRI Shapefile")
inDataSource = inDriver.Open(inShapeFile, 0)
inLayer = inDataSource.GetLayer()
inLayer.SetAttributeFilter("STATEFP10 = '06' and ( COUNTYFP10 = '001' or COUNTYFP10 = '013' or COUNTYFP10 = '041' or COUNTYFP10 = '055' or COUNTYFP10 = '075' or COUNTYFP10 = '081' or COUNTYFP10 = '085' or COUNTYFP10 = '095' or COUNTYFP10 = '097' )")

#for feature in inLayer:
#    print(feature.GetField("TAZCE10"))

# Create the output Layers
outShapefile = "../pct-inputs/02_intermediate/01_geographies/bayArea_zones.GeoJson"
outDriver = ogr.GetDriverByName("GeoJSON")

# Remove output shapefile if it already exists
if os.path.exists(outShapefile):
    outDriver.DeleteDataSource(outShapefile)

# Create the output shapefile
outDataSource = outDriver.CreateDataSource(outShapefile)
outLayer = outDataSource.CreateLayer( "bayArea", geom_type=ogr.wkbMultiPolygon )

# Add input Layer Fields to the output Layer if it is the one we want
inLayerDefn = inLayer.GetLayerDefn()
for i in range(0, inLayerDefn.GetFieldCount()):
    fieldDefn = inLayerDefn.GetFieldDefn(i)
    fieldName = fieldDefn.GetName()
    if fieldName not in field_name_target:
        continue
    outLayer.CreateField(fieldDefn)

# Get the output Layer's Feature Definition
outLayerDefn = outLayer.GetLayerDefn()

# Add features to the ouput Layer
for inFeature in inLayer:
    # Create output Feature
    outFeature = ogr.Feature(outLayerDefn)

    # Add field values from input Layer
    for i in range(0, outLayerDefn.GetFieldCount()):
        fieldDefn = outLayerDefn.GetFieldDefn(i)
        fieldName = fieldDefn.GetName()
        if fieldName not in field_name_target:
            continue
        outFeature.SetField(outLayerDefn.GetFieldDefn(i).GetNameRef(), inFeature.GetField(fieldName))

    # Set geometry as centroid
    geom = inFeature.GetGeometryRef()
    outFeature.SetGeometry(geom.Clone())
    # Add new feature to output Layer
    outLayer.CreateFeature(outFeature)
    outFeature = None

# Save and close DataSources
inDataSource = None
outDataSource = None


# Clean up files
fileList = glob.glob(homeDir + "tl_2011_06_taz10.*")
for filePath in fileList:
    try:
        os.remove(filePath)
    except OSError:
        print("Error while deleting file")
