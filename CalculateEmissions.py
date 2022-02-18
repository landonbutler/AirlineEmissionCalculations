import pandas as pd
import os
import numpy as np
from tqdm import tqdm
import math
import pickle
import requests
import zipfile
import argparse
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def emissions_calc(FAAcode, airplane, timeTakeoff, timeClimb, timeApproach, timeTaxiIn, timeTaxiOut, timeCCD, ltoTableDict, ccdTable, backupDict):
    # Inputs:
    # FAAcode: FAA engine code
    # airplane: airplane type code
    # timeTakeoff: time during take-off, in seconds
    # timeClimb: time during climbing, in seconds
    # timeApproach: time during approach and landing, in seconds
    # timeIdle: time during taxi-in and taxi-out, in seconds
    # timeCCD: time during cruising, in minutes
    # ltoTable: table containing emissions data for the LTO cycle
    # ccdTable: table containing emissions data for the CCD cycle
    # backupDict: FILL IN

    # Outputs:
    # Total_CO2: total amount of CO2 emitted
    # Total_CO2e:total amount of CO2 equivalent emitted (including all other
    # gases such as NOx, HC and CO)

    # Carbon Equivalent Conversion Factors
    CO_2_CO2 = 1.57
    HC_2_CO2 = 84
    NOx_2_CO2 = 298

    ###########################################################################


    ###########################################################################
    # LTO Cycle Emissions Calculations                                        #
    ###########################################################################
    # Finding the lto_table entries corresponding to the desired FAA code
    UIDs = []
    for k,v in ltoTableDict['FAA Code'].items():
        if v == FAAcode:
            UIDs.append(k)

    # If it happens that for some reason the engine FAA_code doesn't match with
    # any of the ones we got, then we consider the following back-up
    if len(UIDs) == 0:
        if airplane in backupDict['FAA Engine Code']:
            FAAcode = backupDict['FAA Engine Code'][airplane]
            for k,v in ltoTableDict['FAA Code'].items():
                if v == FAAcode:
                    UIDs.append(k)
    # Using the indeces, we find the average value of the emissions for the
    # particular engine type. For that, we first construct a smaller, 20-column 
    # table, containing the following information in each column, as shown in
    # the for loop below. Notice that the number next to each entry corresponds 
    # to the column number from the excel table
    if len(UIDs) == 0:
        Total_CO2_lto, Total_CO2e_lto, origin_em, origin_em_eq, destination_em, destination_em_eq, Total_HC_lto, Total_CO_lto, Total_NOx_lto, Total_CO2_lto, Total_CO2_ccd, Total_NOx_ccd, Total_SOx_ccd, Total_H2O_ccd, Total_CO_ccd, Total_HC_ccd = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    else:
        lto_em_table = np.zeros((len(UIDs),20));
        # Filling the table up
        # 'HC EI T/O (g/kg)', 'HC T/O (kg)', 'HC T/O (kg/s)', 'HC EI C/O (g/kg)', 'HC C/O (kg)', 'HC C/O (kg/s)', 'HC EI App (g/kg)', 'HC App (kg)', 'HC App (kg/s)', 'HC EI Idle (g/kg)', 'HC Idle (kg)', 'HC Idle (kg/s)', 'HC LTO Total mass (g)', 'CO EI T/O (g/kg)', 'CO T/O (kg)', 'CO T/O (kg/s)', 'CO EI C/O (kg/s)', 'CO C/O (kg)', 'CO C/O (kg/s)', 'CO EI App (g/kg)', 'CO App (kg)', 'CO App (kg/s)', 'CO EI Idle (g/kg)', 'CO Idle (kg)', 'CO Idle (kg/s)', 'CO LTO Total Mass (g)', 'NOx EI T/O (g/kg)', 'NOx T/O (kg)', 'NOx T/O (kg/s)', 'NOx EI C/O (g/kg)', 'NOx C/O (kg)', 'NOx C/O (kg/s)', 'NOx EI App (g/kg)', 'NOx App (kg)', 'NOx App (kg/s)', 'NOx EI Idle (g/kg)', 'NOx Idle (kg)', 'NOx Idle (kg/s)', 'NOx LTO Total mass (g)'
        for i, id in enumerate(UIDs):
            rates = []

            rates.append(ltoTableDict['HC T/O (kg)'][id])
            rates.append(ltoTableDict['HC C/O (kg/s)'][id])
            rates.append(ltoTableDict['HC App (kg/s)'][id])
            rates.append(ltoTableDict['HC Idle (kg/s)'][id])
            rates.append(ltoTableDict['CO T/O (kg/s)'][id])
            rates.append(ltoTableDict['CO C/O (kg/s)'][id])
            rates.append(ltoTableDict['CO App (kg/s)'][id])
            rates.append(ltoTableDict['CO Idle (kg/s)'][id])
            rates.append(ltoTableDict['NOx T/O (kg/s)'][id])
            rates.append(ltoTableDict['NOx C/O (kg/s)'][id])
            rates.append(ltoTableDict['NOx App (kg/s)'][id])
            rates.append(ltoTableDict['NOx Idle (kg/s)'][id])
            rates.append(ltoTableDict['Fuel Flow T/O (kg/sec)'][id])
            rates.append(ltoTableDict['Fuel Flow C/O (kg/sec)'][id])
            rates.append(ltoTableDict['Fuel Flow App (kg/sec)'][id])
            rates.append(ltoTableDict['Fuel Flow Idle (kg/sec)'][id])
            rates.append(ltoTableDict['CO2 T/O (kg/s)'][id])
            rates.append(ltoTableDict['CO2 C/O (kg/s)'][id])
            rates.append(ltoTableDict['CO2 App (kg/s)'][id])
            rates.append(ltoTableDict['CO2 Idle (kg/s)'][id])
            


            # Ask if there is any entry that has a NaN in it and replace it with a
            # 0 instead
            cleanedRates = []
            for r in rates:
                if pd.isna(r):
                    cleanedRates.append(0)
                else:
                    cleanedRates.append(r)
            lto_em_table[i,:] = cleanedRates

        # After filling up the table, we can take the average value across each
        # column (for the case where multiple engines correspond to the same FAA
        # code):
        lto_em = np.mean(lto_em_table, axis=0)

        # Now, it is possible to calculate the emissions from the LTO cycle. This
        # is a simple calculation, that involves multiplying the specific LTO time
        # by the emission factor from the "em" table
        timeIdle = timeTaxiIn + timeTaxiOut
        Total_HC_lto = timeTakeoff*lto_em[0] + timeClimb*lto_em[1] + timeApproach*lto_em[2] + timeIdle*lto_em[3]
        Total_CO_lto = timeTakeoff*lto_em[4] + timeClimb*lto_em[5] + timeApproach*lto_em[6] + timeIdle*lto_em[7]
        Total_NOx_lto = timeTakeoff*lto_em[8] + timeClimb*lto_em[9] + timeApproach*lto_em[10] + timeIdle*lto_em[11]
        Total_Fuel_lto = timeTakeoff*lto_em[12] + timeClimb*lto_em[13] + timeApproach*lto_em[14] + timeIdle*lto_em[15]
        Total_CO2_lto = timeTakeoff*lto_em[16] + timeClimb*lto_em[17] + timeApproach*lto_em[18] + timeIdle*lto_em[19]
        
        origin_em = timeTakeoff*lto_em[16] + timeClimb*lto_em[17] + timeTaxiOut*lto_em[19]
        destination_em = timeApproach*lto_em[18] + timeTaxiIn*lto_em[19]

        origin_em_eq = HC_2_CO2*(timeTakeoff*lto_em[0] + timeClimb*lto_em[1] + timeTaxiOut*lto_em[3]) + CO_2_CO2*(timeTakeoff*lto_em[4] + timeClimb*lto_em[5] + timeTaxiOut*lto_em[7]) + NOx_2_CO2*(timeTakeoff*lto_em[8] + timeClimb*lto_em[9] + timeTaxiOut*lto_em[11]) + (timeTakeoff*lto_em[16] + timeClimb*lto_em[17] + timeTaxiOut*lto_em[19])
        destination_em_eq = HC_2_CO2*(timeApproach*lto_em[2] + timeTaxiIn*lto_em[3]) + CO_2_CO2*(timeApproach*lto_em[6] + timeTaxiIn*lto_em[7]) + NOx_2_CO2*(timeApproach*lto_em[10] + timeTaxiIn*lto_em[11]) + (timeApproach*lto_em[18] + timeTaxiIn*lto_em[19])

        # And having done this, it is possible to compute the total carbon
        # equivalent emissions from all four types of gases combined. Recall from
        # above that HC_2_CO2, CO_2_CO2 and NOx_2_CO2 are the conversion factors
        # from the impact of HC, CO and NOx in terms of CO2, respectively. Overall,
        # we get that:
        Total_CO2e_lto = HC_2_CO2*Total_HC_lto + CO_2_CO2*Total_CO_lto + NOx_2_CO2*Total_NOx_lto + Total_CO2_lto
    ###########################################################################


    ###########################################################################
    # CCD Cycle Emissions Calculations                                        #
    ###########################################################################
    # Finding the ccd_table entries corresponding to the desired airplane type
    CCDairplanes = CCDtable[CCDtable['Standard Code'] == airplane]

    # Using the indeces, we construct a smaller, 9-column table, containing the 
    # following information in each column, as shown in the for loop below. 
    # Notice that the number next to each entry corresponds to the column 
    # number from the excel table

    # Filling the table up
    CCDairplanes = CCDairplanes
    ccd_em_table = CCDairplanes[['Distance (nm)','Duration (min)','Fuel Burnt (kg)','CO2 (kg)','NOX (kg)','SOX (kg)','H20 (kg)','CO (kg)','HC  (kg)']].fillna(0).to_numpy()
    if ccd_em_table.shape[0] > 0:
        # Now, it is possible to calculate the emissions from the CCD cycle. This
        # is a simple interpolation calculation, that goes as follows. However, we 
        # first need to find the interval in which the ccd time falls into. For
        # that, we consider the following for loop:
        low_ind = 0
        high_ind = 0
        for i in range(ccd_em_table.shape[0]-1):
            if timeCCD > ccd_em_table[i,1] and timeCCD < ccd_em_table[i+1,1]:
                low_ind = i
                high_ind = i + 1
        if timeCCD < ccd_em_table[0,1]:
            # Flight time is smaller than the first entry
            Total_Fuel_ccd = ccd_em_table[0,2]
            Total_CO2_ccd = ccd_em_table[0,3]
            Total_NOx_ccd = ccd_em_table[0,4]
            Total_SOx_ccd = ccd_em_table[0,5]
            Total_H2O_ccd = ccd_em_table[0,6]
            Total_CO_ccd = ccd_em_table[0,7]
            Total_HC_ccd = ccd_em_table[0,8]
        elif timeCCD > ccd_em_table[ccd_em_table.shape[0]-1,1]:
            # Flight time is larger than the max entry
            Total_Fuel_ccd = ccd_em_table[ccd_em_table.shape[0]-1,2]
            Total_CO2_ccd = ccd_em_table[ccd_em_table.shape[0]-1,3]
            Total_NOx_ccd = ccd_em_table[ccd_em_table.shape[0]-1,4]
            Total_SOx_ccd = ccd_em_table[ccd_em_table.shape[0]-1,5]
            Total_H2O_ccd = ccd_em_table[ccd_em_table.shape[0]-1,6]
            Total_CO_ccd = ccd_em_table[ccd_em_table.shape[0]-1,7]
            Total_HC_ccd = ccd_em_table[ccd_em_table.shape[0]-1,8]
        else:
            # Linear interpolation
            diff_t = ccd_em_table[high_ind,1] - ccd_em_table[low_ind,1]
            diff_Fuel = ccd_em_table[high_ind,2] - ccd_em_table[low_ind,2]
            diff_CO2 = ccd_em_table[high_ind,3] - ccd_em_table[low_ind,3]
            diff_NOx = ccd_em_table[high_ind,4] - ccd_em_table[low_ind,4]
            diff_SOx = ccd_em_table[high_ind,5] - ccd_em_table[low_ind,5]
            diff_H2O = ccd_em_table[high_ind,6] - ccd_em_table[low_ind,6]
            diff_CO = ccd_em_table[high_ind,7] - ccd_em_table[low_ind,7]
            diff_HC = ccd_em_table[high_ind,8] - ccd_em_table[low_ind,8]

            timeDiff = timeCCD - ccd_em_table[low_ind,1]
            Total_Fuel_ccd = (diff_Fuel/diff_t)*timeDiff + ccd_em_table[low_ind,2]
            Total_CO2_ccd = (diff_CO2/diff_t)*timeDiff + ccd_em_table[low_ind,3]
            Total_NOx_ccd = (diff_NOx/diff_t)*timeDiff + ccd_em_table[low_ind,4]
            Total_SOx_ccd = (diff_SOx/diff_t)*timeDiff + ccd_em_table[low_ind,5]
            Total_H2O_ccd = (diff_H2O/diff_t)*timeDiff + ccd_em_table[low_ind,6]
            Total_CO_ccd = (diff_CO/diff_t)*timeDiff + ccd_em_table[low_ind,7]
            Total_HC_ccd = (diff_HC/diff_t)*timeDiff + ccd_em_table[low_ind,8] 

        # And having done this, it is possible to compute the total carbon
        # equivalent emissions from all the types of gases combined. Recall from
        # above that HC_2_CO2, CO_2_CO2 and NOx_2_CO2 are the conversion factors
        # from the impact of HC, CO and NOx in terms of CO2, respectively. Overall,
        # we get that:
        Total_CO2e_ccd = HC_2_CO2*Total_HC_ccd + CO_2_CO2*Total_CO_ccd + NOx_2_CO2*Total_NOx_ccd + Total_CO2_ccd;
    else:
        Total_CO2_ccd, Total_CO2e_ccd = 0, 0
        Total_HC_lto, Total_CO_lto, Total_NOx_lto, Total_CO2_lto, Total_CO2_ccd, Total_NOx_ccd, Total_SOx_ccd, Total_H2O_ccd, Total_CO_ccd, Total_HC_ccd = 0,0,0,0,0,0,0,0,0,0

    ###########################################################################

    ###########################################################################
    # Overall Engine Emissions                                                #
    ###########################################################################

    Total_CO2 = Total_CO2_lto + Total_CO2_ccd
    Total_CO2e = Total_CO2e_lto + Total_CO2e_ccd

    return Total_CO2, Total_CO2e, origin_em, origin_em_eq, destination_em, destination_em_eq, Total_HC_lto, Total_CO_lto, Total_NOx_lto, Total_CO2_lto, Total_CO2_ccd, Total_NOx_ccd, Total_SOx_ccd, Total_H2O_ccd, Total_CO_ccd, Total_HC_ccd

