%% Required toolboxes:
% fieldtrip (good idea to run ft_defaults first)
% eeg_pipeline (mine)

%% EEG PREPROCESSING PIPELINE
% 1.  PREPROCESS
% 2.  CONCATENATE DATA
% 3A. DENOISING
% 3B. SELECT NOISY COMPONENTS
% 3C. REMOVE ARTIFACTUAL COMPONENTS
% 4.  COMPUTE DSS COMPONENTS BEFORE RECONSTRUCTION


%%  Required variables

subjDir = 'L:\Raw\P01\Aim 2\';
outPathRoot = 'C:\Users\dstolz\Desktop\EEGData';
skipCompleted = true;

%% 1. PREPROCESS

subjDirStartCode = 'P01*';

% cndDirs = {'Cortical','Pre'};
cndDirs = {'Cortical','Post'};

skipFileCode = {'Rest','rest'}; % exclude some sessions with this in its filename





pathToPreprocessed = fullfile(outPathRoot,'PREPROCESSED');

cfg_Preprocess.definetrial = [];
cfg_Preprocess.definetrial.trialdef.eventtype  = 'STATUS';
cfg_Preprocess.definetrial.trialdef.eventvalue = [3 4];

cfg_Preprocess.resample = [];
cfg_Preprocess.resample.resamplefs = 256;


cfg_Preprocess.preprocessing = [];
cfg_Preprocess.preprocessing.reref = 'yes';
cfg_Preprocess.preprocessing.refchannel = {'A1' 'A2'};
cfg_Preprocess.preprocessing.detrend = 'yes';
cfg_Preprocess.preprocessing.bpfreq = [2 35]; %[1 120];
cfg_Preprocess.preprocessing.bpfilter = 'yes';

[dataPaths,subjs] = get_data_paths(subjDir,subjDirStartCode,cndDirs,'bdf',skipFileCode);
fprintf('Data from %d subjects will be processed\n',length(subjs))

