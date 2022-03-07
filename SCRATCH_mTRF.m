%% REQUIRED
outPathRoot = 'C:\Users\dstolz\Desktop\EEGData';



%% TRF analysis - BONES


pthStimulusDir = 'C:\Users\dstolz\Desktop\Stimuli Concatenated (10 minutes)\Saved Concatenated Files';


ForegroundOrBackground = "Foreground";

% dataSuffix = 'DSS';
dataSuffix = 'CLEAN';

modelDirection = 1; % 1: forward model; -1: backwards model
modelWindow = [-100 400]; % ms
modelSplits = 1; %80;

modelLambda = 0.1; % regularization parameter
modelFactor = 1;%0.0313;

d = dir(fullfile(pthStimulusDir,'**\*.wav'));
fnWav = {d.name}';
ffnWav = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);



pthIn = fullfile(outPathRoot,sprintf('MERGED_%s',dataSuffix));
d = dir(fullfile(pthIn,sprintf('*%s.mat',dataSuffix)));


fnEEG = {d.name}';
ffnEEG = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);

% parse data filenames
cEEG = cellfun(@(a) textscan(a(1:end-4),'%s','delimiter','_'),fnEEG);
cEEG = cellfun(@string,cEEG,'uni',0);
tokEEG.Char = 3;
tokEEG.TC   = 4;
tokEEG.F1   = 5;
tokEEG.F2   = 6;
tokEEG.Pool = 7; % Pool character is suffix to "Pool"

model = cell(size(cEEG));
% match data filenames with corresponding wav filenames
for i = 1:length(cEEG)
    try
        % first match slightly differently named EEG and WAV files
        x = cEEG{i};
        if startsWith(x(tokEEG.TC),"TC",'IgnoreCase',true)
            tc = "TC";
        elseif startsWith(x(tokEEG.TC),"No",'IgnoreCase',true)
            tc = "NoTC";
        else
            tc = "";
        end
        wfn = x(tokEEG.Char) + "_" + ForegroundOrBackground + "_" + tc ...
            + digitsPattern(2) + "_" + x(tokEEG.F1) + "_" + x(tokEEG.F2) ...
            + "_Pool_" + x{tokEEG.Pool}(end);
        ind = startsWith(fnWav,wfn,'IgnoreCase',true);
        
        model{i}.fnWAVpattern = wfn;
        
        if ~any(ind)
            model{i}.fnEEG = fnEEG{i};
            model{i}.fnWAV = '';
            fprintf(2,'No matching Wav files found! Figure out what''s wrong and run again\n')
            continue
        end
        
        
        fnEEGcur = fnEEG{i};
        fnWAVcur = fnWav{ind};
        
        fprintf('Matched: "%s" with "%s"\n',fnEEGcur,fnWav{ind})
        
        fprintf('Loading "%s" ...',fnEEGcur)
        load(ffnEEG{i});
        if exist('data','var')
            resp = data.trial{1}';
            Fs = data.fsample;
        else
            resp = comp.trial{1}';
            Fs = comp.fsample;
        end
        fprintf(' done\n')
        
        fprintf('Loading "%s" ...',fnWAVcur)
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

        
%         w = mean(model{i}.w,[1 3]);
%         plot(model{i}.t,w,'linewidth',2)
%         axis tight
%         grid on
%         
%         %     stackedplot(model{i}.t,squeeze(model{i}.w(:,:,1:3)))
%         
%         sgtitle(thisFnEEG,'interpreter','none');
%         drawnow
    catch me
        fprintf(2,'ERROR! SKIPPED!\n\t%s;\tLine %d\n\t%s\n',me.identifier,me.stack(1).line,me.message)
        model{i}.ERROR = me;
    end
    
    model{i}.fnEEG = fnEEGcur;
    model{i}.fnWAV = fnWAVcur;
end

e = cellfun(@(a) isfield(a,'ERROR'),model);
if any(e)
    fprintf('Finished with %d Errors!\n',sum(e))
end

fn = sprintf('mTRF_%s_%s_model_%d.mat',ForegroundOrBackground,dataSuffix,modelDirection);
ffn = fullfile(outPathRoot,fn);
fprintf('Saving "%s" ...',ffn)
save(ffn,'model');
fprintf(' done\n')


%% log off windows after finished

system('shutdown -L')

