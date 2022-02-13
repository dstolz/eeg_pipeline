%%
addpath(genpath('C:\Users\Daniel\src\mTRF-Toolbox'));

%% TRF analysis - BONES

nComponents = 6;
outPathRoot = 'C:\Users\dstolz\Desktop\EEGTestData';


pthStimulusDir = 'C:\Users\dstolz\Desktop\Stimuli Concatenated (10 minutes)\Saved Concatenated Files';


ForegroundOrBackground = 'Foreground';

modelDirection = 1; % 1: forward model; -1: backwards model
modelWindow = [-100 400]; % ms
modelLambda = 0.1; % regularization parameter

d = dir(fullfile(pthStimulusDir,'**\*.wav'));
fnWav = {d.name}';
ffnWav = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);


pthDSS = fullfile(outPathRoot,'MERGED_DSS');

d = dir(fullfile(pthDSS,'*DSS.mat'));
fnDSS = {d.name}';

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
        & contains(fnWav,x{tokDSS.TC}) ...
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
    load(fnDSS{i});
    fprintf(' done\n')

    fprintf('Loading "%s" ...',fnWav{ind})
    [stim,wavFs] = audioread(ffnWav{ind});
    fprintf(' done\n')
    
    
    fprintf('Resampling stimulus %.1f Hz -> %.1f Hs ...',wavFs,Fs)
%     [q,p] = rat(wavFs/Fs);
%     stim = resample(stim,p,q);
    stim = mTRFenvelope(stim,wavFs,Fs);
    fprintf(' done\n')
    
    % truncate extra samples if the stimulus length doesn't match EEG trial
    adj = length(stim) - length(resp);
    if adj ~= 0
        fprintf(2,'WARNING: Stimulus ended up being %d samples longer than the trial. Truncating stimulus.\n',adj)
        stim(end-adj+1:end) = [];
    end

    fprintf('Computing hilbert transform of stimulus ...')
    stim = hilbert(stim);
    stim = abs(stim);
    fprintf(' done\n')
    
    model = mTRFtrain(stim,resp.*factor,Fs,modelDirection,modelWindow(1),modelWindow(2),modelLambda,'split',40);

    
end

%%

load(fullfile(pthDSS,'P012712_Pre_M_noTC_6-7_PoolC_MERGED_CLEAN_DSS.mat'),'comp');
Fs = comp.fsample;
resp = comp.trial{1}';
clear comp

stim = hilbert(stim);
stim = real(stim);

[q,p] = rat(wavFs/Fs);
stim = resample(stim,p,q);

% truncate extra samples if the stimulus length doesn't match EEG trial
adj = length(stim) - length(resp);
stim(end-adj+1:end) = [];


factor = 0.0313; % ?

model = mTRFtrain(stim,resp.*factor,Fs,-1,-50,400,0.1,'split',40);

% model.w = squeeze(model.w); % ???

disp(model)


%

% Plot STRF
h = imagesc(model.t,1:length(model.b),model.w);
title('Speech STRF (Fz)'), ylabel('Frequency band'), xlabel('lag (ms)')
set(gca,'ydir','normal');%,'clim',[-.6 .6])
colormap jet

%%

w = mean(model.w,[1 3]);
plot(model.t,w,'linewidth',2)
axis tight
grid on

%%
% Plot GFP
subplot(2,2,2), mTRFplot(model,'mgfp');
title('Global Field Power'), xlabel('')

% Plot TRF
subplot(2,2,3), mTRFplot(model,'trf');
title('Speech TRF (Fz)'), ylabel('Amplitude (a.u.)')

% Plot GFP
subplot(2,2,4), mTRFplot(model,'gfp');
title('Global Field Power')
