%% Group Analysis

% EXP means that the participant is receiving training on recognizing time 
% compressed sentences. ACT means that the participant is receiving training 
% on recognizing sentences in noise.

ValidStatus = "OK";

% TrainingMap matches naming convention from EEG file names with
% Participant Tracking spreadsheet
TrainingMap = ["TC" , "EXP"; ...
               "noTC", "EXP"];

ffnSubjectData = 'L:\Processed\P01\Aim 2\Aim 2 Participant Tracking.xlsx';
sheet = 'Summary_Study Dates';
range = 'A1:E36';

SubjectData = read_subject_data(ffnSubjectData,sheet,range);

ind = ismember([SubjectData.status],ValidStatus);
SubjectData(~ind) = [];


fn = fieldnames(SubjectData);

for i = 1:length(fn)
    uSD.(fn{i}) = unique([SubjectData.(fn{i})]);
end

disp(uSD)

groupFn = setdiff(fn,{'Subject','status'});
fprintf('Groups: %s\n',char(join(groupFn,', ')))



























