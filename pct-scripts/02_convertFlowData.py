#!/usr/bin/python3

# This script converts csv files containing flow/od data as can be obtained from
# ctpp.transportation.org to a format that can be imported into the pct

import pandas as pd
import numpy  as np
import glob

counties = ["AlamedaCounty", "ContraCostaCounty", "MarinCounty", "NapaCounty", "SanFranciscoCounty", "SanMateoCounty", "SantaClaraCounty", "SolanoCounty", "SonomaCounty"]

# Set column names
columnNames = ["zone_code", "dest_code", "all", "all.error", "car.1p", "car.1p.error", "car.2p", "car.2p.error", "car.3p", "car.3p.error", "car.4p", "car.4p.error", "car.5p", "car.5p.error", "car.7p", "car.7p.error", "bus", "bus.error", "streetcar", "streetcar.error", "subway", "subway.error",  "railroad", "railroad.error",  "ferry", "ferry.error", "bicycle", "bicycle.error", "walked", "walked.error", "taxi", "taxi.error", "motorcycle", "motorcycle.error", "other", "other.error", "home", "home.error", "auto", "auto.error"]

for county in counties:

    fileList = glob.glob("../pct-inputs/01_raw/02_flow_data/" + county + "*.csv")
    for index, filePath in enumerate(fileList):
        print(county)
        if index == 0:
            rawDf = pd.read_csv(filePath, skiprows=3, skipfooter=3, header=None, engine='python', names=["Origin", "Destination", "How", "What", "Number"])
        else:
            tmpDf = pd.read_csv(filePath, skiprows=3, skipfooter=3, header=None, engine='python', names=["Origin", "Destination", "How", "What", "Number"])

            frames = [rawDf, tmpDf]
            rawDf = pd.concat(frames)

# Count unique columns
    columns = len(rawDf[rawDf["How"].str.contains("Total, means of transportatio") & rawDf["What"].str.contains("Estimate")])

# Set empty array
    npData = np.zeros((columns, len(columnNames)))

# Define dataframe
    df = pd.DataFrame(data=npData, columns=columnNames)

