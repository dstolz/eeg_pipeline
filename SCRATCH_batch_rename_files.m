%% Batch rename

outPathRoot = 'C:\Users\dstolz\Desktop\EEGTestData';

d = dir(fullfile(outPathRoot,'**\*MERGED*.mat'));



for i = 1:length(d)
    fnOut = strrep(d(i).name,'-','_');
    ffnIn = fullfile(d(i).folder,d(i).name);
    ffnOut = fullfile(d(i).folder,fnOut);
    fprintf('%s -> %s\n',d(i).name,fnOut)
    movefile(ffnIn,ffnOut);
    
end