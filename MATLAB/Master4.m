%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Engine Emissions Calculator - Master Script 4                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This code calculates the greenhouse gas emissions for a particular route
% operated during the month of September 2021. The reporting airlines are: PSA
% (OH), SkyWest (OO), Horizon (QX), United (UA), Delta (DL), Frontier (F9),
% Allegiant (G4), Hawaiian (HA), Envoy (MQ), Spirit (NK), Southwest (WN),
% Mesa (YV), Republic (YX), Endeavor (9E), American (AA), Alaska (AS) and
% JetBlue (B6). The overall outputs of this code includes:

% 1: (General Flight Statistics) Flight Distance, Average Flight Time, Average
% Delays, Airplane Types (percentage of each plane), Total Seats Offered,
% Total Flights Offered

% 2: (Airline Specific Flight Statistics) Average
% Delays, Airplane Types (percentage of each plane), Total Seats Offered,
% Total Flights Offered, Market Shares

% 3: (General Emissions) Total Emissions for the Route, Average Carbon
% Footprint

% 4: (Airline Specific Emissions) Emissions per Airline operating the route, 
% Emissions per airline airplane operating the route, average carbon 
% footprint of each airline, average footprint of flying a particular plane

% 5: (Day Statistics) Number of flights per day, emissions per day, delays 
% per day

% Uploading the LTO cycle table
lto_table = readtable('data/ICAO Emissions Databank.xlsx');
% Uploading the CCD cycle table
ccd_table = readtable('data/Engine Fuel Consumption.xlsx');
% Uploading the master airplane/engines table
eng_table = readtable('data/Master Airplane Engine Table.xlsx');
% Uploading the LTO table back-up for cases in which there is no matching
backup = readtable('data/lto_backup.xlsx');
% Uploading the September 2021 flights data
september = readtable('data/Sept-2021-Data.csv');
% Uploading the Reporting Airlines Codes
air_code = readtable('data/reporting_airlines.xlsx');

% From eng_table, we are mainly interested in columns 3, 4, 5, 6, denoting
% the standard airplane code, tail number, airplane number of seats and FAA
% engine code. Now, it is possible to input a particular tailnumber,
% together with the corresponding LTO and CCD times, and the total amount
% of emissions will be calculated, together with the emissions per
% passenger ratio

% In particular, we can extract all flight times (LTO and CCD) from the
% september table, for all tailnumbers in the US. We are interested in
% looking at the columns denoting: 
% Reporting Airline: 7 (G)
% Airplane Tailnumber: 10 (J)
% Taxi-out Time (minutes): 37 (AK)
% Taxi-in Time (minutes): 40 (AN)
% Air Time (minutes): 53 (BA) - includes the LTO standard take-off and landing times

% Other important columns are:
% Distance: 55 (BC)
% Arrival Delay Minutes: 44 (AR)
% Departure Delay Minutes: 33 (AG)
% Origin City Code: 15 (O)
% Destination City Code: 24 (X)
% Day of Week: 5 (E)

% Selecting the route:
Origin = 'JFK';
Destination = 'LAX';
% Notice the notation on each flight

% Now, we can find the indeces of the table corresponding to the selected
% Origin-Destination pair
f_or = find((string(september{:,15}) == Origin));
f_de = find((string(september{:,24}) == Destination));
f_in = [];
% Computing the vector that contains all flights 
for k = 1:length(f_or)
    
    if sum(f_or(k) == f_de) == 1
        f_in = [f_in,f_or(k)];
    end
    
end
  
% The first thing we need to do is check whether there is actually a flight
% between the selected city pairs
if isempty(f_in) == 1
    % No flights exist
    disp('No flights exist between the selected city pairs')
