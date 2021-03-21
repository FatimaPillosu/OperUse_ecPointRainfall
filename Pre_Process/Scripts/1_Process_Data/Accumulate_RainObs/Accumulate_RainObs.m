clear 
clc

%INPUT PARAMETERS

RainST_FileName = 'ListStations.csv';
StartDate = '20181003';
EndDate = '20181005';
Acc = 12;
StartPeriod = [0,6,12,18];
WorkDir = '/perm/mo/mofp/PhD/Papers2Write/OperUse_ecPointRainfall'
InDir = 'Pre_Process/Raw_Data/OBS/IMN';
OutDir = 'Pre_Process/Processed_Data/OBS/IMN';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Importing the list of rain gauges
RainST_File = strcat(WorkDir, '/', InDir, '/', RainST_FileName);
RainST = importListStations(RainST_File); % CodeST=1,Lon=2, Lat=3


% Accumulating the observations in four 6-hourly periods per day
% from 00 to 06
% from 06 to 12
% from 12 to 18
% from 18 to 00 (of the following day)
disp(strcat("*** Accumulation of PPT observations over ", num2str(Acc), " hourly periods.***"))
StartDate = datetime(StartDate,'InputFormat','yyyyMMdd');
EndDate = datetime(EndDate,'InputFormat','yyyyMMdd');
for TheDate = StartDate : EndDate
    
    TheDateSTR = datestr(TheDate,'dd_mm_yyyy');
    disp(" ")
    disp(strcat("Post-Processing PPT observations for ", TheDateSTR))
    
    % Import the raw observations
    PPT_File = strcat(InDir, '/', TheDateSTR, '.csv');
    [Basin,Station,Date,Time,PPT] = importPPT(PPT_File);
    PPT_RainST = Basin * 1000 + Station;
    List_RainST = unique(PPT_RainST);
    
    Obs_6 = [];
    Obs_12 = [];
    Obs_18 = [];
    Obs_24 = [];
    
    for i = 1 : length(List_RainST)
        
        ST_temp = List_RainST(i);
        Time_temp = find(PPT_RainST==ST_temp);
        if length(Time_temp) == 24 % to check that all the hourly observations have been recorded
            
            % Identify location of station
            indST = find(RainST(:,1)==ST_temp);
            lon_temp = RainST(indST,2);
            lat_temp =RainST(indST,3);
            
            if ~isempty(lon_temp) && ~isempty(lat_temp) %there are no location recorded for certain gauges 
                
                lon_temp = lon_temp(1); % there are some gauges double counted
                lat_temp = lat_temp(1); % there are some gauges double counted
            
                % First 6-hourly period (00am to 6am, local time)
                ind_inf = 1;
                ind_sup = 6;
                Time_temp1 = Time_temp(ind_inf:ind_sup);
                PPT_acc = sum(PPT(Time_temp1));
                Obs_6 = [Obs_6; ST_temp, lon_temp, lat_temp, PPT_acc];
                
                % Second 6-hourly period (6am to 12am, local time)
                ind_inf = 7;
                ind_sup = 12;
                Time_temp1 = Time_temp(ind_inf:ind_sup);
                PPT_acc = sum(PPT(Time_temp1));
                Obs_12 = [Obs_12; ST_temp, lon_temp, lat_temp, PPT_acc];
                
                % Third 6-hourly period (12am to 6pm, local time)
                ind_inf = 13;
                ind_sup = 18;
                Time_temp1 = Time_temp(ind_inf:ind_sup);
                PPT_acc = sum(PPT(Time_temp1));
                Obs_18 = [Obs_18; ST_temp, lon_temp, lat_temp, PPT_acc];
                
                % Fourth 6-hourly period (6pm to 00am, local time)
                ind_inf = 19;
                ind_sup = 24;
                Time_temp1 = Time_temp(ind_inf:ind_sup);
                PPT_acc = sum(PPT(Time_temp1));
                Obs_24 = [Obs_24; ST_temp, lon_temp, lat_temp, PPT_acc];
                
                % Saving the four 6-hourly periods
                FileOut = strcat(WorkDir, '/', OutDir, "/", TheDateSTR, "_06.mat");
                PPT6 = Obs_6;
                save(FileOut,'PPT6')
                
                FileOut = strcat(WorkDir, '/', OutDir, "/", TheDateSTR, "_12.mat");
                PPT6 = Obs_12;
                save(FileOut,'PPT6')
                
                FileOut = strcat(WorkDir, '/', OutDir, "/", TheDateSTR, "_18.mat");
                PPT6 = Obs_18;
                save(FileOut,'PPT6')
                
                TheDate1STR = datestr(TheDate+1,'dd_mm_yyyy');
                FileOut = strcat(WorkDir, '/', OutDir, "/", TheDate1STR, "_00.mat");
                PPT6 = Obs_24;
                save(FileOut,'PPT6')
                
            end
            
        end
        
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Computing the four overlapping 12-hourly periods for the period of
% interest
clc

