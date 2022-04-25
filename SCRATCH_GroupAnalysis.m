%% Group Analysis

% EXP means that the participant is receiving training on recognizing time
% compressed sentences.
% ACT means that the participant is receiving training on recognizing sentences in noise.

modelPathRoot = 'L:\Users\dstolz\EEGData_32\';


ForegroundOrBackground = "Foreground";

% dataSuffix = 'DSS';
dataSuffix = 'CLEAN';

% modelDirection = 1; % 1: forward model; -1: backwards model
modelDirection = -1;



ffnSubjectData = 'L:\Processed\P01\Aim 2\Aim 2 Participant Tracking.xlsx';
sheet = 'Summary_Study Dates';
range = 'A1:E36';

SD = read_subject_data(ffnSubjectData,sheet,range);


fn = fieldnames(SD);

for i = 1:length(fn)
    uSD.(fn{i}) = unique([SD.(fn{i})]);
end
uSD.Condition = ["Pre" "Post"];

disp(uSD)

fn = fieldnames(uSD);


groupFn = setdiff(fn,{'Subject','status'});
fprintf('Groups: %s\n',char(join(groupFn,', ')))


% load model data
fn = sprintf('mTRF_%s_%s_model_%d.mat',ForegroundOrBackground,dataSuffix,modelDirection);
ffn = fullfile(modelPathRoot,fn);

load(ffn,'model');

subjIdx = 1;
condIdx = 2;
trainIdx = 4;

badIdx = [];
for i = 1:length(model)
    
    if isempty(model{i}) || ~isfield(model{i},'train')
        badIdx = [badIdx, i];
        continue
    end
    
    info = model{i}.info;
    
    
    
    ind = [SD.Subject] == info(subjIdx); % & [SD.Train] == trainLUT(indLUT,2);
    
    model{i}.Subject = SD(ind).Subject;
    model{i}.MCI     = SD(ind).has_MCI;
    model{i}.Age     = SD(ind).Age;
    model{i}.Train   = SD(ind).Train;
    model{i}.status  = SD(ind).status;
    model{i}.TCcond  = info(trainIdx);
    model{i}.Condition = info(condIdx);
end
model(badIdx) = [];

Data = cell2mat(model);


%
f = figure(modelDirection+1000);
clf(f)
set(f,'color','w');
hold on
indBase = [Data.status] == "OK" & ~[Data.MCI];
for k = 1:length(uSD.Condition) % "Pre" or "Post"
    for i = 1:length(uSD.Train) % "ACT" or "EXP"
        for j = 1:length(uSD.Age)
            ind = indBase ...
                & [Data.Condition] == uSD.Condition(k) ...
                & [Data.Train] == uSD.Train(i) ...
                & [Data.Age] == uSD.Age(j);
            
            
            if ~any(ind), continue; end
            
            str = sprintf('%s-%s,%s,n=%d', ...
                uSD.Condition(k),uSD.Age(j),uSD.Train(i),sum(ind));
            
            %         w = {Data(ind).w};
            %
            %         w = cellfun(@(a) mean(a,3),w,'uni',0);
            %         w = cell2mat(w');
            %         mw = mean(w,1);
            
            train = [Data(ind).train];
            
            gfp = mean(cat(1,train.GFP));
            
            plot(train(1).t,gfp,'DisplayName',str);
        end
    end
end
hold off
legend
ylabel('GFP (a.u.)')
if modelDirection > 0
    title('EEG - forward model')
else
    title('Stimulus - reverse model')
end
axis tight
box on
grid on
xlabel('time (ms)')