def emissions_batch(onTime, ENGtableDict, LTOtableDict, CCDtable, backupDict, aircraftManufacture):
    total_CO2s = []
    total_CO2es = []
    number_seats = []
    total_Origin_LTO = []
    total_Origin_LTOe = []
    total_Destination_LTO = []
    total_Destination_LTOe = []
    airplane_manu_year = []
    total_HC_lto = [] 
    total_CO_lto = [] 
    total_NOx_lto = [] 
    total_CO2_lto = [] 
    total_CO2_ccd = [] 
    total_NOx_ccd = []
    total_SOx_ccd = [] 
    total_H2O_ccd = [] 
    total_CO_ccd = [] 
    total_HC_ccd = []

    for ind, row in tqdm(onTime.iterrows(), total=onTime.shape[0]):
        if row['Tail_Number'] in ENGtableDict and not pd.isna(row['AirTime']):
            FAAcode = ENGtableDict[row['Tail_Number']]['FAA Engine Code']
            airplane = ENGtableDict[row['Tail_Number']]['Standard Code']
            ICAOcode = row['Reporting_Airline']
            if row['Tail_Number'] in aircraftManufacture:
                airplane_manu_year.append(aircraftManufacture[row['Tail_Number']])
            else:
                airplane_manu_year.append(np.nan)
            timeTakeoff = 42
            timeClimb = 132
            timeApproach = 240
            timeTaxiIn = 60 * row['TaxiIn']
            timeTaxiOut = 60 * row['TaxiOut']
            timeCCD = row['AirTime'] - ((timeTakeoff + timeClimb + timeApproach)/60)

            Total_CO2, Total_CO2e, origin_em, origin_em_eq, destination_em, destination_em_eq, Total_HC_lto, Total_CO_lto, Total_NOx_lto, Total_CO2_lto, Total_CO2_ccd, Total_NOx_ccd, Total_SOx_ccd, Total_H2O_ccd, Total_CO_ccd, Total_HC_ccd = emissions_calc(FAAcode , airplane, timeTakeoff, timeClimb, timeApproach, timeTaxiIn, timeTaxiOut, timeCCD, LTOtableDict, CCDtable, backupDict)
            total_CO2s.append(Total_CO2)
            total_CO2es.append(Total_CO2e)
            total_Origin_LTO.append(origin_em)
            total_Origin_LTOe.append(origin_em_eq)
            total_Destination_LTO.append(destination_em)
            total_Destination_LTOe.append(destination_em_eq)
            number_seats.append(ENGtableDict[row['Tail_Number']]['Number of Seats'])
            total_HC_lto.append(Total_HC_lto)
            total_CO_lto.append(Total_CO_lto)
            total_NOx_lto.append(Total_NOx_lto)
            total_CO2_lto.append(Total_CO2_lto)
            total_CO2_ccd.append(Total_CO2_ccd)
            total_NOx_ccd.append(Total_NOx_ccd)
            total_SOx_ccd.append(Total_SOx_ccd)
            total_H2O_ccd.append(Total_H2O_ccd)
            total_CO_ccd.append(Total_CO_ccd)
            total_HC_ccd.append(Total_HC_ccd)
        else:
            total_CO2s.append(np.nan)
            total_CO2es.append(np.nan)
            number_seats.append(np.nan)
            total_Origin_LTO.append(np.nan)
            total_Origin_LTOe.append(np.nan)
            total_Destination_LTO.append(np.nan)
            total_Destination_LTOe.append(np.nan)
            airplane_manu_year.append(np.nan)
            total_HC_lto.append(np.nan)
            total_CO_lto.append(np.nan)
            total_NOx_lto.append(np.nan)
            total_CO2_lto.append(np.nan)
            total_CO2_ccd.append(np.nan)
            total_NOx_ccd.append(np.nan)
            total_SOx_ccd.append(np.nan)
            total_H2O_ccd.append(np.nan)
            total_CO_ccd.append(np.nan)
            total_HC_ccd.append(np.nan)
    
    onTime['Total CO2'] = total_CO2s
    onTime['Total CO2E'] = total_CO2es
    onTime['Number Seats'] = number_seats
    onTime['Origin LTO CO2'] =  total_Origin_LTO
    onTime['Origin LTO CO2e'] = total_Origin_LTOe
    onTime['Destination LTO CO2'] = total_Destination_LTO
    onTime['Destination LTO CO2e'] = total_Destination_LTOe
    onTime['Airplane Manu Year'] = airplane_manu_year
    onTime['Total_HC_lto'] =  total_HC_lto
    onTime['Total_CO_lto'] = total_CO_lto
    onTime['Total_NOx_lto'] = total_NOx_lto
    onTime['Total_CO2_lto'] = total_CO2_lto
    onTime['Total_CO2_ccd'] =  total_CO2_ccd
    onTime['Total_NOx_ccd'] = total_NOx_ccd
    onTime['Total_SOx_ccd'] = total_SOx_ccd
    onTime['Total_H2O_ccd'] = total_H2O_ccd
    onTime['Total_CO_ccd'] = total_CO_ccd
    onTime['Total_HC_ccd'] = total_HC_ccd
    return onTime