for TheDateS = StartDate : EndDate
    
    for indPer = 1 : length(StartPeriod)
        
        ThePerS = StartPeriod(indPer);
        ThePerF = ThePerS + 12;
        if ThePerF >= 24
            TheDateF = TheDateS + 1;
            ThePerF = ThePerF - 24;
        else
            TheDateF = TheDateS;
        end
        
        TheDateSSTR = datestr(TheDateS,'dd_mm_yyyy');
        TheDateFSTR = datestr(TheDateF,'dd_mm_yyyy');
        ThePerSSTR = num2str(ThePerS,'%0.2d');
        ThePerFSTR = num2str(ThePerF,'%0.2d');
        disp(" ")
        disp(strcat("Accumulating 12-h PPT between ", TheDateSSTR, " at ", ThePerSSTR, " and ", TheDateFSTR, " at ", ThePerFSTR))
        
        % Reading the files to compute the accumulated periods
        ThePerS1 = ThePerS + (Acc/2);
        TheDateS1 = TheDateS;
        if ThePerS1 == 24
            TheDateS1 = TheDateS + 1;
            ThePerS1 = 0;
        end
        TheDateS1STR = datestr(TheDateS1,'dd_mm_yyyy');
        ThePerS1STR = num2str(ThePerS1,'%0.2d');
        FileS = strcat(TheDateS1STR, "_", ThePerS1STR, ".mat");
        FileF = strcat(TheDateFSTR, "_", ThePerFSTR, ".mat");
        
        if exist(FileS) && exist (FileF)
            
            % Loading the 6-hourly PPTs
            disp(strcat("Reading ", FileS, "..."))
            disp(strcat("Reading ", FileF, "..."))
            load(FileS)
            temp1 = PPT6;
            load(FileF)
            temp2 = PPT6;
            
            % Checking that both 6-hourly periods have the same data;
            [temp,i1,i2] = intersect(temp1(:,1),temp2(:,1));
            temp1_def = temp1(i1,:);
            temp2_def = temp2(i2,:);
            
            % Adding the correspondent 6-h accumulations.
            PPT12 = temp1_def;
            PPT12(:,4) = temp1_def(:,4) + temp2_def(:,4);
            
            %Saving PPT12 in csv files
            TheDateF1STR = datestr(TheDateF,'yyyymmdd');
            FileOut = strcat(WorkDir, '/', OutDir, "/", "PPT12_", TheDateF1STR, "_", ThePerFSTR, ".csv");
            Headers = {'CodeST', 'Lon', 'Lat', 'PPT_mm'};
            T = array2table(PPT12,'VariableNames',Headers);
            writetable(T,FileOut)
        
        else
            
            disp("Data not available.")
        
        end
        
    end
    
end

% Remove temporary files
d=dir('*.mat');
for i = 1 : length(d)
    delete(d(i).name)
end