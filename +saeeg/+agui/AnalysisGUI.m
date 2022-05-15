classdef (Hidden) AnalysisGUI < handle
    
    properties
        cfg
    end
    
    properties (SetAccess = immutable)
        
    end
    
    properties (SetAccess = protected)
        parent
        handles
        MasterObj
    end
    
    
    
    methods (Abstract) 
        create_gui(obj)
        run_analysis(obj,FileQueueObj)
    end
    
    methods
        function obj = AnalysisGUI()
        end
        
        function create_run(obj)
            h = uibutton(obj.parent);
            h.Text = 'Run';
            h.ButtonPushedFcn = @obj.run_analysis;
            obj.handles.Run = h;
        end
        
        function h = create_parameter_table(obj,parent,data)
            fn = fieldnames(data);
            dv = struct2cell(data);
            ind = cellfun(@isnumeric,dv);
            dv(ind) = cellfun(@mat2str,dv(ind),'uni',0);
            d = [fn, dv];
            
            c = cellfun(@class,dv,'uni',0);
            c(ind) = {'numeric'};
            c = c(:)';
            
            
            h = uitable(parent);
            h.Data = d;
            h.UserData = data;
            h.FontSize = 12;
            h.ColumnEditable = [false true];
            h.ColumnFormat = c;
            h.RowName = {};
%             h.CellEditCallback = @obj.verify_parameters;
        end
    end
    
    methods (Static)
        function cfg = tabledata_to_cfg(hObj)
            ud = hObj.UserData;
            data = hObj.Data;
            ind = structfun(@isnumeric,ud);
            data(ind,2) = cellfun(@str2num,data(ind,2),'uni',0);
            cfg = cell2struct(data(:,2),data(:,1));
        end
    end
    
    
end