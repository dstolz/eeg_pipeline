%%
addpath(genpath('C:\Users\dstolz\Documents\src\mTRF-Toolbox'));

%% TRF analysis - BONES


outPathRoot = 'C:\Users\dstolz\Desktop\EEGData';
pthStimulusDir = 'C:\Users\dstolz\Desktop\Stimuli Concatenated (10 minutes)\Saved Concatenated Files';


ForegroundOrBackground = 'Foreground';

modelDirection = 1; % 1: forward model; -1: backwards model
modelWindow = [-100 400]; % ms
modelLambda = 0.1; % regularization parameter
modelFactor = 0.0313;

d = dir(fullfile(pthStimulusDir,'**\*.wav'));
fnWav = {d.name}';
ffnWav = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);


pthIn = fullfile(outPathRoot,'MERGED_CLEAN');

d = dir(fullfile(pthIn,'*CLEAN.mat'));
fnEEG = {d.name}';
ffnEEG = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);

% parse data filenames
cEEG = cellfun(@(a) textscan(a(1:end-4),'%s','delimiter','_'),fnEEG);
tokEEG.Char = 3;
tokEEG.TC   = 4;
tokEEG.F1   = 5;
tokEEG.F2   = 6;
tokEEG.Pool = 7; % Pool character is suffix to "Pool"

% match data filenames with corresponding wav filenames
for i = 1:length(cEEG)
    x = cEEG{i};
    ind = contains(fnWav,x{tokEEG.Char}) ...
        & contains(fnWav,x{tokEEG.TC},'IgnoreCase',true) ...
        & contains(fnWav,[x{tokEEG.F1} '_' x{tokEEG.F2}]) ...
        & contains(fnWav,['Pool_' x{tokEEG.Pool}(end)]) ...
        & contains(fnWav,ForegroundOrBackground);
    n = sum(ind);
    
    if n == 0
        fprintf(2,'No matching Wav files found! skipping\n')
        continue
    end
        
    if n > 1
        fprint(2,'%d matching Wav files found! Figure out what''s wrong and run again\n',n)
        continue
    end
    
    fprintf('Matched: "%s" with "%s"\n',fnEEG{i},fnWav{ind})
    
    fprintf('Loading "%s" ...',fnEEG{i})
    load(ffnEEG{i});
    resp = data.trial{1}';
    Fs = data.fsample;
    fprintf(' done\n')

    fprintf('Loading "%s" ...',fnWav{ind})
    [stim,wavFs] = audioread(ffnWav{ind});
    fprintf(' done\n')
    
    fprintf('Rectifying and resampling stimulus %.1f Hz -> %.1f Hz ...',wavFs,Fs)
    stim = mTRFenvelope(stim,wavFs,Fs);
    fprintf(' done\n')
    

    adj = length(stim) - length(resp);
    if adj ~= 0
        fprintf(2,'WARNING: Stimulus ended up being %d samples longer than the trial. Truncating stimulus.\n',adj)
        stim(end-adj+1:end) = [];
    end

    model = mTRFtrain(stim,resp.*modelFactor,Fs,modelDirection,modelWindow(1),modelWindow(2),modelLambda);


    w = mean(model.w,[1 3]);
    plot(model.t,w,'linewidth',2)
    axis tight
    grid on
    
    
    sgtitle(fnEEG{i},'interpreter','none');
    drawnow
    
end




