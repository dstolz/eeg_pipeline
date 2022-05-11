classdef (Hidden) AnalysisGUI < handle
    
    properties
        cfg
    end
    
    properties (SetAccess = immutable)
        
    end
    
    properties (SetAccess = protected)
        parent
        handles
    end
    
    methods
        function obj = AnalysisGUI()
%             obj.parent = parent;
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
            h.CellEditCallback = @obj.verify_parameters;
        end
        
        
    end
    
    
end