else
    % A flight exists, and we can begin calculating some statistics
    
    % The next thing we need to do is check whether there is recorded data
    emp = find(isnan(september{f_in,53}) == 0);
    f_in = f_in(emp);
    
    % General Flight Statistics
    disp('%--------------------------------------------------------------%')
    disp('General Flight Statistics')
    disp('%--------------------------------------------------------------%')
    % Route
    disp(['Origin Airport = ',Origin])
    disp(['Destination Airport = ',Destination])
    
    % Finding the flight distance
    dis = mean(september{f_in,55});
    disp(['Average Flight Distance = ',num2str(dis),' miles'])
    
    % Finding the Average Flight Time
    % We are adding the air time, taxi-in and taxi-out times together
    time = mean(september{f_in,37}) + mean(september{f_in,40}) + mean(september{f_in,53});
    disp(['Average Flight Time = ',num2str(time),' minutes'])
    
    % Finding the Average Delays
    dep_delay = mean(september{f_in,33});
    arr_delay = mean(september{f_in,44});
    disp(['Average Departure Delay = ',num2str(dep_delay),' minutes'])
    disp(['Average Arrival Delay = ',num2str(arr_delay),' minutes'])
    
    % Finding the Airplane Types
    tailnumbers = september{f_in,10};
    tail_in = zeros(length(f_in),1);
    for k = 1:length(f_in)
        tail_str = find(string(eng_table{:,4}) == tailnumbers(k));
        if isempty(tail_str) == 0
            tail_in(k) = tail_str(1); 
        end
    end
    ze = find(tail_in ~= 0);
    tail_in = tail_in(ze);
    airplanes = unique(eng_table{tail_in,3});
    disp('Airplane Types = ')
    disp(airplanes)
    
    % Finding the Total Number of Seats and Flights Offered
    seats = sum(eng_table{tail_in,5}); 
    flights = length(f_in);
    disp(['Total Number of Seats Offered = ',num2str(seats)])
    disp(['Total Number of Flights Offered = ',num2str(flights)])
    disp('')
    
    % Airline Specific Flight Statistics
    disp('%--------------------------------------------------------------%')
    disp('Airline Specific Flight Statistics')
    disp('%--------------------------------------------------------------%')
    rep_air = unique(september{f_in,7});
    Airlines = cell(length(rep_air),6);
    for k = 1:length(rep_air)
        Airlines{k,1} = string(rep_air(k));
        code = find(string(rep_air(k))==air_code{:,1});
        Airlines{k,2} = string(air_code{code,2});
        disp('Airline = ')
        disp([string(Airlines{k,2}),string(Airlines{k,1})])
        
        count = [];
        airline_pl = [];
        % Finding the specific flights operated by each airline
        for l = 1:length(f_in)
            if string(september{f_in(l),7}) == string(rep_air(k))
                count = [count,f_in(l)];        
            end 
        end
        tailnumbers = september{count,10};
        tail_in = zeros(length(count),1);
        
        for jj = 1:length(count)
            tail_str = find(string(eng_table{:,4}) == tailnumbers(jj));
            if isempty(tail_str) == 0
                tail_in(jj) = tail_str(1); 
            end
        end
        ze = find(tail_in ~= 0);
        tail_in = tail_in(ze);
        airplanes = unique(eng_table{tail_in,3});
        disp('Airplane Types = ')
        disp(airplanes)
        Airlines{k,3} = length(count); % Recording the number of flights
        Airlines{k,4} = sum(eng_table{tail_in,5}); % Recording the number of seats
        disp(['Total Number of Seats Offered = ',num2str(Airlines{k,4})])
        disp(['Total Number of Flights Offered = ',num2str(Airlines{k,3})])
        Airlines{k,5} = 100*Airlines{k,4}/seats; % Recording Market Share per Seats Offered
        Airlines{k,6} = 100*Airlines{k,3}/flights; % Recording Market Share per Flights Offered
        disp(['Market Share per Seats Offered = ',num2str(Airlines{k,5}),'%'])
        disp(['Market Share per Flights Offered = ',num2str(Airlines{k,6}),'%'])
        emp = find(isnan(september{count,53}) == 0);
        count = count(emp);
        dep_delay = mean(september{count,33});
        arr_delay = mean(september{count,44});
        disp(['Average Departure Delay = ',num2str(dep_delay),' minutes'])
        disp(['Average Arrival Delay = ',num2str(arr_delay),' minutes'])
        disp('-o-o-o-o-o-o-o-o-')
    end
    disp('')
    
    % General Emissions
    disp('%--------------------------------------------------------------%')
    disp('General Emissions')
    disp('%--------------------------------------------------------------%')
     % Finding the Tail Numbers
    tailnumbers = september{f_in,10};
    tail_in = zeros(length(f_in),1);
    for k = 1:length(f_in)
        tail_str = find(string(eng_table{:,4}) == tailnumbers(k));
        if isempty(tail_str) == 0
            tail_in(k) = tail_str(1); 
        end
    end
    emissions = zeros(4,length(rep_air));
    day_of_week = zeros(7,1);
    count = 0;
    for k = 1:length(f_in)
        % Setting the tailnumber
        tailnumber = tailnumbers(k); 
        % Extracting the flight reporting airline ICAO code
        icao_code = september{f_in(k),7};
        icao_in = find(string(rep_air) == string(icao_code));
        day = september{f_in(k),5};
        if tail_in(k) ~= 0
            % We only perform the calculations if there is data available
            % Airplane Type
            airplane = eng_table{tail_in(k),3};
            % Setting the LTO cycle times, in seconds
            time_Takeoff = 42;
            time_Climb = 132;
            time_Approach = 240;
            % Extracting the taxi-in and taxi-out times, which combined produce the
            % Idle time. Notice that the times are in minutes
            time_Idle = 60*(september{f_in(k),37}+september{f_in(k),40});
            % Extracting the CCD cycle times, in minutes. Notice that we can take
            % the time from the september table and subtract the LTO times of
            % take-off, climb and approach
            time_CCD = september{f_in(k),53}-(time_Takeoff+time_Climb+time_Approach)/60;
            % Setting the FAA code
            FAA_code = eng_table{tail_in(k),6};
            % Setting the airplane type number of seats
            seats = eng_table{tail_in(k),5};
 
            % Performing the calculations
            [Total_CO2,Total_CO2e] = emissions_calc(FAA_code,airplane,time_Takeoff,time_Climb,time_Approach,time_Idle,time_CCD,lto_table,ccd_table,backup);
            Carbon_Footprint = Total_CO2e/seats;
            
            % Storing the emissions numbers
            emissions(1,icao_in) = emissions(1,icao_in) + Total_CO2;
            emissions(2,icao_in) = emissions(2,icao_in) + Total_CO2e;
            emissions(3,icao_in) = emissions(3,icao_in) + Carbon_Footprint;
            day_of_week(day,1) = day_of_week(day,1) + Total_CO2e;
            count = count + 1;
            
        end
        
    end
    disp(['Total CO2 produced by the route was equal to ',num2str(sum(emissions(1,:))),' kg'])
    disp(['Total CO2 equivalent produced by the route was equal to ',num2str(sum(emissions(2,:))),' kg'])
    disp(['Average Carbon Footprint of the route was equal to ',num2str(sum(emissions(3,:))/count),' kg of CO2e per passenger'])
    
    % Airline Specific Emissions
    disp('%--------------------------------------------------------------%')
    disp('Airline Specific Emissions')
    disp('%--------------------------------------------------------------%')
    for k = 1:length(rep_air)
        Airlines{k,1} = string(rep_air(k));
        code = find(string(rep_air(k))==air_code{:,1});
        Airlines{k,2} = string(air_code{code,2});
        disp('Airline = ')
        disp([string(Airlines{k,2}),string(Airlines{k,1})])
        disp(['Total CO2 produced was equal to ',num2str(emissions(1,k)),' kg'])
        disp(['Total CO2 equivalent produced was equal to ',num2str(emissions(2,k)),' kg'])
        disp(['Average Carbon Footprint was equal to ',num2str(emissions(3,k)/Airlines{k,3}),' kg of CO2e per passenger'])
        emissions(4,k) = 100*emissions(2,k)/sum(emissions(2,:)); % Recording Market Share per CO2e
        disp(['Market Share per CO2e = ',num2str(emissions(4,k)),'%'])
        disp('-o-o-o-o-o-o-o-o-')
        
    end
    
