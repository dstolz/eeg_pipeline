%% Required toolboxes:
% fieldtrip (good idea to run ft_defaults first)
% eeg_pipeline (mine)

%% EEG PREPROCESSING PIPELINE
% 1.  PREPROCESS
% 2.  CONCATENATE DATA
% 3A. ICA DENOISING
% 3B. PREGENERATE TOPOGRAPHIC MAPS OF COMPONENTS
% 3C. VISUALLY MARK AND CLEAN ARTIFACTUAL COMPONENTS
% 4.  COMPUTE DSS COMPONENTS BEFORE RECONSTRUCTION


%%  Required variables

subjDir = 'L:\Raw\P01\Aim 2\';
outPathRoot = 'L:\Users\dstolz\EEGData_32\';

skipCompleted = true;

%% 1. PREPROCESS

subjDirStartCode = 'P01*';

cndDirs = {'Cortical','Pre'};
% cndDirs = {'Cortical','Post'};

skipFileCode = {'Rest','rest'}; % exclude some sessions with this in its filename


pathToPreprocessed = fullfile(outPathRoot,'PREPROCESSED');

cfg_Preprocess.definetrial = [];
cfg_Preprocess.definetrial.trialdef.eventtype  = 'STATUS';
cfg_Preprocess.definetrial.trialdef.eventvalue = [3 4];

cfg_Preprocess.resample = [];
cfg_Preprocess.resample.resamplefs = 32;
% cfg_Preprocess.resample.resamplefs = 256;


cfg_Preprocess.preprocessing = [];
cfg_Preprocess.preprocessing.reref = 'yes';
cfg_Preprocess.preprocessing.refchannel = {'A1' 'A2'};
cfg_Preprocess.preprocessing.detrend = 'yes';
% cfg_Preprocess.preprocessing.bpfreq = [2 35]; %[1 120];
cfg_Preprocess.preprocessing.bpfreq = [1 14];
cfg_Preprocess.preprocessing.bpfilter = 'yes';

eeg_preamble

[dataPaths,subjs] = get_data_paths(subjDir,subjDirStartCode,cndDirs,'bdf',skipFileCode);
fprintf('Data from %d subjects will be processed\n',length(subjs))

if ~isfolder(outPathRoot), mkdir(outPathRoot); end

st = tic;
for s = 1:length(subjs)
    curSubj = char(subjs(s));
    ffn = dataPaths.(curSubj);
    
    fprintf('\n%s\nProcessing Subject %d of %d: "%s"\n\t%d files found\n',repmat('~',1,50),s,length(subjs),curSubj,length(ffn))

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
            clear data
        catch me
            fprintf(2,'ERROR!\n%s\n%s\n\n',me.identifier,me.message)
        end
    end
end
fprintf('Total preprocessing time = %.1f minutes\n',toc(st)/60)




%% 2. CONCATENATE DATA
%  Note this will currently only work with single trial data
%  Also, channels are assumed to be in the same order for all files

pathOut = fullfile(outPathRoot,'MERGED');


remArtifactStdThr = 50; % # std threshold; 0 or empty to not threshold

orderTokenIdx = 5;

pathToPreprocessed = fullfile(outPathRoot,'PREPROCESSED');

toBeMerged = merge_data_files(pathToPreprocessed,orderTokenIdx);

eeg_preamble
if ~isfolder(pathOut), mkdir(pathOut); end

fprintf('Will attempt to merge %d groups of files\n',length(toBeMerged))
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
    
    
    if ~isempty(remArtifactStdThr) && remArtifactStdThr > 0
        cfg_art = [];
        cfg_art.channel = ft_channelselection({'all','-Status','-*EOG','-EXG*'},data.label);
        data = ft_selectdata(cfg_art,data);
        
        data_std = std(data.trial{1},[],2);
        
        [ci,bs] = bootci(1000,{@mean,data_std},'alpha',.025);
        ind = data_std > ci(2) & data_std > remArtifactStdThr;
        
        fprintf('outliers: %d;\t97.5%% CI = %.1f\n',sum(ind),ci(2))
        idx = find(ind);
        fprintf('\tCh. Label\tStd\n')
        for k = 1:length(idx)
            fprintf('\t%-2d. %-3s \t%.2f\n',idx(k),data.label{idx(k)},data_std(idx(k)))
        end
        
        artLabel = cellfun(@(a) ['-' a],data.label(ind),'uni',0);
        
        cfg_art = [];
        cfg_art.channel = ft_channelselection({'all',artLabel{:},'-Status','-EXG*'},data.label); %#ok<CCAT>

        data = ft_selectdata(cfg_art,data);
    end
    
    
    
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

