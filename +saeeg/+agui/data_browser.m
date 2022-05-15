classdef data_browser < saeeg.agui.AnalysisGUI
    
    methods
        function obj = data_browser(MasterObj,parent)
            obj.MasterObj = MasterObj;
            obj.parent = parent;
        end
        
        
        function run_analysis(obj,Q)
            
            cfg.blocksize = obj.handles.blocksize.Value;
            cfg.layout = obj.MasterObj.SensorLayout;
            
            data = load(Q.CurrentFile,'data');
            
            cfg.channel = ft_channelselection({'all','-Status','-*EOG','-EXG*','-A1','-A2'},data.label);
            ft_databrowser(cfg,data);
            
            Q.mark_completed;
            
            Q.start_next;
        end
        
        function create_gui(obj)
            g = uigridlayout(obj.parent);
            g.ColumnWidth = {'1x','1x'};
            g.RowHeight = repmat({30},1,5);
            
            
            
            h = uilabel(g);
            h.Layout.Column = 1;
            h.Layout.Row = 1;
            h.Text = 'Block size:';
            h.FontSize = 16;
            h.FontWeight = 'bold';
            h.HorizontalAlignment = 'right';
            
            h = uieditfield(g,'numeric');
            h.Layout.Column = 2;
            h.Layout.Row = 1;
            h.Value = getpref('saeeg_agui','data_browser_blocksize',30);
            h.ValueDisplayFormat = '%.1f seconds';
            h.HorizontalAlignment = 'center';
            h.Limits = [0.1 600];
            obj.handles.blocksize = h;
                        
            
            
        end
        
        
    end
    
end