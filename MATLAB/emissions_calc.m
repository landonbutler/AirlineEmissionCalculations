%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Engine Emissions Calculator                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Total_CO2,Total_CO2e] = emissions_calc(FAA_code,airplane,time_Takeoff,time_Climb,time_Approach,time_Idle,time_CCD,lto_table,ccd_table,backup)

% Inputs:
% FAA_code: FAA engine code
% airplane: airplane type code
% time_Takeoff: time during take-off, in seconds
% time_Climb: time during climbing, in seconds
% time_Approach: time during approach and landing, in seconds
% time_Idle: time during taxi-in and taxi-out, in seconds
% time_CCD: time during cruising, in minutes
% lto_table: table containing emissions data for the LTO cycle
% ccd_table: table containing emissions data for the CCD cycle

% Outputs:
% Total_CO2: total amount of CO2 emitted
% Total_CO2e:total amount of CO2 equivalent emitted (including all other
% gases such as NOx, HC and CO)

% Carbon Equivalent Conversion Factors
CO_2_CO2 = 1.57;
HC_2_CO2 = 84;
NOx_2_CO2 = 298;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LTO Cycle Emissions Calculations                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Finding the lto_table entries corresponding to the desired FAA code
in = find(lto_table{:,2} == FAA_code);
l = length(in);

% If it happens that for some reason the engine FAA_code doesn't match with
% any of the ones we got, then we consider the following back-up
if isempty(in)
    in = find(backup{:,1} == airplane);
    l = length(in);
    FAA_code = backup{in,2};
    in = find(lto_table{:,2} == FAA_code);
    l = length(in);
end

% Using the indeces, we find the average value of the emissions for the
% particular engine type. For that, we first construct a smaller, 20-column 
% table, containing the following information in each column, as shown in
% the for loop below. Notice that the number next to each entry corresponds 
% to the column number from the excel table
lto_em_table = zeros(l,20);
% Filling the table up

for k = 1:l
    
    lto_em_table(k,1) = lto_table{in(k),11};  % [HC T/O (kg/s)] 11
    lto_em_table(k,2) = lto_table{in(k),14};  % [HC C/O (kg/s)] 14
    lto_em_table(k,3) = lto_table{in(k),17};  % [HC App (kg/s)] 17
    lto_em_table(k,4) = lto_table{in(k),20};  % [HC Idle (kg/s)] 20
    lto_em_table(k,5) = lto_table{in(k),24};  % [CO T/O (kg/s)] 24
    lto_em_table(k,6) = lto_table{in(k),27};  % [CO C/O (kg/s)] 27
    lto_em_table(k,7) = lto_table{in(k),30};  % [CO App (kg/s)] 30
    lto_em_table(k,8) = lto_table{in(k),33};  % [CO Idle (kg/s)] 33
    lto_em_table(k,9) = lto_table{in(k),37};  % [NOx T/O (kg/s)] 37
    lto_em_table(k,10) = lto_table{in(k),40}; % [NOx C/O (kg/s)] 40
    lto_em_table(k,11) = lto_table{in(k),43}; % [NOx App (kg/s)] 43
    lto_em_table(k,12) = lto_table{in(k),46}; % [NOx Idle (kg/s)] 46
    lto_em_table(k,13) = lto_table{in(k),49}; % [Fuel Flow T/O (kg/s)] 49
    lto_em_table(k,14) = lto_table{in(k),51}; % [Fuel Flow C/O (kg/s)] 51
    lto_em_table(k,15) = lto_table{in(k),53}; % [Fuel Flow App (kg/s)] 53
    lto_em_table(k,16) = lto_table{in(k),55}; % [Fuel Flow Idle (kg/s)] 55
    lto_em_table(k,17) = lto_table{in(k),58}; % [CO2 T/O (kg/s)] 58
    lto_em_table(k,18) = lto_table{in(k),60}; % [CO2 C/O (kg/s)] 60
    lto_em_table(k,19) = lto_table{in(k),62}; % [CO2 App (kg/s)] 62
    lto_em_table(k,20) = lto_table{in(k),64}; % [CO2 Idle (kg/s)] 64
    
    % Ask if there is any entry that has a NaN in it and replace it with a
    % 0 instead
    nan_in = find(isnan(lto_em_table(k,:)) == 1);
    lto_em_table(k,nan_in) = 0;
        
end

% After filling up the table, we can take the average value across each
% column (for the case where multiple engines correspond to the same FAA
% code):
lto_em = mean(lto_em_table,1);

% Now, it is possible to calculate the emissions from the LTO cycle. This
% is a simple calculation, that involves multiplying the specific LTO time
% by the emission factor from the "em" table
Total_HC_lto = time_Takeoff*lto_em(1) + time_Climb*lto_em(2) + time_Approach*lto_em(3) + time_Idle*lto_em(4);
Total_CO_lto = time_Takeoff*lto_em(5) + time_Climb*lto_em(6) + time_Approach*lto_em(7) + time_Idle*lto_em(8);
Total_NOx_lto = time_Takeoff*lto_em(9) + time_Climb*lto_em(10) + time_Approach*lto_em(11) + time_Idle*lto_em(12);
Total_Fuel_lto = time_Takeoff*lto_em(13) + time_Climb*lto_em(4) + time_Approach*lto_em(15) + time_Idle*lto_em(16);
Total_CO2_lto = time_Takeoff*lto_em(17) + time_Climb*lto_em(18) + time_Approach*lto_em(19) + time_Idle*lto_em(20);

