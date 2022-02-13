%%
addpath('G:\My Drive\AUD\Classes\Independent Study\myCode')
addpath('c:\Users\Daniel\src\fieldtrip\')


%% 1. PREPROCESS

subjDir = 'C:\Users\Daniel\Desktop\EEGTestData';
% subjDir = 'L:\Raw\P01\Aim 2\';

pathToPreprocessed = fullfile(subjDir,'FTDATA');


subjDirStartCode = 'P01*';
cndDirs = {'Cortical','Pre'};

newFs = 512;

skipCompleted = true;

cfg.definetrial = [];
cfg.definetrial.trialdef.eventtype  = 'STATUS';
cfg.definetrial.trialdef.eventvalue = [3 4];

cfg.resample = [];
cfg.resample.resamplefs = newFs;


cfg.preprocessing = [];
cfg.preprocessing.reref = 'yes';
cfg.preprocessing.refchannel = {'A1' 'A2'};
cfg.preprocessing.detrend = 'yes';
cfg.preprocessing.bpfreq = [1 120];
cfg.preprocessing.bpfilter = 'yes';

[dataPaths,subjs] = get_data_paths(subjDir,subjDirStartCode,cndDirs,'bdf');
fprintf('Data from %d subjects will be processed\n',length(subjs))

st = tic;
for s = 1:length(subjs)
    curSubj = char(subjs(s));
    fprintf('\n%s\nProcessing Subject %d of %d:"%s"\n',repmat('~',1,50),s,length(subjs),curSubj)
    ffn = dataPaths.(curSubj);
    
    for i = 1:length(ffn)
        
        [~,inFn,~] = fileparts(ffn{i});
        outFfn = fullfile(pathToPreprocessed,[inFn '.mat']);
        
        if skipCompleted && exist(outFfn,'file')
            fprintf(2,'File exists, skipping ... "%s"\n',outFfn)
            continue
        end
        
        cfg.definetrial.headerfile = ffn{i};
        cfg.definetrialOut = ft_definetrial(cfg.definetrial);
        
        cfg.definetrialOut.trl = [cfg.definetrialOut.trl(:,1)', 0]; % reconjigure trial samples for onset/offset timing from separate events [3 4]
        
        data = ft_preprocessing(cfg.definetrialOut);
        
        oldFs = data.fsample;
        
        data = ft_resampledata(cfg.resample,data);
        
        data = ft_preprocessing(cfg.preprocessing,data);
        
        if ~isfolder(fileparts(outFfn)), mkdir(fileparts(outFfn)); end
        
        fprintf('Saving "%s" ...',outFfn)
        save(outFfn,'data');
        fprintf(' done\n')
    end
end
fprintf('Total preprocessing time = %.1f minutes\n',toc(st)/60)




%% 2. CONCATENATE DATA
%  Note this will currently only work with single trial data
%  Also, channels are assumed to be in the same order for all files

pathToPreprocessed = 'C:\Users\Daniel\Desktop\EEGTestData\FTDATA';
pathOut = 'C:\Users\Daniel\Desktop\EEGTestData\FTDATA_MERGED';

orderTokenIdx = 5;
delimiter = "_";
toBeMerged = merge_data_files(pathToPreprocessed,'mat',orderTokenIdx,[],delimiter);


if ~isfolder(pathOut), mkdir(pathOut); end

fprintf('Will merge %d groups of files\n',length(toBeMerged))
for i = 1:length(toBeMerged)
    fprintf('\nMerging %d of %d groups\n',i,length(toBeMerged))
    
    data = [];
    fn = cell(size(toBeMerged{i}));
    for j = 1:length(toBeMerged{i})
        [~,fn{j},~] = fileparts(toBeMerged{i}{j});
        fprintf('\t> %d/%d: "%s" ...',j,length(toBeMerged{i}),fn{j})
        if j == 1
            load(toBeMerged{i}{j},'data');
        else
            m = load(toBeMerged{i}{j},'data');
            data.trial = {[data.trial{1}, m.data.trial{1}]};
        end
        fprintf(' done\n')
    end
    
    data.time  = {(0:length(data.trial{1})-1.)/data.fsample};
    data.sampleinfo = [1 length(data.time{1})];
    
    
    s = string(split(fn,delimiter));
    s(1,orderTokenIdx) = join(s(:,orderTokenIdx)',"-");
    fnOut = join(s(1,:),delimiter);
    fnOut = fnOut + "_MERGED.mat";
    ffnOut = fullfile(pathOut,fnOut);
    
    fprintf('\tSaving "%s" ...',fnOut)
    save(ffnOut,'data');
    fprintf(' done\n')
end

%% 3A. DENOISING
% Use PCA or ICA to find artifacts and then remove

pthIn  = 'C:\Users\Daniel\Desktop\EEGTestData\FTDATA_MERGED';
pthOut = 'C:\Users\Daniel\Desktop\EEGTestData\FTDATA_MERGED_COMP';

chExclude = {'-Status','-*EOG','-EXG*','-A1','-A2'};

cfg = [];
cfg.method = 'varimax';
% cfg.method = 'pca';
% cfg.method = 'dss';
% cfg.method = 'fastica';
% cfg.fastica.numOfIC = 'all';
% cfg.fastica.maxNumIterations = 100;

d = dir(fullfile(pthIn,'*MERGED.mat'));

if ~isfolder(pthOut), mkdir(pthOut); end
t = tic;
for i = 1:length(d)
    ffnIn = fullfile(d(i).folder,d(i).name);
    if i == 1
        load(ffnIn,'data');
        cfg.channel = ft_channelselection({'all',chExclude{:}},data.label); %#ok<CCAT>
    end
    
    [~,fnOut,~] = fileparts(ffnIn);
    ffnOut = fullfile(pthOut,[fnOut '_COMP.mat']);

    cfg.inputfile  = ffnIn;
    cfg.outputfile = ffnOut;
    ft_componentanalysis(cfg);
end
fprintf('Completed processing %d files in %.1f minutes\n',length(d),toc(t)/60)

%% 3B. SELECT NOISY COMPONENTS
% Visualize components for denoising

pthIn = 'C:\Users\Daniel\Desktop\EEGTestData\FTDATA_MERGED_COMP';

d = dir(fullfile(pthIn,'*COMP.mat'));

cfg = [];
cfg.layout = 'biosemi64.lay';
% cfg.ylim = [-75 75];
cfg.viewmode = 'component';
cfg.blocksize = 30;
cfg.channel = 1:16;
% cfg.preproc.hilbert = 'abs';

c = repmat('*',1,50);
for i = 1:length(d)
    fprintf('\n%s\n\t%s\n%s\n',c,d(i).name,c)
    
    [~,fnIn,~] = fileparts(d(i).name);
    
    fnCompArt  = [fnIn '_ARTIFACTS.txt'];
    ffnCompArt = fullfile(pthIn,fnCompArt);
    
    fid = fopen(ffnCompArt,'wt');
    fprintf(fid,'%s\n',fnIn);
    fclose(fid);
    winopen(ffnCompArt);
    fprintf('Enter artifact channels: <a href = "matlab:winopen(''%s'')">%s</a>\n', ...
        ffnCompArt,fnCompArt)
    
    load(fullfile(d(i).folder,d(i).name));
    ft_databrowser(cfg,comp);
    set(gcf,'name',d(i).name)
    waitfor(gcf)
    pause(1)
end

%% 3C. Remove selected components
pthInData = 'C:\Users\Daniel\Desktop\EEGTestData\FTDATA_MERGED';
pthInComp = 'C:\Users\Daniel\Desktop\EEGTestData\FTDATA_MERGED_COMP';
pthOut    = 'C:\Users\Daniel\Desktop\EEGTestData\FTDATA_MERGED_CLEAN';

dd = dir(fullfile(pthInData,'*MERGED.mat'));
dc = dir(fullfile(pthInComp,'*COMP.mat'));
da = dir(fullfile(pthInComp,'*ARTIFACTS.txt'));

if ~isfolder(pthOut), mkdir(pthOut); end

for i = 1:length(dc)
    
    ffnCompArt = fullfile(da(i).folder,da(i).name);
    fid = fopen(ffnCompArt,'r');
    c = textscan(fid,'%d', ...
        'Delimiter',',', ...
        'Headerlines',1, ...
        'CollectOutput',true, ...
        'EndOfLine','\r\n');
    fclose(fid);
    
    c = c{1}';
    
    
    load(fullfile(dd(i).folder,dd(i).name),'data');
    load(fullfile(dc(i).folder,dc(i).name),'comp');
    
    [~,fn,~] = fileparts(dd(i).name);
    fnOut = [fn '_CLEAN.mat'];
    
    cfg = [];
    cfg.outputfile = fullfile(pthOut,fnOut);
    cfg.component = c;
    data_clean = ft_rejectcomponent(cfg,comp,data);
end

%% Visualize cleaned data
cfg = [];
cfg.layout = 'biosemi64.lay';
cfg.blocksize = 30;
cfg.channel = ft_channelselection({'all','-Status','-*EOG','-EXG*','-A1','-A2'},data.label);
ft_databrowser(cfg,data);


%% 4. COMPUTE DSS COMPONENTS BEFORE RECONSTRUCTION
% Use PCA or ICA to find artifacts and then remove

pthIn  = 'C:\Users\Daniel\Desktop\EEGTestData\FTDATA_MERGED_CLEAN';
pthOut = 'C:\Users\Daniel\Desktop\EEGTestData\FTDATA_MERGED_DSS';

chExclude = {'-Status','-*EOG','-EXG*','-A1','-A2'};

cfg = [];
cfg.method = 'dss';

d = dir(fullfile(pthIn,'*CLEAN.mat'));

if ~isfolder(pthOut), mkdir(pthOut); end
t = tic;
for i = 1:length(d)
    ffnIn = fullfile(d(i).folder,d(i).name);
    if i == 1
        load(ffnIn,'data');
        cfg.channel = ft_channelselection({'all',chExclude{:}},data.label); %#ok<CCAT>
    end
    
    [~,fnOut,~] = fileparts(ffnIn);
    ffnOut = fullfile(pthOut,[fnOut '_DSS.mat']);

    cfg.inputfile  = ffnIn;
    cfg.outputfile = ffnOut;
    ft_componentanalysis(cfg);
end
fprintf('Completed processing %d files in %.1f minutes\n',length(d),toc(t)/60)





%% Visualize DSS data
cfg = [];
cfg.layout = 'biosemi64.lay';
cfg.blocksize = 30;
cfg.channel = 1:10;
ft_databrowser(cfg,comp);












