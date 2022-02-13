%% TRF analysis - BONES

nComponents = 6;

pthWav = 'C:\Users\Daniel\Desktop\EEGTestData\Stimuli';


outPathRoot = 'C:\Users\dstolz\Desktop\EEGTestData';
pthDSS = fullfile(outPathRoot,'MERGED_DSS');

fnWav = 'M_Background_NoTC40_6_7_Pool_C.wav';

ffnWav = fullfile(pthWav,fnWav);
[stim,wavFs] = audioread(ffnWav);

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
