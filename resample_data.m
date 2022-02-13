function data = resample_data(data,newFs)
% data = resample_data(data,newFs)
% 
% DJS 2/2022

narginchk(2,2);

[d,n] = rat(data.sampling_frequency/newFs);
newFs = ceil(n/d*data.sampling_frequency);

fprintf('Resampling from %.1f Hz to %.1f Hz ...',data.sampling_frequency,newFs)
data.eeg_data = resample(data.eeg_data',n,d)';
data.sampling_frequency = newFs;
data.samples = size(data.eeg_data,2);
data.events_trigger = round(data.events_trigger .* n ./ d);
data.time = (0:data.samples-1)./data.sampling_frequency;
fprintf(' done\n')