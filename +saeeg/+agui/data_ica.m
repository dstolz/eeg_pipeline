classdef data_ica < saeeg.agui.AnalysisGUI
    
    
    properties
        
    end
    
    methods
        function obj = data_ica(MasterObj,parent)
            obj.MasterObj = MasterObj;
            obj.parent = parent;
        end
        
        
        function run_analysis(obj,Q)
            % Use ICA to find artifacts and then remove in 3B
            % Jung, et al, 2000, Psychophysiology, https://doi.org/10.1111/1469-8986.3720163
                                   
            cfg = []; 
            cfg.method = obj.handles.method.Value;
            cfg.channel = obj.handles.ChannelSelection.Value;
                       
            
            fnOut = Q.CurrentFilename + "_" + cfg.method + ".mat";
            ffnOut = char(fullfile(Q.OutputPath,fnOut));
            
            if Q.SkipExisting && exist(ffnOut,'file')
                saeeg.vprintf(1,1,'File already exists, skippping: %s\n',fnOut)
            else
                cfg.inputfile  = char(Q.CurrentFile);
                cfg.outputfile = ffnOut;
                ft_componentanalysis(cfg);
            end
            
            Q.mark_completed;
            
            Q.start_next;

        end
        
        function create_gui(obj)
            g = uigridlayout(obj.parent);
            g.ColumnWidth = {'1x','1x'};
            g.RowHeight = {30,'1x'};
            
                        
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 1;
            h.Text = 'Method:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            h = uidropdown(g);
            h.Layout.Column = 2;
            h.Layout.Row = 1;
            h.Items = {'fastica','runica'};
            h.Value = getpref('saeeg_agui','data_ica_method','fastica');
            obj.handles.method = h;
            

            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 2;
            h.Text = 'Channels:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';            
            
            lay = obj.MasterObj.SensorLayout.label(1:end-2); % always exclude 'COMNT' and 'SCALE';
            
            h = uilistbox(g);
            h.Layout.Column = 2;
            h.Layout.Row = 2;
            h.Multiselect = 'on';
            h.Items = lay;
            h.Value = lay(~startsWith(lay,{'Status','EXG'}));
            obj.handles.ChannelSelection = h;

            
        end
        
        
    end
    
end