end 

    % Day Specific Emissions
    disp('%--------------------------------------------------------------%')
    disp('Day Specific Emissions')
    disp('%--------------------------------------------------------------%')
    disp(['Monday Total CO2e Emissions was equal to ',num2str(day_of_week(1,1)),' kg']);
    disp(['Monday Emissions Share ',num2str(100*day_of_week(1,1)/sum(day_of_week)),' %']);
    disp('-o-o-o-o-o-o-o-o-')
    disp(['Tuesday Total CO2e Emissions was equal to ',num2str(day_of_week(2,1)),' kg']);
    disp(['Tuesday Emissions Share ',num2str(100*day_of_week(2,1)/sum(day_of_week)),' %']);
    disp('-o-o-o-o-o-o-o-o-')
    disp(['Wednesday Total CO2e Emissions was equal to ',num2str(day_of_week(3,1)),' kg']);
    disp(['Wednesday Emissions Share ',num2str(100*day_of_week(3,1)/sum(day_of_week)),' %']);
    disp('-o-o-o-o-o-o-o-o-')
    disp(['Thursday Total CO2e Emissions was equal to ',num2str(day_of_week(4,1)),' kg']);
    disp(['Thursday Emissions Share ',num2str(100*day_of_week(4,1)/sum(day_of_week)),' %']);
    disp('-o-o-o-o-o-o-o-o-')
    disp(['Friday Total CO2e Emissions was equal to ',num2str(day_of_week(5,1)),' kg']);
    disp(['Friday Emissions Share ',num2str(100*day_of_week(5,1)/sum(day_of_week)),' %']);
    disp('-o-o-o-o-o-o-o-o-')
    disp(['Saturday Total CO2e Emissions was equal to ',num2str(day_of_week(6,1)),' kg']);
    disp(['Saturday Emissions Share ',num2str(100*day_of_week(6,1)/sum(day_of_week)),' %']);
    disp('-o-o-o-o-o-o-o-o-')
    disp(['Sunday Total CO2e Emissions ',num2str(day_of_week(7,1)),' kg']);
    disp(['Sunday Emissions Share ',num2str(100*day_of_week(7,1)/sum(day_of_week)),' %']);

