%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Engine Emissions Calculator - flight_emissions:                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This code calculates the emissions of a particular airplane/tail-number 
% for the provided conditions

% Uploading the LTO cycle table
lto_table = readtable('data/ICAO Emissions Databank.xlsx');
% Uploading the CCD cycle table
ccd_table = readtable('data/Engine Fuel Consumption.xlsx');
% Uploading the master airplane/engines table
eng_table = readtable('data/Master Airplane Engine Table.xlsx');
% Uploading the LTO table back-up for cases in which there is no matching
backup = readtable('data/lto_backup.xlsx');

% From eng_table, we are mainly interested in columns 3, 4, 5, 6, denoting
% the standard airplane code, tail number, airplane number of seats and FAA
% engine code. Now, it is possible to input a particular tailnumber,
% together with the corresponding LTO and CCD times, and the total amount
% of emissions will be calculated, together with the emissions per
% passenger ratio

% Setting the tailnumber (notice the notation in quotation marks)
tailnumber = 'N815DN';
% Setting the LTO cycle times, in seconds
time_Takeoff = 42;
time_Climb = 132;
time_Approach = 240;
time_Idle = 22.85*60;
% Setting the CCD cycle times, in minutes
time_CCD = 124;

% Extracting from eng_table the corresponding FAA code and airplane type
in = find(tailnumber == string(eng_table{:,4}));
l = round(length(in)/2);
% Note: it is possible that the same tailnumber has been recorded multiple
% times in the eng_table, given that it encompasses multiple years. As a
% result, it could also be possible that the airline owning the airplane
% changed the engine type too. For the purposes of this code, we'll take
% the results corresponding to the first engine type, although we'll
% perform the calculations for all the different types of engines. We'll
% store all this information in the env_impact table
env_impact = zeros(l,3);

for k = 1:l
    
% Setting the FAA code
FAA_code = eng_table{in(k),6};
% Setting the airplane type
airplane = eng_table{in(k),3};
% Setting the airplane type number of seats
seats = eng_table{in(k),5};

% Performing the calculations
[Total_CO2,Total_CO2e] = emissions_calc(FAA_code,airplane,time_Takeoff,time_Climb,time_Approach,time_Idle,time_CCD,lto_table,ccd_table,backup);
Carbon_Footprint = Total_CO2e/seats;

% Storing the results
env_impact(k,1) = Total_CO2;
env_impact(k,2) = Total_CO2e;
env_impact(k,3) = Carbon_Footprint;

end

disp(['Total CO2 produced by the flight was equal to ',num2str(env_impact(1,1)),' kg'])
disp(['Total CO2 equivalent produced by the flight was equal to ',num2str(env_impact(1,2)),' kg'])
disp(['Average Carbon Footprint the flight was equal to ',num2str(env_impact(1,3)),' kg'])
