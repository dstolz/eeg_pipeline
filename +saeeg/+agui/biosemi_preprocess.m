classdef biosemi_preprocess < saeeg.agui.AnalysisGUI
    
    % cfg_Preprocess.definetrial = [];
    % cfg_Preprocess.definetrial.trialdef.eventtype  = 'STATUS';
    % cfg_Preprocess.definetrial.trialdef.eventvalue = [3 4];
    %
    % cfg_Preprocess.resample = [];
    % cfg_Preprocess.resample.resamplefs = 256;
    %
    %
    % cfg_Preprocess.preprocessing = [];
    % cfg_Preprocess.preprocessing.reref = 'yes';
    % cfg_Preprocess.preprocessing.refchannel = {'A1' 'A2'};
    % cfg_Preprocess.preprocessing.detrend = 'yes';
    % cfg_Preprocess.preprocessing.bpfreq = [2 35]; %[1 120];
    % cfg_Preprocess.preprocessing.bpfilter = 'yes';
    
    
    
    methods
        function obj = biosemi_preprocess(MasterObj,parent)
            obj.MasterObj = MasterObj;
            obj.parent = parent;
        end
        
        function create_gui(obj)
            g = uigridlayout(obj.parent);
            g.ColumnWidth = {'1x','1x'};
            g.RowHeight = {30,'1x',30,30,'1x'};
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 1;
            h.Text = 'Define Trial';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            
            
            data.eventtype = 'STATUS';
            data.eventvalue = [3 4];
            data = getpref('saeeg_agui','biosemi_preprocess_definetrial',data);
            
            h = obj.create_parameter_table(g,data);
            h.Layout.Column = [1 2];
            h.Layout.Row = 2;
            h.ColumnName = {'Parameter','Value'};
            obj.handles.definetrial = h;
           
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 3;
            h.Text = 'Resample Fs:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            
            h = uieditfield(g,'numeric');
            h.Layout.Column = 2;
            h.Layout.Row = 3;
            h.Value = getpref('saeeg_agui','biosemi_preprocess_resamplefs',32);
            h.ValueDisplayFormat = '%.1f Hz';
            h.Limits = [1 1e5];
            obj.handles.resamplefs = h;
            
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 4;
            h.Text = 'Preprocessing';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            
            data.reref = 'yes';
            data.refchannel = 'A1,A2';
            data.detrend = 'yes';
            data.bpfreq = [2 35];
            data.bpfilter = 'yes';
            
            data = getpref('saeeg_agui','biosemi_preprocess_preprocessing',data);

            h = obj.create_parameter_table(g,data);
            h.Layout.Column = [1 2];
            h.Layout.Row = 5;
            h.ColumnName = {'Parameter','Value'};
            obj.handles.preprocess = h;
        end
        
        
        
        function run_analysis(obj,Q)
            
            
            [~,fnIn,~] = fileparts(Q.CurrentFile);
            ffnOut = char(fullfile(obj.MasterObj.OutputPath,fnIn + ".mat"));
            
            if Q.SkipExisting && exist(ffnOut,'file')
                saeeg.vprintf(1,1,'File already exists, skippping: %s\n',Q.CurrentFile)
            end
            
            cfg = [];
            cfg.trialdef = obj.tabledata_to_cfg(obj.handles.definetrial);
            cfg.headerfile = char(Q.CurrentFile);
            cfg = ft_definetrial(cfg);
            
            cfg.trl = [cfg.trl(:,1)', 0]; % reconjigure trial samples for onset/offset timing from separate events [3 4]
            

            data = ft_preprocessing(cfg);
            
            cfg = [];
            cfg.resamplefs = obj.handles.resamplefs.Value;
            data = ft_resampledata(cfg,data);
            
            cfg = obj.tabledata_to_cfg(obj.handles.preprocess);
            cfg.refchannel = split(cfg.refchannel,',');
            data = ft_preprocessing(cfg,data);
           
            saeeg.vprintf(1,'Saving data: "%s"',ffnOut)
            save(ffnOut,'data');
        end
        
        
    end
    
end