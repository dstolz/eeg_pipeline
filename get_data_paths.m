function [dataPaths,subjects] = get_data_paths(subjDir,subjDirStartCode,cndDirs,ext)
% [dataPaths,subjects] = get_data_paths(subjDir,[subjDirStartCode],[cndDirs],[ext])
% 
% ex input:
% subjDir = 'L:\Raw\P01\Aim 2\';
% subjDirStartCode = 'P01*';
% cndDirs = {'Cortical','Pre'};

% DJS 2/2022

narginchk(1,4);

if nargin < 2 || isempty(subjDirStartCode), subjDirStartCode = '*'; end
if nargin < 3 || isempty(cndDirs), cndDirs = '**\*'; end
if nargin < 4 || isempty(ext), ext = 'bdf'; end

cndDirs = cellstr(cndDirs);
    
subjs = dir(fullfile(subjDir,subjDirStartCode));

dataDirs = arrayfun(@(a) fullfile(a.folder,a.name,cndDirs{:}),subjs,'uni',0);

dataPaths = [];
for i = 1:length(dataDirs)
    d = dir(fullfile(dataDirs{i},[subjs(i).name '*.' ext]));
    dataPaths.(subjs(i).name) = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);   
end

subjects = {subjs.name}';