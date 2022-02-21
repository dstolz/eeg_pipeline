%%
addpath(genpath('C:\Users\dstolz\Documents\src\mTRF-Toolbox'));

%% TRF analysis - BONES


outPathRoot = 'C:\Users\dstolz\Desktop\EEGData';
pthStimulusDir = 'C:\Users\dstolz\Desktop\Stimuli Concatenated (10 minutes)\Saved Concatenated Files';


ForegroundOrBackground = 'Foreground';

modelDirection = -1; % 1: forward model; -1: backwards model
modelWindow = [-100 400]; % ms
modelLambda = 0.1; % regularization parameter
modelFactor = 1;%0.0313;
modelSplits = 80;

d = dir(fullfile(pthStimulusDir,'**\*.wav'));
fnWav = {d.name}';
ffnWav = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);


% pthIn = fullfile(outPathRoot,'MERGED_CLEAN');
% d = dir(fullfile(pthIn,'*CLEAN.mat'));

pthIn = fullfile(outPathRoot,'MERGED_DSS');
d = dir(fullfile(pthIn,'*DSS.mat'));


fnEEG = {d.name}';
ffnEEG = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);

% parse data filenames
cEEG = cellfun(@(a) textscan(a(1:end-4),'%s','delimiter','_'),fnEEG);
tokEEG.Char = 3;
tokEEG.TC   = 4;
tokEEG.F1   = 5;
tokEEG.F2   = 6;
tokEEG.Pool = 7; % Pool character is suffix to "Pool"

model = cell(size(cEEG));
% match data filenames with corresponding wav filenames
for i = 1:length(cEEG)
    try
        x = cEEG{i};
        %     ind = contains(fnWav,x{tokEEG.Char}) ...
        %         & contains(fnWav,x{tokEEG.TC},'IgnoreCase',true) ...
        %         & contains(fnWav,[x{tokEEG.F1} '_' x{tokEEG.F2}]) ...
        %         & contains(fnWav,['Pool_' x{tokEEG.Pool}(end)]) ...
        %         & contains(fnWav,ForegroundOrBackground);
        wfn = join({x{tokEEG.Char},ForegroundOrBackground,x{tokEEG.TC}, ...
            x{tokEEG.F1},x{tokEEG.F2},'Pool',x{tokEEG.Pool}(end)},'_');
        wfn = char(wfn);
        ind = startsWith(fnWav,wfn);
        
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
        if exist('data','var')
            resp = data.trial{1}';
            Fs = data.fsample;
        else
            resp = comp.trial{1}';
            Fs = comp.fsample;
        end
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
        
        model{i} = mTRFtrain(stim,resp.*modelFactor,Fs,modelDirection,modelWindow(1),modelWindow(2),modelLambda,'split',modelSplits);
        model{i}.fnEEG = fnEEG{i};
        model{i}.fnWAV = fnWav;
        
%         w = mean(model{i}.w,[1 3]);
%         plot(model{i}.t,w,'linewidth',2)
%         axis tight
%         grid on
%         
%         %     stackedplot(model{i}.t,squeeze(model{i}.w(:,:,1:3)))
%         
%         sgtitle(fnEEG{i},'interpreter','none');
%         drawnow
    catch me
        fprintf(2,'ERROR! SKIPPED!\n')
        model{i}.ERROR = me;
    end
end

fn = sprintf('mTRF_model_%d.mat',modelDirection);
ffn = fullfile(outPathRoot,fn);
fprintf('Saving "%s" ...',ffn)
save(ffn,'model');
fprintf(' done\n')

%% log off windows after finished

system('shutdown -L')

