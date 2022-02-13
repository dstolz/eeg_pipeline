function data = remove_sensors(data,rmSensors)
% data = remove_sensors(data)
% data = remove_sensors(data,rmSensors)
% 
% DJS 2/2022

if nargin < 2 || isempty(rmSensors)
    [s,v] = listdlg('PromptString','Select sensors to remove...', ...
        'SelectionMode','multiple', ...
        'ListString',data.labels);
    if ~v
        fprintf(2,'No sensors were removed from the data.\n')
        return
    end
    rmSensors = data.labels(s);
end

ind = ismember(data.labels,rmSensors);
data.labels(ind) = [];
data.chanlocs(ind) = [];
data.eeg_data(ind,:) = [];
data.channels = sum(~ind);
data.sensors_removed = rmSensors;
fprintf('Removed %d of %d sensors: %s\n',sum(ind),length(ind),string(join(rmSensors,',')))
