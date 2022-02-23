%% Group Analysis

% EXP means that the participant is receiving training on recognizing time 
% compressed sentences. ACT means that the participant is receiving training 
% on recognizing sentences in noise.



ValidStatus = "OK";

modelDirection = -1; % 1: forward model; -1: backwards model

modelPathRoot = 'C:\Users\dstolz\Desktop\EEGData';

trainLUT = ["noTC" , "ACT"; "TC40" , "EXP"];


ffnSubjectData = 'L:\Processed\P01\Aim 2\Aim 2 Participant Tracking.xlsx';
sheet = 'Summary_Study Dates';
range = 'A1:E36';

SD = read_subject_data(ffnSubjectData,sheet,range);

% ind = ismember([SD.status],ValidStatus);
% SD(~ind) = [];


fn = fieldnames(SD);

for i = 1:length(fn)
    uSD.(fn{i}) = unique([SD.(fn{i})]);
end

disp(uSD)

groupFn = setdiff(fn,{'Subject','status'});
fprintf('Groups: %s\n',char(join(groupFn,', ')))



% load model data
fn = sprintf('mTRF_model_%d.mat',modelDirection);
ffn = fullfile(modelPathRoot,fn);

load(ffn,'model');

subjIdx = 1;
trainIdx = 4;

for i = 1:length(model)
    [~,fnEEG,~] = fileparts(model{i}.fnEEG);
    x = split(fnEEG,'_');
    x = string(x);

    xt = x(trainIdx);
    
    
    indLUT = contains(trainLUT(:,1),xt,'IgnoreCase',true);
    
    ind = [SD.Subject] == x(subjIdx) ...
        & [SD.Train] == trainLUT(indLUT,2);
    
%     if ~any(ind)
%         fprintf(2,'Unable to match "%s" with log data\n',fnEEG)
%         continue
%     end
    
    model{i}.Subject = SD(ind).Subject;
    model{i}.MCI     = SD(ind).has_MCI;
    model{i}.Age     = SD(ind).Age;
    model{i}.Train   = SD(ind).Train;
    model{i}.isOK    = SD(ind).status;
end


Data = cell2mat(model);

indBase = [Data.isOK] == "OK" & ~[Data.MCI];
for i = 1:length(uSD.Train)
    for j = 1:length(uSD.Age)
        ind = indBase & [Data.Train] == uSD.Train(i) ...
            & [Data.Age] == uSD.Age(j);
        
        w = {Data(ind).w};
    end
end












