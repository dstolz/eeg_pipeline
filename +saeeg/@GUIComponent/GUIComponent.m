classdef (Hidden) GUIComponent < handle
    
    properties (SetAccess = protected)
        hGridLayout
    end
    
    properties (Dependent)
        Layout
    end
    
    properties (SetAccess = protected)
        Parent
        ParentObj
        MasterObj
    end
    
    methods
        function set.Layout(obj,v)
            fn = fieldnames(v);
            for i = 1:length(fn)
                obj.hGridLayout.Layout.(fn{i}) = v.(fn{i});
            end
        end
        
        function layout = get.Layout(obj)
            layout = obj.hGridLayout.Layout;
        end
    end
end