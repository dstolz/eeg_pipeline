classdef BatchGUI < saeeg.GUIComponent
    
    properties        
        objFileTree
        objAnalysisPanel
    end
    
    properties (Dependent)
        curDataFileType
        curDataFileQueue
        curAnalysisType
    end

    properties (SetAccess = private)
        hMainGridLayout
    end
    
    properties (Dependent)
        
        
    end
    
    properties (SetAccess = private, Hidden = true)
        
        
    end
    
    events
        
    end
    
    methods
        function obj = BatchGUI(Parent)
            if nargin > 1 && ~isempty(Parent), obj.Parent = Parent; end
            
            obj.MasterObj = saeeg.MasterObj;
%             
%             % Check if everything is ready for a state change
%             addlistener(obj.MasterObj,'AnalysisState','PostSet',@obj.analysis_state);            
 
            
            obj.create_figure; % uses parent if specified
            
            obj.create_layout;
            
            obj.gui_disable;
            
            obj.create_analysis_panel;
            
            obj.create_filetree;
            
            % link the FileTree and AnalysisPanel objects
            addlistener(obj.objFileTree,'SelectionChanged',@obj.update_analysis_panel);
            
            
            obj.gui_enable;
            
            
            if nargout == 0, clear obj; end
                        
        end

        
        function update_analysis_state(obj,newState)
            % see if everyone is ready for the state update            
            curState = obj.MasterObj.AnalysisState;
            
%             if curState > 1 && curState < 9 && isempty(obj.curDataFileQueue) 
%                 return
%             end
            
            try
                obj.MasterObj.AnalysisState = newState;
            catch me
                saeeg.vprintf(0,1,me)
                return
            end
            
            switch newState
                case "START"
                    obj.MasterObj.FileQueueObj = saeeg.FileQueueObj(obj.curFileQueue);
                    
                    addlistener(obj.MasterObj.FileQueueObj,'UpdateAvailable',@obj.process_queue);
                    
                    obj.MasterObj.FileQueueObj.start_next;
            end
            
        end
        
        function q = get.curDataFileQueue(obj)
            % queue obj?
        end
        
        
        function process_queue(obj,src,event)
            disp(event)
        end
        
    end
    
    
    methods (Access = private)
        function create_figure(obj)
            if isempty(obj.Parent)
                obj.Parent = uifigure('Name','BatchGUI');
            end
            f = ancestor(obj.Parent,'figure'); % may be parent
            
            f.Position([3 4]) = [1000 500];
            
            movegui(f,'onscreen');
            
        end
        
        
        function create_layout(obj)
            p = obj.Parent;
            
            g = uigridlayout(p);
            g.RowHeight = {'1x'};
            g.ColumnWidth = {500,'1x'};
            
            obj.hMainGridLayout = g;
            
        end
        
        function create_filetree(obj)
            obj.objFileTree = saeeg.FileTree(obj.MasterObj,obj,obj.hMainGridLayout);
            obj.objFileTree.Layout.Row = 1;
            obj.objFileTree.Layout.Column = 1;
        end
        
        function create_analysis_panel(obj)
            obj.objAnalysisPanel = saeeg.AnalysisPanel(obj.MasterObj,obj,obj.hMainGridLayout);
            obj.objAnalysisPanel.Layout.Row = 1;
            obj.objAnalysisPanel.Layout.Column = 2;
        end
       
        
        function update_analysis_panel(obj,src,event)
            obj.gui_disable;
            obj.objAnalysisPanel.reset;
            dt = obj.MasterObj.get_datatype(event.Filenames{1});
            obj.objAnalysisPanel.DataType = dt;
            obj.gui_enable;
        end
        
        
        function gui_enable(obj)
            obj.Parent.Pointer = 'arrow';
            h = findobj(obj.hMainGridLayout.Children,'-property','Enable');
            set(h,'Enable','on');
            drawnow
        end
        
        function gui_disable(obj)
            obj.Parent.Pointer = 'watch';
            h = findobj(obj.hMainGridLayout.Children,'-property','Enable');
            set(h,'Enable','off');
            drawnow
        end
    end
    
end