def readReferenceTables(onTime):
    # Downloads Aircraft Information
    aircraft = pd.read_csv('ReferenceTables/AircraftByAirline.csv')
    # Keeps latest reported aircraft
    aircraft = aircraft[aircraft['YEAR'] == 2020]

    # Saves as dictionary for quick look-up
    aircraftManufacture = {}
    for i,row in aircraft.iterrows():
        aircraftManufacture[row['TAIL_NUMBER']] = row['MANUFACTURE_YEAR']

    # Loads in LTO emission information and saves into a dictionary
    LTOtable = pd.read_excel('ReferenceTables/ICAO Emissions Databank.xlsx').set_index('UID No')
    LTOtableDict = LTOtable.to_dict()

    # Loads in CCD emission information
    CCDtable = pd.read_excel('ReferenceTables/Engine Fuel Consumption.xlsx')

    # Loads in Engine Table
    ENGtable = pd.read_excel('ReferenceTables/Master Airplane Engine Table.xlsx')
    ENGtableDict = {}
    # Maps newest Tail Number to {Standard Code, Number of Seats, FAA Engine Code} 
    for i, row in ENGtable.iterrows():
        if not pd.isna(row['FAA Engine Code (Complete)']):
            ENGtableDict[row['Tail Number']] = {'Standard Code': row['Standard Code'],
                                            'Number of Seats': row['Number of Seats'],
                                            'FAA Engine Code': int(row['FAA Engine Code (Complete)'])}

    # Loads in LTO Backup information for Ambiguous Flights
    backup = pd.read_excel('ReferenceTables/lto_backup.xlsx')
    backupDict = backup.set_index('Standard Code').to_dict()

    return aircraftManufacture, LTOtableDict, CCDtable, ENGtableDict, backupDict
    
