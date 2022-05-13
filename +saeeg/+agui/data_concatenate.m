classdef data_concatenate < saeeg.agui.AnalysisGUI
    
    properties
        
    end
    
    methods
        function obj = data_concatenate(MasterObj,parent)
            obj.MasterObj = MasterObj;
            obj.parent = parent;
        end
        
        
        function run_analysis(obj,Q)
            
            
            orderTokenIdx = obj.handles.orderTokenIdx.Value;
                        
            pathOut = obj.MasterObj.OutputPath;
%             pthToBeProcessed = obj.MasterObj.
            
            toBeMerged = merge_data_files(pathToPreprocessed,orderTokenIdx);
            
            eeg_preamble
            if ~isfolder(pathOut), mkdir(pathOut); end
            
            fprintf('Will attempt to merge %d groups of files\n',length(toBeMerged))
            for i = 1:length(toBeMerged)
                fprintf('\nMerging %d of %d groups\n',i,length(toBeMerged))
                
                if numel(toBeMerged{i}) < 2
                    fprintf(2,'\tMulitple files not found. No merging performed for this file!\n')
                    continue
                end
                
                data = [];
                fn = cell(size(toBeMerged{i}));
                for j = 1:length(toBeMerged{i})
                    [~,fn{j},~] = fileparts(toBeMerged{i}{j});
                    fprintf('\t> %d/%d: "%s" ...',j,length(toBeMerged{i}),fn{j})
                    if j == 1
                        load(toBeMerged{i}{j},'data');
                    else
                        m = load(toBeMerged{i}{j},'data');
                        data.trial = {[data.trial{1}, m.data.trial{1}]};
                    end
                    fprintf(' done\n')
                end
                
                data.time  = {(0:length(data.trial{1})-1.)/data.fsample};
                data.sampleinfo = [1 length(data.time{1})];
                
                
                if ~isempty(remArtifactStdThr) && remArtifactStdThr > 0
                    cfg_art = [];
                    cfg_art.channel = ft_channelselection({'all','-Status','-*EOG','-EXG*'},data.label);
                    data = ft_selectdata(cfg_art,data);
                    
                    data_std = std(data.trial{1},[],2);
                    
                    [ci,bs] = bootci(1000,{@mean,data_std},'alpha',.025);
                    ind = data_std > ci(2) & data_std > remArtifactStdThr;
                    
                    fprintf('outliers: %d;\t97.5%% CI = %.1f\n',sum(ind),ci(2))
                    idx = find(ind);
                    fprintf('\tCh. Label\tStd\n')
                    for k = 1:length(idx)
                        fprintf('\t%-2d. %-3s \t%.2f\n',idx(k),data.label{idx(k)},data_std(idx(k)))
                    end
                    
                    artLabel = cellfun(@(a) ['-' a],data.label(ind),'uni',0);
                    
                    cfg_art = [];
                    cfg_art.channel = ft_channelselection({'all',artLabel{:},'-Status','-EXG*'},data.label); %#ok<CCAT>
                    
                    data = ft_selectdata(cfg_art,data);
                end
                
                
                
                s = string(split(fn,delimiter));
                s(1,orderTokenIdx) = join(s(:,orderTokenIdx)',"_");
                fnOut = join(s(1,:),delimiter);
                fnOut = fnOut + "_MERGED.mat";
                ffnOut = fullfile(pathOut,fnOut);
                
                if skipCompleted && exist(ffnOut,'file')
                    fprintf('\tMerged file already exists, skippping: %s\n',fnOut)
                    continue
                end
                
                fprintf('\tSaving "%s" ...',fnOut)
                save(ffnOut,'data');
                fprintf(' done\n')
            end
        end
        
        function create_gui(obj)
            g = uigridlayout(obj.parent);
            g.ColumnWidth = {'1x','1x'};
            g.RowHeight = {30,30};
            
            
            % # std threshold; 0 or empty to not threshold
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 1;
            h.Text = 'Reject Threshold:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            
            h = uieditfield(g,'numeric');
            h.Layout.Column = 2;
            h.Layout.Row = 1;
            h.Value = getpref('saeeg_agui','data_concatenate_remArtifactStdThr',50);
            h.ValueDisplayFormat = '%.1f std';
            h.Limits = [1 inf];
            obj.handles.remArtifactStdThr = h;
            
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 2;
            h.Text = 'Order Token Index:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            
            h = uieditfield(g,'numeric');
            h.Layout.Column = 2;
            h.Layout.Row = 2;
            h.Value = getpref('saeeg_agui','data_concatenate_orderTokenIdx',5);
            h.ValueDisplayFormat = '%d';
            h.RoundFractionalValues = true;
            h.Limits = [1 100];
            obj.handles.orderTokenIdx = h;
            
        end
        
        
    end
    
end