st = tic;
for s = 1:length(subjs)
    curSubj = char(subjs(s));
    fprintf('\n%s\nProcessing Subject %d of %d: "%s"\n',repmat('~',1,50),s,length(subjs),curSubj)
    ffn = dataPaths.(curSubj);
    
    for i = 1:length(ffn)
        
        try
            [~,inFn,~] = fileparts(ffn{i});
            outFfn = fullfile(pathToPreprocessed,[inFn '.mat']);
            
            if skipCompleted && exist(outFfn,'file')
                fprintf(2,'File exists, skipping ... "%s"\n',outFfn)
                continue
            end
            
            cfg_Preprocess.definetrial.headerfile = ffn{i};
            cfg_Preprocess.definetrialOut = ft_definetrial(cfg_Preprocess.definetrial);
            
            cfg_Preprocess.definetrialOut.trl = [cfg_Preprocess.definetrialOut.trl(:,1)', 0]; % reconjigure trial samples for onset/offset timing from separate events [3 4]
            
            data = ft_preprocessing(cfg_Preprocess.definetrialOut);
            
            oldFs = data.fsample;
            
            data = ft_resampledata(cfg_Preprocess.resample,data);
            
            data = ft_preprocessing(cfg_Preprocess.preprocessing,data);
            
            if ~isfolder(fileparts(outFfn)), mkdir(fileparts(outFfn)); end
            
            fprintf('Saving "%s" ...',outFfn)
            save(outFfn,'data');
            fprintf(' done\n')
            
        catch me
            fprintf(2,'ERROR!\n')
        end
    end
end
fprintf('Total preprocessing time = %.1f minutes\n',toc(st)/60)




%% 2. CONCATENATE DATA
%  Note this will currently only work with single trial data
%  Also, channels are assumed to be in the same order for all files

pathOut = fullfile(outPathRoot,'MERGED');

orderTokenIdx = 5;
delimiter = "_";

pathToPreprocessed = fullfile(outPathRoot,'PREPROCESSED');

toBeMerged = merge_data_files(pathToPreprocessed,'mat',orderTokenIdx,[],delimiter);


if ~isfolder(pathOut), mkdir(pathOut); end

fprintf('Will merge %d groups of files\n',length(toBeMerged))
for i = 1:length(toBeMerged)
    fprintf('\nMerging %d of %d groups\n',i,length(toBeMerged))
    
    if numel(toBeMerged{i}) < 2
        fprintf(2,'\tMulitple files not found. No merging performed for this file!\n')
        continue
    end
    
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
    s(1,orderTokenIdx) = join(s(:,orderTokenIdx)',"_");
    fnOut = join(s(1,:),delimiter);
    fnOut = fnOut + "_MERGED.mat";
    ffnOut = fullfile(pathOut,fnOut);
    
    if skipCompleted && exist(ffnOut,'file')
        fprintf('\tMerged file already exists, skippping: %s\n',fnOut)
        continue
    end
    
    fprintf('\tSaving "%s" ...',fnOut)
    save(ffnOut,'data');
    fprintf(' done\n')
end

%% 3A. DENOISING
% Use ICA to find artifacts and then remove in 3B
% Jung, et al, 2000, Psychophysiology, https://doi.org/10.1111/1469-8986.3720163

pthIn  = fullfile(outPathRoot,'MERGED');
pthOut = fullfile(outPathRoot,'MERGED_COMP');

chExclude = {'-Status','-EXG*'}; % include EOG channels

cfg = [];
% cfg.method = 'pca';

cfg.method = 'fastica';
cfg.fastica.numOfIC = 'all';
cfg.fastica.maxNumIterations = 250;

d = dir(fullfile(pthIn,'*MERGED.mat'));


pthOut = [pthOut '_' cfg.method];

if ~isfolder(pthOut), mkdir(pthOut); end
t = tic;


c = repmat('*',1,50);
for i = 1:length(d)
    fprintf('\n%s\n\t%d of %d: %s\n%s\n',c,i,length(d),d(i).name,c)
    
    ffnIn = fullfile(d(i).folder,d(i).name);
    
    
    if i == 1
        load(ffnIn,'data');
        cfg.channel = ft_channelselection({'all',chExclude{:}},data.label); %#ok<CCAT>
    end
    
    [~,fnOut,~] = fileparts(ffnIn);
    ffnOut = fullfile(pthOut,[fnOut '_COMP_' cfg.method '.mat']);
    
    
    if skipCompleted && exist(ffnOut,'file')
        fprintf(2,'\tFile already exists, skippping: %s\n',fnOut)
        continue
    end
    
    cfg.inputfile  = ffnIn;
    cfg.outputfile = ffnOut;
    ft_componentanalysis(cfg);
end
fprintf('Completed processing %d files in %.1f minutes\n',length(d),toc(t)/60)

%% 3B. SELECT NOISY COMPONENTS
% Visualize and select artifactual components for removal. Reconstruction in 3C.

pthIn = fullfile(outPathRoot,'MERGED_COMP');


cfg = [];
cfg.layout = 'biosemi64.lay';
cfg.ylim = [-1 1]*150;
cfg.viewmode = 'component';
cfg.comment = 'no';
cfg.blocksize = 30;
cfg.channel = 1:16;
% cfg.preproc.hilbert = 'abs';




d = dir(fullfile(pthIn,'*COMP.mat'));

if skipCompleted
    ind = arrayfun(@(a) exist(fullfile(a.folder,[a.name(1:end-4) '_ARTIFACTS.txt']),'file')==2,d);
    fprintf(2,'Skipping %d existing artifact component files\n',sum(ind))
    d(ind) = [];
end

c = repmat('*',1,50);
for i = 1:length(d)
    fprintf('\n%s\n\t%d of %d: %s\n%s\n',c,i,length(d),d(i).name,c)
    
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
    set(gcf,'name',d(i).name,'WindowState','maximized')
    waitfor(gcf)
    pause(1)
end

%% 3C(option 1). REMOVE ARTIFACTUAL COMPONENTS

pthInData = fullfile(outPathRoot,'MERGED');
pthInComp = fullfile(outPathRoot,'MERGED_COMP');
pthOut    = fullfile(outPathRoot,'MERGED_CLEAN');

delComps = 1;

da = dir(fullfile(pthInComp,'*ARTIFACTS.txt'));

if ~isfolder(pthOut), mkdir(pthOut); end

for i = 1:length(da)
    
    ffnCompArt = fullfile(da(i).folder,da(i).name);
    fid = fopen(ffnCompArt,'r');
    fgetl(fid); % discard header line
    c = fgetl(fid);
    fclose(fid);
    
    if isequal(c,-1)
        fprintf('No components marked as artifact for "%s"\n',da(i).name)
        continue
    end
    c = str2num(c); %#ok<ST2NM>
    
    t = textscan(da(i).name,'%s','delimiter','_');
    
    fnComp = join(string(t{1}(1:end-1)),'_');
    fnData = join(string(t{1}(1:end-2)),'_');
    
    load(fullfile(fileparts(da(i).folder),"MERGED",fnData+".mat"),'data');
    load(fullfile(da(i).folder,fnComp+".mat"),'comp');
    
    fn = join(string(t{1}(1:end-3)),'_');
    fnOut = fn + "_CLEAN.mat";
    
    cfg = [];
    cfg.outputfile = char(fullfile(pthOut,fnOut));
    cfg.component = c;
    data_clean = ft_rejectcomponent(cfg,comp,data);
end

%% 3C(option 2). AUTOREMOVE ARTIFACTUAL COMPONENTS

pthInData = fullfile(outPathRoot,'MERGED');
pthInComp = fullfile(outPathRoot,'MERGED_COMP');
pthOut    = fullfile(outPathRoot,'MERGED_CLEAN');

delComps = 1;

da = dir(fullfile(pthInComp,'*COMP.mat'));

if ~isfolder(pthOut), mkdir(pthOut); end

for i = 1:length(da)
    t = split(da(i).name,'_');
    
    fnData = join(string(t(1:end-2)),'_')+"_MERGED";
    
    load(fullfile(fileparts(da(i).folder),"MERGED",fnData+".mat"),'data');
    load(fullfile(da(i).folder,da(i).name),'comp');
    
    fn = join(string(t(1:end-2)),'_');
    fnOut = fn + "_CLEAN.mat";
    
    cfg = [];
    cfg.outputfile = char(fullfile(pthOut,fnOut));
    cfg.component = delComps;
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

pthIn  = fullfile(outPathRoot,'MERGED_CLEAN');
pthOut = fullfile(outPathRoot,'MERGED_DSS');

chExclude = {'-Status','-*EOG','-EXG*','-A1','-A2'};

cfg = [];
cfg.method = 'dss';

d = dir(fullfile(pthIn,'*CLEAN.mat'));

if ~isfolder(pthOut), mkdir(pthOut); end
t = tic;

c = repmat('*',1,50);
for i = 1:length(d)
    fprintf('\n%s\n\t%d of %d: %s\n%s\n',c,i,length(d),d(i).name,c)
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












%% log off windows after finished

system('shutdown -L')

