classdef fig_comp_mark_topomaps < saeeg.agui.AnalysisGUI
    
    properties
        
    end
    
    methods
        
        function obj = fig_comp_mark_topomaps(MasterObj,parent)
            obj.MasterObj = MasterObj;
            obj.parent = parent;
        end
        
        function run_analysis(obj,Q)
            
%             showAll = obj.handles.showAll.Value; % if false, show only unprocessed data
            
            
            topoFigPath = fullfile(outPathRoot,'TOPOFIG');
            cleanPath  = fullfile(outPathRoot,'CLEANED');
            
            gui_clean_components(topoFigPath,cleanPath)
            
%             Q.start_next;
        end
        
        
        function create_gui(obj)
            g = uigridlayout(obj.parent);
            g.ColumnWidth = {'1x','1x'};
            g.RowHeight = {30,'1x'};
            
%                       
%             
%             h = uicheckbox(g);
%             h.Layout.Column = 2;
%             h.Layout.Row = 1;
%             h.Text = '';
%             h.Value = getpref('saeeg_agui','comp_mark_topomaps','showAll');
%             obj.handles.showAll = h;
            
        end
        
    end
    
end