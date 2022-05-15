classdef data_reject_bad_channels < saeeg.agui.AnalysisGUI
    
    properties
        
    end
    
    methods
        function obj = data_reject_bad_channels(MasterObj,parent)
            obj.MasterObj = MasterObj;
            obj.parent = parent;
        end
        
        
        function run_analysis(obj,Q)
            
            remArtifactStdThr = obj.handles.remArtifactStdThr.Value;
            
            pathOut = fullfile(obj.MasterObj.OutputPath,'REJECTED');
            
            if ~isfolder(pathOut), mkdir(pathOut); end
            
            
            fnOut = Q.CurrentFilename + "_CHREJECT.mat";
            ffnOut = fullfile(pathOut,fnOut);
            
            if ~Q.OverwriteExisting && exist(ffnOut,'file')
                saeeg.vprintf(1,1,'File already exists, skippping: %s\n',Q.CurrentFile)
            else
                
                load(Q.CurrentFile,'data');
                
                cfg = [];
                cfg.channel = ft_channelselection({'all','-Status','-*EOG','-EXG*'},data.label);
                data = ft_selectdata(cfg,data);
                
                data_std = std(data.trial{1},[],2);
                
                ci = bootci(1000,{@mean,data_std},'alpha',.025);
                ind = data_std > ci(2) & data_std > remArtifactStdThr;
                
                saeeg.vprintf(2,'outliers: %d;\t97.5%% CI = %.1f',sum(ind),ci(2))
                idx = find(ind);
                saeeg.vprintf(2,'\tCh. Label\tStd')
                for k = 1:length(idx)
                    saeeg.vprintf(2,'\t%-2d. %-3s \t%.2f',idx(k),data.label{idx(k)},data_std(idx(k)))
                end
                
                artLabel = cellfun(@(a) ['-' a],data.label(ind),'uni',0);
                
                cfg = [];
                cfg.channel = ft_channelselection({'all',artLabel{:},'-Status','-EXG*'},data.label); %#ok<CCAT>
                
                data = ft_selectdata(cfg,data);
                
                saeeg.vprintf(1,'\tSaving "%s" ...',fnOut)
                save(ffnOut,'data');
                
            end
            
            Q.mark_completed;
            
            Q.start_next;
        end
        
        function create_gui(obj)
            g = uigridlayout(obj.parent);
            g.ColumnWidth = {'1x','1x'};
            g.RowHeight = repmat({30},1,5);
            
            
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
            h.HorizontalAlignment = 'center';
            h.Limits = [1 inf];
            obj.handles.remArtifactStdThr = h;
            
            
        end
        
        
    end
    
end