% And having done this, it is possible to compute the total carbon
% equivalent emissions from all four types of gases combined. Recall from
% above that HC_2_CO2, CO_2_CO2 and NOx_2_CO2 are the conversion factors
% from the impact of HC, CO and NOx in terms of CO2, respectively. Overall,
% we get that:
Total_CO2e_lto = HC_2_CO2*Total_HC_lto + CO_2_CO2*Total_CO_lto + NOx_2_CO2*Total_NOx_lto + Total_CO2_lto;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CCD Cycle Emissions Calculations                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Finding the ccd_table entries corresponding to the desired airplane type
in2 = find(ccd_table{:,2} == airplane);
l2 = length(in2);

% Using the indeces, we construct a smaller, 9-column table, containing the 
% following information in each column, as shown in the for loop below. 
% Notice that the number next to each entry corresponds to the column 
% number from the excel table
ccd_em_table = zeros(l2,9);
% Filling the table up

for k = 1:l2
    
    ccd_em_table(k,1) = ccd_table{in2(k),8};  % [Distance (nm)] 8
    ccd_em_table(k,2) = ccd_table{in2(k),10};  % [Duration (min)] 10
    ccd_em_table(k,3) = ccd_table{in2(k),11};  % [Fuel (kg)] 11
    ccd_em_table(k,4) = ccd_table{in2(k),12};  % [CO2 (kg)] 12
    ccd_em_table(k,5) = ccd_table{in2(k),13};  % [NOx (kg)] 13
    ccd_em_table(k,6) = ccd_table{in2(k),14};  % [SOx (kg)] 14
    ccd_em_table(k,7) = ccd_table{in2(k),15};  % [H2O (kg)] 15
    ccd_em_table(k,8) = ccd_table{in2(k),16};  % [CO (kg)] 16
    ccd_em_table(k,9) = ccd_table{in2(k),17};  % [HC (kg)] 17
    
    % Ask if there is any entry that has a NaN in it and replace it with a
    % 0 instead
    nan_in = find(isnan(ccd_em_table(k,:)) == 1);
    ccd_em_table(k,nan_in) = 0;
        
end

% Now, it is possible to calculate the emissions from the CCD cycle. This
% is a simple interpolation calculation, that goes as follows. However, we 
% first need to find the interval in which the ccd time falls into. For
% that, we consider the following for loop:
interval = zeros(2,1);
for k = 1:(l2-1)
    
    % Ask whether the CCD time falls within some of the pre-established
    % time intervals
    if (ccd_em_table(k,2) < time_CCD) && (time_CCD < ccd_em_table(k+1,2))   
        interval(1) = k; % lower bound index
        interval(2) = k+1; % upper bound index
    end
       
end

% If it happens that the flight time is too small (less than the first
% index in the interpolation table), then we will set the emissions to be
% equal to the entry from the first intepolation time
if sum(interval) ~= 0
    % Now, it is possible to perform the linear interpolation:
    diff_t = ccd_em_table(interval(2),2) - ccd_em_table(interval(1),2);
    diff_Fuel = ccd_em_table(interval(2),3) - ccd_em_table(interval(1),3);
    diff_CO2 = ccd_em_table(interval(2),4) - ccd_em_table(interval(1),4);
    diff_NOx = ccd_em_table(interval(2),5) - ccd_em_table(interval(1),5);
    diff_SOx = ccd_em_table(interval(2),6) - ccd_em_table(interval(1),6);
    diff_H2O = ccd_em_table(interval(2),7) - ccd_em_table(interval(1),7);
    diff_CO = ccd_em_table(interval(2),8) - ccd_em_table(interval(1),8);
    diff_HC = ccd_em_table(interval(2),9) - ccd_em_table(interval(1),9);

    Total_Fuel_ccd = (diff_Fuel/diff_t)*(time_CCD-ccd_em_table(interval(1),2)) + ccd_em_table(interval(1),3);
    Total_CO2_ccd = (diff_CO2/diff_t)*(time_CCD-ccd_em_table(interval(1),2)) + ccd_em_table(interval(1),4);
    Total_NOx_ccd = (diff_NOx/diff_t)*(time_CCD-ccd_em_table(interval(1),2)) + ccd_em_table(interval(1),5);
    Total_SOx_ccd = (diff_SOx/diff_t)*(time_CCD-ccd_em_table(interval(1),2)) + ccd_em_table(interval(1),6);
    Total_H2O_ccd = (diff_H2O/diff_t)*(time_CCD-ccd_em_table(interval(1),2)) + ccd_em_table(interval(1),7);
    Total_CO_ccd = (diff_CO/diff_t)*(time_CCD-ccd_em_table(interval(1),2)) + ccd_em_table(interval(1),8);
    Total_HC_ccd = (diff_HC/diff_t)*(time_CCD-ccd_em_table(interval(1),2)) + ccd_em_table(interval(1),9);
else
    % This is the case where the flight time is too small
    Total_Fuel_ccd = ccd_em_table(1,3);
    Total_CO2_ccd = ccd_em_table(1,4);
    Total_NOx_ccd = ccd_em_table(1,5);
    Total_SOx_ccd = ccd_em_table(1,6);
    Total_H2O_ccd = ccd_em_table(1,7);
    Total_CO_ccd = ccd_em_table(1,8);
    Total_HC_ccd = ccd_em_table(1,9);
end
% And having done this, it is possible to compute the total carbon
% equivalent emissions from all the types of gases combined. Recall from
% above that HC_2_CO2, CO_2_CO2 and NOx_2_CO2 are the conversion factors
% from the impact of HC, CO and NOx in terms of CO2, respectively. Overall,
% we get that:
Total_CO2e_ccd = HC_2_CO2*Total_HC_ccd + CO_2_CO2*Total_CO_ccd + NOx_2_CO2*Total_NOx_ccd + Total_CO2_ccd;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Overall Engine Emissions                                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Total_CO2 = Total_CO2_lto + Total_CO2_ccd;
Total_CO2e = Total_CO2e_lto + Total_CO2e_ccd;