# Iterate over rows of raw dataframe and copy to df
    rowNr = -1
    for index, row in rawDf.iterrows():
        if row["How"] == "Total, means of transportation" and row["What"] == "Estimate":
            rowNr = rowNr + 1
            df.loc[rowNr,"zone_code"] = row["Origin"].split(',')[0].split(' ')[1]
            df.loc[rowNr,"dest_code"] = row["Destination"].split(',')[0].split(' ')[1]
            df.loc[rowNr,"all"] = row["Number"] 
        if row["How"] == "Total, means of transportation" and row["What"] == "Margin of Error":
            df.loc[rowNr,"all.error"] = row["Number"] 
        if row["How"] == "Car, truck, or van -- Drove alone" and row["What"] == "Estimate":
            df.loc[rowNr,"car.1p"] = row["Number"] 
        if row["How"] == "Car, truck, or van -- Drove alone" and row["What"] == "Margin of Error":
            df.loc[rowNr,"car.1p.error"] = row["Number"] 
        if row["How"] == "Car, truck, or van -- In a 2-person carpool" and row["What"] == "Estimate":
            df.loc[rowNr,"car.2p"] = row["Number"] 
        if row["How"] == "Car, truck, or van -- In a 2-person carpool" and row["What"] == "Margin of Error":
            df.loc[rowNr,"car.2p.error"] = row["Number"] 
        if row["How"] == "Car, truck, or van -- In a 3-person carpool" and row["What"] == "Estimate":
            df.loc[rowNr,"car.3p"] = row["Number"] 
        if row["How"] == "Car, truck, or van -- In a 3-person carpool" and row["What"] == "Margin of Error":
            df.loc[rowNr,"car.3p.error"] = row["Number"] 
        if row["How"] == "Car, truck, or van -- In a 4-person carpool" and row["What"] == "Estimate":
            df.loc[rowNr,"car.4p"] = row["Number"] 
        if row["How"] == "Car, truck, or van -- In a 4-person carpool" and row["What"] == "Margin of Error":
            df.loc[rowNr,"car.4p.error"] = row["Number"] 
        if row["How"] == "Car, truck, or van -- In a 5-or-6-person carpool" and row["What"] == "Estimate":
            df.loc[rowNr,"car.5p"] = row["Number"] 
        if row["How"] == "Car, truck, or van -- In a 5-or-6-person carpool" and row["What"] == "Margin of Error":
            df.loc[rowNr,"car.5p.error"] = row["Number"] 
        if row["How"] == "Car, truck, or van -- In a 7-or-more-person carpool" and row["What"] == "Estimate":
            df.loc[rowNr,"car.7p"] = row["Number"] 
        if row["How"] == "Car, truck, or van -- In a 7-or-more-person carpool" and row["What"] == "Margin of Error":
            df.loc[rowNr,"car.7p.error"] = row["Number"] 
        if row["How"] == "Bus or trolley bus" and row["What"] == "Estimate":
            df.loc[rowNr,"bus"] = row["Number"] 
        if row["How"] == "Bus or trolley bus" and row["What"] == "Margin of Error":
            df.loc[rowNr,"bus.error"] = row["Number"] 
        if row["How"] == "Streetcar or trolley car" and row["What"] == "Estimate":
            df.loc[rowNr,"streetcar"] = row["Number"] 
        if row["How"] == "Streetcar or trolley car" and row["What"] == "Margin of Error":
            df.loc[rowNr,"streetcar.error"] = row["Number"] 
        if row["How"] == "Subway or elevated" and row["What"] == "Estimate":
            df.loc[rowNr,"subway"] = row["Number"] 
        if row["How"] == "Subway or elevated" and row["What"] == "Margin of Error":
            df.loc[rowNr,"subway.error"] = row["Number"] 
        if row["How"] == "Railroad" and row["What"] == "Estimate":
            df.loc[rowNr,"railroad"] = row["Number"] 
        if row["How"] == "Railroad" and row["What"] == "Margin of Error":
            df.loc[rowNr,"railroad.error"] = row["Number"] 
        if row["How"] == "Ferryboat" and row["What"] == "Estimate":
            df.loc[rowNr,"ferry"] = row["Number"] 
        if row["How"] == "Ferryboat" and row["What"] == "Margin of Error":
            df.loc[rowNr,"ferry.error"] = row["Number"] 
        if row["How"] == "Bicycle" and row["What"] == "Estimate":
            df.loc[rowNr,"bicycle"] = row["Number"] 
        if row["How"] == "Bicycle" and row["What"] == "Margin of Error":
            df.loc[rowNr,"bicycle.error"] = row["Number"] 
        if row["How"] == "Walked" and row["What"] == "Estimate":
            df.loc[rowNr,"walked"] = row["Number"] 
        if row["How"] == "Walked" and row["What"] == "Margin of Error":
            df.loc[rowNr,"walked.error"] = row["Number"] 
        if row["How"] == "Taxicab" and row["What"] == "Estimate":
            df.loc[rowNr,"taxi"] = row["Number"] 
        if row["How"] == "Taxicab" and row["What"] == "Margin of Error":
            df.loc[rowNr,"taxi.error"] = row["Number"] 
        if row["How"] == "Motorcycle" and row["What"] == "Estimate":
            df.loc[rowNr,"motorcycle"] = row["Number"] 
        if row["How"] == "Motorcycle" and row["What"] == "Margin of Error":
            df.loc[rowNr,"motorcycle.error"] = row["Number"] 
        if row["How"] == "Other method" and row["What"] == "Estimate":
            df.loc[rowNr,"other"] = row["Number"] 
        if row["How"] == "Other method" and row["What"] == "Margin of Error":
            df.loc[rowNr,"other.error"] = row["Number"] 
        if row["How"] == "Worked at home" and row["What"] == "Estimate":
            df.loc[rowNr,"home"] = row["Number"] 
        if row["How"] == "Worked at home" and row["What"] == "Margin of Error":
            df.loc[rowNr,"home.error"] = row["Number"] 
        if row["How"] == "Auto" and row["What"] == "Estimate":
            df.loc[rowNr,"auto"] = row["Number"] 
        if row["How"] == "Auto" and row["What"] == "Margin of Error":
            df.loc[rowNr,"auto.error"] = row["Number"] 

    df.to_csv("../pct-inputs/02_intermediate/02_flow_data/" + county + "-BayArea_od.csv", index=False)