if __name__ == '__main__':
    parser = argparse.ArgumentParser("Monthly Emissions Calculation")
    parser.add_argument("YEAR", help="A year since 1987", type=int)
    parser.add_argument("MONTH", help="A month as an integer 1-12", type=int)
    args = parser.parse_args()

    # Make YEAR and MONTH be entered upon calling script
    YEAR = args.YEAR    # Ex. 2021
    MONTH = args.MONTH  # Integer 1-12, Ex. 11

    # Downloads On-Time Dataset into Reference Tables
    print(f'Loading in On-Time Dataset for {MONTH}, {YEAR}...')
    url = f"https://transtats.bts.gov/PREZIP/On_Time_Reporting_Carrier_On_Time_Performance_1987_present_{YEAR}_{MONTH}.zip"
    onTimeFilename = f"ReferenceTables/On_Time_{YEAR}_{MONTH}.zip"
    r = requests.get(url, allow_redirects=True, verify=False)
    open(onTimeFilename, 'wb').write(r.content)

    # Unzips the On-Time Dataset and saves into a Pandas DataFrame
    with zipfile.ZipFile(onTimeFilename, 'r') as zipRef:
        zipRef.extractall('ReferenceTables')
    print('Reading into Pandas Dataframe...')
    onTime = pd.read_csv(f'ReferenceTables/On_Time_Reporting_Carrier_On_Time_Performance_(1987_present)_{YEAR}_{MONTH}.csv', low_memory=False)

    # Reads in Reference Tables
    print('Ingesting Reference Tables...')
    aircraftManufacture, LTOtableDict, CCDtable, ENGtableDict, backupDict = readReferenceTables(onTime)

    # Runs Emissions Batch Script
    print('Beginning Emissions Calculations...')
    onTimeEmissions = emissions_batch(onTime, ENGtableDict, LTOtableDict, CCDtable, backupDict, aircraftManufacture)

    # Saves to Results directory
    print('Emissions Calculations Finished!')
    saveLoc = f'Results/OnTimeEmissions{YEAR}_{MONTH}.csv'
    print(f'Saving to {saveLoc}')
    onTimeEmissions.to_csv(saveLoc)