%% Group Analysis

% EXP means that the participant is receiving training on recognizing time 
% compressed sentences. ACT means that the participant is receiving training 
% on recognizing sentences in noise.



ForegroundOrBackground = "Foreground";

% dataSuffix = 'DSS';
dataSuffix = 'CLEAN';

modelDirection = 1; % 1: forward model; -1: backwards model

modelPathRoot = 'C:\Users\dstolz\Desktop\EEGData';



ffnSubjectData = 'L:\Processed\P01\Aim 2\Aim 2 Participant Tracking.xlsx';
sheet = 'Summary_Study Dates';
range = 'A1:E36';

SD = read_subject_data(ffnSubjectData,sheet,range);


fn = fieldnames(SD);

for i = 1:length(fn)
    uSD.(fn{i}) = unique([SD.(fn{i})]);
end

disp(uSD)

groupFn = setdiff(fn,{'Subject','status'});
fprintf('Groups: %s\n',char(join(groupFn,', ')))



% load model data
fn = sprintf('mTRF_%s_%s_model_%d.mat',ForegroundOrBackground,dataSuffix,modelDirection);
ffn = fullfile(modelPathRoot,fn);

load(ffn,'model');

subjIdx = 1;
trainIdx = 4;

for i = 1:length(model)
    [~,fnEEG,~] = fileparts(model{i}.fnEEG);
    x = split(fnEEG,'_');
    x = string(x);

    xt = x(trainIdx);
    
        
    ind = [SD.Subject] == x(subjIdx); % & [SD.Train] == trainLUT(indLUT,2);
    
    model{i}.Subject = SD(ind).Subject;
    model{i}.MCI     = SD(ind).has_MCI;
    model{i}.Age     = SD(ind).Age;
    model{i}.Train   = SD(ind).Train;
    model{i}.status  = SD(ind).status;
    model{i}.TCcond  = x(trainIdx);
end


Data = cell2mat(model);


%
indBase = [Data.status] == "OK" & ~[Data.MCI];
for i = 1:length(uSD.Train) % "ACT" or "EXP"
    for j = 1:length(uSD.Age)
        ind = indBase ...
            & [Data.Train] == uSD.Train(i) ...
            & [Data.Age] == uSD.Age(j);
        
        fprintf('Age = "%s", Train = "%s"; Found %d\n',uSD.Age(j),uSD.Train(i),sum(ind))
        
        if ~any(ind), continue; end
        
        w = {Data(ind).w};
        
        w = cellfun(@(a) mean(a,3),w,'uni',0);
        w = cell2mat(w');
    end
end












