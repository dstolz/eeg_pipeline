function data = biosemi2mat(ffnIn,opts)
% bisoemi2mat
% data = biosemi2mat
% data = biosemi2mat(ffnIn)
% data = biosemi2mat(ffnIn,opts)
% [data,opts] = biosemi2mat(...)
% 
% opts.ReferenceChannels = 0;
% opts.RemoveFirstTrigger = false;
% opts.ParallelPortOffset = 0;
%
% DJS 2/2022

dflt.ReferenceChannels = 0;
dflt.RemoveFirstTrigger = false;
dflt.ParallelPortOffset = 0;

if nargin < 2 || isempty(opts), opts = dflt; end

fields = fieldnames(dflt);
for i = 1:length(fields)
    if ~isfield(opts,fields{i})
        opts.(fields{i}) = dflt.(fields{i});
    end
end

if nargin < 1 || isempty(ffnIn)
    pthIn = getpref('EEG_PIPELINE','biosemi2mat_pthIn',cd);
    [fnIn,pthIn] = uigetfile({'*.bdf','Biosemi EEG'},'Biosemi', ...
        pthIn,'Multiselect','on');
    
    if isequal(fnIn,0), return; end
    
    setpref('EEG_PIPELINE','biosemi2mat_pthIn',pthIn);
    
    if iscellstr(fnIn)
        ffnIn = cellfun(@(a) fullfile(pthIn,a),fnIn,'uni',0);
    else
        ffnIn = fullfile(pthIn,fnIn);
    end
end


if iscellstr(ffnIn)
    data = cellfun(@(a) biosemi2mat(a,opts),ffnIn,'uni',0);
    return
end


fprintf('Loading Biosemi data: %s ...',ffnIn)
EEG = extract_data_biosemi(ffnIn,opts.ReferenceChannels);    %My code
fprintf(' done\n')

labels_electrodes = [EEG.chanlocs.labels]';

%Adding the Cz value re-referenced to the average of the two ear lobes
if isequal(opts.ReferenceChannels,0)
    EEG.data(size(EEG.data,1) + 1,:) = mean(EEG.data);
    labels_electrodes(length(EEG.chanlocs) + 1,1) = {'AEL'};
end

%Adding the additional channel (A2 - A1) for the Perceptual study
if isequal(opts.ReferenceChannels,0)
    EEG.data(size(EEG.data,1) + 1,:) = EEG.data(1,:) - EEG.data(2,:);
    labels_electrodes(length(EEG.chanlocs) + 2,1) = {'A1_A2'};
end

data.events_type    = [EEG.event.type] - opts.ParallelPortOffset;
data.events_trigger = [EEG.event.latency];
data.events_status  = [EEG.event.status];

if opts.RemoveFirstTrigger
    data.events_type(1) = [];
    data.events_trigger(1) = [];
    data.events_status(1) = [];
end

data.eeg_data = double(EEG.data);
data.channels = EEG.nbchan;
data.samples = EEG.pnts;
data.sampling_frequency = EEG.srate;
data.time = (0:size(EEG.data,2)-1)./EEG.srate;
data.opts.ReferenceChannels = {opts.ReferenceChannels};
data.trial_duration = (EEG.pnts - 1)/EEG.srate;
data.labels = labels_electrodes;
data.chanlocs = EEG.chanlocs;
data.resolution = EEG.resolution;

if nargout == 0
    clear data opts
end