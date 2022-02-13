%%
addpath(genpath('C:\Users\dstolz\Documents\src\mTRF-Toolbox'));

%% TRF analysis - BONES


outPathRoot = 'C:\Users\dstolz\Desktop\EEGTestData';
pthStimulusDir = 'C:\Users\dstolz\Desktop\Stimuli Concatenated (10 minutes)\Saved Concatenated Files';


ForegroundOrBackground = 'Foreground';

modelDirection = 1; % 1: forward model; -1: backwards model
modelWindow = [-100 400]; % ms
modelLambda = 0.1; % regularization parameter
modelFactor = 0.0313;

d = dir(fullfile(pthStimulusDir,'**\*.wav'));
fnWav = {d.name}';
ffnWav = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);


pthDSS = fullfile(outPathRoot,'MERGED_DSS');

d = dir(fullfile(pthDSS,'*DSS.mat'));
fnDSS = {d.name}';
ffnDSS = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);

% parse DSS filenames
cDSS = cellfun(@(a) textscan(a(1:end-4),'%s','delimiter','_'),fnDSS);
tokDSS.Char = 3;
tokDSS.TC   = 4;
tokDSS.F1   = 5;
tokDSS.F2   = 6;
tokDSS.Pool = 7; % Pool character is suffix to "Pool"

% match data filenames with corresponding wav filenames
for i = 1:length(cDSS)
    x = cDSS{i};
    ind = contains(fnWav,x{tokDSS.Char}) ...
        & contains(fnWav,x{tokDSS.TC},'IgnoreCase',true) ...
        & contains(fnWav,[x{tokDSS.F1} '_' x{tokDSS.F2}]) ...
        & contains(fnWav,['Pool_' x{tokDSS.Pool}(end)]) ...
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
    
    fprintf('Matched: "%s" with "%s"\n',fnDSS{i},fnWav{ind})
    
    fprintf('Loading "%s" ...',fnDSS{i})
    load(ffnDSS{i});
    resp = comp.trial{1}';
    Fs = comp.fsample;
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
    
    
    sgtitle(fnDSS{i},'interpreter','none');
    drawnow
    
end




