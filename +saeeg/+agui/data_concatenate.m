classdef data_concatenate < saeeg.agui.AnalysisGUI
    
    methods
        function obj = data_concatenate(parent)
            obj.parent = parent;
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