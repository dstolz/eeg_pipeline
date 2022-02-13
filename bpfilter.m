function [data,opts] = bpfilter(data,opts)
% data = bpfilter(data,opts)
% [data,opts] = bpfilter(data,opts)
% 
% opts.a = 1;
% opts.filterOrder = 2;
% opts.Acausal = false;
% opts.bpfc = [];
%
% DJS 2/2022

dflt.a = 1;
dflt.filterOrder = 2;
dflt.Acausal = false;
dflt.bpfc = [];

if nargin < 2 || isempty(opts), opts = dflt; end

fields = fieldnames(dflt);
for i = 1:length(fields)
    if ~isfield(opts,fields{i})
        opts.(fields{i}) = dflt.(fields{i});
    end
end

a = 1;
b = fir1(opts.filterOrder,opts.bpfc/(data.sampling_frequency/2));

if dflt.Acausal
    data.eeg_data = filtfilt(b,a,data.eeg_data')';
else
    data.eeg_data = filter(b,a,data.eeg_data')';
    
    %Data have been shifted to compensate for the phase-shift introduced by the FIR filter
    [time_delay_fir,~]  = grpdelay(b,1);
    data.eeg_data = data.eeg_data(:,round(mean(time_delay_fir)) + 1:end);
end
fprintf(' done\n')

