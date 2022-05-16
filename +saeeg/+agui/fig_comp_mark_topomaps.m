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


            outPathRoot = obj.MasterObj.OutputPath;

            cleanPath = fullfile(outPathRoot,'CLEANED');

            fnOut = char(Q.CurrentFilename);
            fnOut = fnOut(1:find(fnOut=='_',1,'last')-1);
            ffnOut = fullfile(cleanPath,fnOut + "_CLEANED.mat");
            
            if ~Q.OverwriteExisting && exist(ffnOut,'file')
                saeeg.vprintf(1,1,'File already exists, skippping: %s\n',ffnOut)
            else
                if ~isfolder(cleanPath), mkdir(cleanPath); end

                gui_clean_components(Q.CurrentFile);

                waitfor(gcf);
            end
            
            Q.mark_completed;
            
            Q.start_next;
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