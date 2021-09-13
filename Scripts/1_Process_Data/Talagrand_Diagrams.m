clear
clc
%

% INPUT PARAMETERS
DateS = 20200601;
DateF = 20200831;
BaseTime = 0;
StepF = 108;
Acc = 12;
numENS = 99;
InDir = "/perm/mo/mofp/PhD/Papers2Write/OperUse_ecPointRainfall/Pre_Process/Processed_Data/OBS/OMSZ/ObjectiveVerif/NearestFC_ECMWFObs";
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Set some variables
DateS=datenum(num2str(DateS),"yyyymmdd");
DateF=datenum(num2str(DateF),"yyyymmdd");
BaseTimeSTR = sprintf("%02d", BaseTime);
StepFSTR = sprintf("%03d", StepF);
AccSTR = sprintf("%03d", Acc);
Bin = zeros(1,numENS-1+2);
mTot = 0;

% Create Talagrand diagrams
for BaseDate = DateS : DateF
    
    BaseDateSTR = datestr(BaseDate,"yyyymmdd");
    disp(BaseDateSTR)
    
    % Read the input observations and correspondent nearest forecasts
    FileName = strcat(InDir, "/NearestFC_", AccSTR, "_", BaseDateSTR, "_", BaseTimeSTR, "_", StepFSTR, ".csv");
    temp = import_OBS_NearestFC(FileName);
    obs = temp(:,1);
    fc = temp(:,2:end);
    [m,~] = size(fc);
    mTot = mTot + m;
    
    % Creating the Talagrand diagram
    for i = 1 : m
        obs_temp = obs(i);
        fc_temp = fc(i,:);
        pointer = find(fc_temp == obs_temp);
        n = length(pointer);
        if ~isempty(pointer) && (n==1)
            Bin(pointer+1) = Bin(pointer+1) + 1;
        elseif ~isempty(pointer) && (n>1)
            Bin(pointer) = Bin(pointer) + 1/n;
        else
            all = sort([obs_temp, fc_temp]);
            pointer = find(all == obs_temp);
            Bin(pointer) = Bin(pointer) + 1;
        end
        
    end
    
end
Bin = Bin./mTot;
    
% Plot the Talagrand diagram
bar(Bin)
ylim([0,0.1])
