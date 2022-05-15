classdef data_mTRF < saeeg.agui.AnalysisGUI
    
    methods
        function obj = data_mTRF(MasterObj,parent)
            obj.MasterObj = MasterObj;
            obj.parent = parent;
        end
        
        
        function run_analysis(obj,Q)
            
            
            ForegroundOrBackground = obj.handles.modelDirection.Value;           
            modelWindow = str2num(obj.handles.window.Value);
            metricForLamda = obj.handles.lambdaMetric.Value; % maximum Pearson's correlation coefficient
            crossvalLambdas = str2num(obj.handles.crossvalLambdas.Value);
            crossvalNFold = obj.handles.crossvalNFold.Value;
            pthStimulusDir = obj.handles.pthStimulusDir.Value;
            
            predictTestFold = round(crossvalNFold/2);
            
                        
            
            d = dir(fullfile(pthStimulusDir,'**\*.wav'));
            fnWav = {d.name}';
            ffnWav = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);
            
                        
            % parse data filenames
            cEEG = textscan(Q.CurrentFilename,'%s','delimiter','_');
            cEEG = string(cEEG{1});
            
            tokEEG.Subject = 1;
            tokEEG.Condition = 2;
            tokEEG.Char = 3;
            tokEEG.TC   = 4;
            tokEEG.F1   = 5;
            tokEEG.F2   = 6;
            tokEEG.Pool = 7; % Pool character is suffix to "Pool"
            
            
            % match data filenames with corresponding wav filenames
            
            % first match slightly differently named EEG and WAV files
            if startsWith(cEEG(tokEEG.TC),"TC",'IgnoreCase',true)
                tc = "TC40";
            elseif startsWith(cEEG(tokEEG.TC),"No",'IgnoreCase',true)
                tc = "NoTC40";
            else
                tc = "";
            end
            wfn = cEEG(tokEEG.Char) + "_" + ForegroundOrBackground + "_" + tc ...
                + "_" + cEEG(tokEEG.F1) + "_" + cEEG(tokEEG.F2) ...
                + "_Pool_" + cEEG{tokEEG.Pool}(end);
            ind = startsWith(fnWav,wfn,'IgnoreCase',true);
            
            M.fnWAVpattern = wfn;
            
            M.fnEEG = Q.CurrentFile;
            M.fnWAV = '';           
            M.info = cEEG;

            if ~any(ind)
                fprintf(2,'%s\nNo matching Wav files found! Figure out what''s wrong and run again\n',fnEEGcur)
                
                Q.mark_completed;
                
                Q.start_next;
            end
            
            
            fnWAVcur = fnWav{ind};
            
            M.fnWAV = fnWAVcur;
            
            saeeg.vprintf(1,'Matched: "%s" with "%s"\n',Q.CurrentFilename,fnWav{ind})
            
            saeeg.vprintf(1,'Loading "%s" ...',Q.CurrentFilename)
            load(Q.CurrentFile,'data');
            
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
            
            % normalize response
            resp = resp ./ std(resp(:));
            
            
            % handle the stimulus
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
            
            
            % store some info along with the model
            M.label = data.label;
            M.fsample = data.fsample;
            
            cfg = [];
            cfg.layout = 'biosemi64.lay';
            M.layoutFile = 'biosemi64.lay';
            M.layout = ft_prepare_layout(cfg);
            
            
            
            % generate random crossval, training, and prediction subsets
            
            % Generate training/test sets
            [stimtrain,resptrain,stimtest,resptest] = mTRFpartition(stim,resp,crossvalNFold,predictTestFold);
            
            
            
            % Crossvalidation
            % Model hyperparameters
            % Run fast cross-validation
            M.crossval = mTRFcrossval(stimtrain,resptrain,Fs,modelDirection,0,modelWindow(2),crossvalLambdas,...
                'zeropad',0,'fast',1);
            
            
            
            
            
            
            % Estimate optimal hyperparameters
            M.crossval.Ravg = mean(M.crossval.r,1);
            [M.crossvalRavgVal,M.crossvalRavgIdx] = max(M.crossval.Ravg,[],2);
            
            M.crossval.MSEavg = mean(M.crossval.err,1);
            [M.crossvalMSEavgVal,M.crossvalMSEavgIdx] = min(mean(M.crossval.err,1),[],2);
            
            
            switch lower(metricForLamda)
                case "r"
                    M.predictLambda = crossvalLambdas(M.crossvalRavgIdx);
                case "mse"
                    M.predictLambda = crossvalLambdas(M.crossvalMSEavgIdx);
            end
            
            
            
            
            
            
            % Train model
            M.train = mTRFtrain(stimtrain,resptrain,Fs,modelDirection,modelWindow(1),modelWindow(2),M.predictLambda,'zeropad',0);
            M.train.GFP = var(M.train.w,[],[1 3]); % global field power
            
            
            
            
            % Predict
            [M.predict,M.predictStats] = mTRFpredict(stimtest,resptest,M.train,'zeropad',0);
            
            
            
            
            Q.mark_completed;
            
            Q.start_next;
        end
        
        
        
        function create_gui(obj)
            g = uigridlayout(obj.parent);
            g.ColumnWidth = {'1x','1x'};
            g.RowHeight = repmat({30},1,6);
            
            
            
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 1;
            h.Text = 'Model direction:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            h = uidropdown(g);
            h.Layout.Column = 2;
            h.Layout.Row = 1;
            h.Items = {'Forward','Backward'};
            h.ItemsData = {1,-1};
            h.Value = getpref('saeeg_agui','data_mTRF_modelDirection',1);
            obj.handles.modelDirection = h;
            
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 2;
            h.Text = 'Window (ms):';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            h = uieditfield(g);
            h.Layout.Column = 2;
            h.Layout.Row = 2;
            h.Value = getpref('saeeg_agui','data_mTRF_window','[-150 450]');
            h.HorizontalAlignment = 'center';
            obj.handles.window = h;
            
            
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 3;
            h.Text = 'Lambda metric:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            h = uidropdown(g);
            h.Layout.Column = 2;
            h.Layout.Row = 3;
            h.Items = {'r','err'};
            h.Value = getpref('saeeg_agui','data_mTRF_lambdaMetric','r');
            obj.handles.lambdaMetric = h;
            
            
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 4;
            h.Text = 'Crossvalidation Lambda Values:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            h = uieditfield(g);
            h.Layout.Column = 2;
            h.Layout.Row = 4;
            h.Value = getpref('saeeg_agui','data_mTRF_crossvalLambdas','10.^(linspace(-6,6,16))');
            h.HorizontalAlignment = 'center';
            obj.handles.crossvalLambdas = h;
            
            
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 5;
            h.Text = 'Crossvalidation Folds:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            h = uieditfield(g,'numeric');
            h.Layout.Column = 2;
            h.Layout.Row = 5;
            h.Value = getpref('saeeg_agui','data_mTRF_crossvalNFold',50);
            h.Limits = [1 1e6];
            h.RoundFractionalValues = 'on';
            h.ValueDisplayFormat = '%d';
            h.HorizontalAlignment = 'center';
            obj.handles.crossvalNFold = h;
            
            
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 6;
            h.Text = 'Stimulus file location:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            h = uieditfield(g);
            h.Layout.Column = 2;
            h.Layout.Row = 6;
            h.Value = getpref('saeeg_agui','data_mTRF_pthStimulusDir','L:\Users\dstolz\Stimuli Concatenated (10 minutes)\Saved Concatenated Files');
            obj.handles.pthStimulusDir = h;
            
            
        end
        
        
    end
    
end