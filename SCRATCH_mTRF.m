%% REQUIRED
outPathRoot = 'L:\Users\dstolz\EEGData_32\';
pthStimulusDir = 'L:\Users\dstolz\Stimuli Concatenated (10 minutes)\Saved Concatenated Files';


% TRF analysis

ForegroundOrBackground = "Foreground";

% dataSuffix = 'DSS';
dataSuffix = 'CLEAN';

% modelDirection = 1; % 1: forward model; -1: backwards model
modelDirection = -1; % 1: forward model; -1: backwards model

modelWindow = [-100 400]; % ms
% modelSplits = 1; %80;
modelSplits = 12;


crossvalLambdas = logspace(0,7,16);

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
tokEEG.Condition = 2;
tokEEG.Char = 3;
tokEEG.TC   = 4;
tokEEG.F1   = 5;
tokEEG.F2   = 6;
tokEEG.Pool = 7; % Pool character is suffix to "Pool"

model = cell(size(cEEG));

% match data filenames with corresponding wav filenames
for i = 1:length(cEEG)
    clear M

    try
        % first match slightly differently named EEG and WAV files
        x = cEEG{i};
        if startsWith(x(tokEEG.TC),"TC",'IgnoreCase',true)
            tc = "TC40";
        elseif startsWith(x(tokEEG.TC),"No",'IgnoreCase',true)
            tc = "NoTC40";
        else
            tc = "";
        end
        wfn = x(tokEEG.Char) + "_" + ForegroundOrBackground + "_" + tc ...
            + "_" + x(tokEEG.F1) + "_" + x(tokEEG.F2) ...
            + "_Pool_" + x{tokEEG.Pool}(end);
        ind = startsWith(fnWav,wfn,'IgnoreCase',true);
        
        M.fnWAVpattern = wfn;
        
        if ~any(ind)
            M.fnEEG = fnEEG{i};
            M.fnWAV = '';
            fprintf(2,'%s\nNo matching Wav files found! Figure out what''s wrong and run again\n',fnEEGcur)
            continue
        end
        
        
        fnEEGcur = fnEEG{i};
        fnWAVcur = fnWav{ind};
        
        M.info = cEEG{i};
        M.fnEEG = fnEEGcur;
        M.fnWAV = fnWAVcur;
        
        fprintf('\n%s\nDataset %d/%d\nMatched: "%s" with "%s"\n',repmat('v',1,50),i,length(cEEG),fnEEGcur,fnWav{ind})
        
        fprintf('Loading "%s" ...',fnEEGcur)
        load(ffnEEG{i});
        cfg = [];
        if exist('data','var')
            cfg.channel = ft_channelselection({'all','-A1','-A2','-Status','-*EOG','-EXG*'},data.label);
            data = ft_selectdata(cfg,data);
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
        
        M.label = data.label;
        M.fsample = data.fsample;
        
        cfg = [];
        cfg.layout = 'biosemi64.lay';
        M.layoutFile = 'biosemi64.lay';
        M.layout = ft_prepare_layout(cfg);
        
        n = length(crossvalLambdas);
        for j = 1:n
            fprintf('%d/%d.\tLambda = %.E\n',j,n,crossvalLambdas(j))
            M.crossval(j).result = mTRFcrossval(stim,resp.*modelFactor,Fs,modelDirection,0,modelWindow(2),crossvalLambdas(j),'verbose',0,'split',modelSplits);
            M.crossval(j).Ravg   = mean(M.crossval(j).result.r,'all');
            M.crossval(j).MSEavg = mean(M.crossval(j).result.err,'all');
            M.crossval(j).lambda = crossvalLambdas(j);
        end
        [v,k] = max([M.crossval.Ravg]);
        M.crossvalRavgIdx = k;
        M.crossvalRavgVal = v;
        
        [v,k] = min([M.crossval.MSEavg]);
        M.crossvalMSEavgIdx = k;
        M.crossvalMSEavgVal = v;
        
%         M.predictLambda = crossvalLambdas(M.crossvalRavgIdx);
        M.predictLambda = crossvalLambdas(M.crossvalMSEavgIdx);
        
        M.train = mTRFtrain(stim,resp.*modelFactor,Fs,modelDirection,modelWindow(1),modelWindow(2),M.predictLambda,'split',modelSplits);
        M.train.GFP = var(M.train.w,[],[1 3]); % global field power
        
        
        [M.predict,M.predictStats] = mTRFpredict(stim,resp.*modelFactor,M.train);%,'split',modelSplits);
        
        
        
        clf
        subplot(221)
        line(crossvalLambdas,[M.crossval.Ravg],'color','b','marker','o');
        line(crossvalLambdas(M.crossvalRavgIdx),M.crossvalRavgVal,'color','b','marker','o','markerfacecolor','b');
        set(gca,'xscale','log')
        ylabel('Pearson''s r')
        xlabel('\lambda')
        axis tight
        box on
        grid on
        
        subplot(222)
        
        line(crossvalLambdas,[M.crossval.MSEavg],'color','r','marker','o');
        line(crossvalLambdas(M.crossvalMSEavgIdx),M.crossvalMSEavgVal,'color','r','marker','o','markerfacecolor','r');
        set(gca,'xscale','log')
        ylabel('MSE')
        xlabel('\lambda')
        axis tight
        box on
        grid on
        
        if modelDirection > 0
            subplot(223)
            quick_topoplot(M.layout,mean(M.predictStats.r,1),M.label,true);
            h = colorbar;
            h.Label.String = 'Pearson''s r';
            
            subplot(224)
            quick_topoplot(M.layout,mean(M.predictStats.err,1),M.label,true);
            h = colorbar;
            h.Label.String = 'MSE';
        else
            subplot(2,2,[3 4])
            plot(M.train.t,M.train.GFP,'-','linewidth',2);
            axis tight
            grid on
            xline(0)
            xlabel('time (ms)');
            ylabel('GFP (a.u.)');
        end
        
        sgtitle({M.fnEEG,M.fnWAV},'Interpreter','none');

        drawnow
        
    catch me
        fprintf(2,'ERROR! SKIPPED!\n\t%s;\tLine %d\n\t%s\n',me.identifier,me.stack(1).line,me.message)
        M.ERROR = me;
    end
    
    
    model{i} = M;
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

% system('shutdown -L')