chExclude = {'-Status','-EXG*'}; % include non-signal channels

cfg = [];

% cfg.method = 'runica';
cfg.method = 'fastica';

d = dir(fullfile(pthIn,'*MERGED.mat'));

eeg_preamble

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
        fprintf(2,'File already exists, skippping: %s\n',fnOut)
        continue
    end
    
    cfg.inputfile  = ffnIn;
    cfg.outputfile = ffnOut;
    ft_componentanalysis(cfg);
end
fprintf('Completed processing %d files in %.1f minutes\n',length(d),toc(t)/60)




%% 3B. PREGENERATE TOPOGRAPHIC MAPS FOR VISUAL REJECTION OF ARTIFACTUAL COMPONENTS

eeg_preamble

compMethod = 'fastica';
% compMethod = 'runica';

cfg = [];
cfg.layout  = 'biosemi64.lay';
cfg.marker  = 'off';
cfg.shading = 'interp';
cfg.style   = 'straight';
cfg.comment = 'no';
cfg.title   = 'auto';

pthIn  = fullfile(outPathRoot,sprintf('MERGED_COMP_%s',compMethod));
pthOut = fullfile(outPathRoot,'MERGED_CLEAN');
pthFig = fullfile(outPathRoot,'MERGED_COMP_TOPOFIG');

if ~isfolder(pthOut), mkdir(pthOut); end
if ~isfolder(pthFig), mkdir(pthFig); end

d = dir(fullfile(pthIn,sprintf('*COMP_%s.mat',compMethod)));

for i = 1:length(d)
    ffn = fullfile(d(i).folder,d(i).name);
    fnOut = [d(i).name(1:end-4) '_CLEAN.mat'];
    ffnOut = fullfile(pthOut,fnOut);
    
    fnFig = [d(i).name(1:end-4) '_TOPOFIG.fig'];
    ffnFig = fullfile(pthFig,fnFig);
    
    
    if skipCompleted && exist(ffnFig,'file')
        fprintf(2,'\tTopographic figure file already exists, skippping: %s\n',fnOut)
        continue
    end
    
    % create placeholder ffnFig
    f = figure('WindowState','Maximized');
    savefig(f,ffnFig);

    
    fprintf('\n%d/%d. Loading components data from "%s" ...',i,length(d),d(i).name)
    load(ffn,'comp');
    fprintf(' done\n')
    
    cfg.component = 1:length(comp.label);
    
    
    ft_warning off FieldTrip:getdimord:warning_dimord_could_not_be_determined
    ft_topoplotIC(cfg,comp)
    ft_warning on FieldTrip:getdimord:warning_dimord_could_not_be_determined
        
    f.CreateFcn = @gui_toggle_component;

    h = findobj(f,'-property','ButtonDownFcn');
    set(h,'ButtonDownFcn',@gui_toggle_component);
    ax = findobj(f,'type','axes');
    
    f.CloseRequestFcn = @gui_clean_components;
    f.Name = d(i).name;
    f.Tag = 'TOPO';
    f.Pointer = 'hand';
    
    f.UserData.compToBeRejected = false(size(ax));
    f.UserData.cfg = cfg;
    f.UserData.comp = comp;
    f.UserData.compcfg = comp.cfg;
    f.UserData.ffnTopoFig = ffnFig;
    f.UserData.ffnOut = ffnOut;
    f.UserData.TimeStamp = now;
    
    drawnow
    
    fprintf('Saving figure "%s" ...',fnFig)
    savefig(f,ffnFig);
    fprintf(' done\n')
    
    delete(f)
end


%% 3C. REJECT ARTIFACTUAL COMPONENTS

showAll = false; % if false, show only unprocessed data


topoFigPath = fullfile(outPathRoot,'MERGED_COMP_TOPOFIG');
cleanPath  = fullfile(outPathRoot,'MERGED_CLEAN');

gui_clean_components(topoFigPath,cleanPath,showAll)



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
fprintf('Attempting to log off ...\n')

system('shutdown -L')

fprintf(2,'Logging off failed!\nIf you need this computer, then go ahead and log off this account\n')

