classdef AnalysisPanel < saeeg.GUIComponent
    
    properties (SetObservable)
        DataType
        CurrentAnalysisGUI
    end
    
    properties (SetAccess = protected)
        hAnalysisDropdown
        hStateButton
        hPanel
    end
    
    properties (Dependent)
        CurrentAnalysis
    end
    
    
    methods
        function obj = AnalysisPanel(MasterObj,ParentObj,Parent)
            obj.Parent = Parent;
            obj.MasterObj = MasterObj;
            obj.ParentObj = ParentObj;

            
            obj.create;
            
            addlistener(obj,'DataType','PostSet',@obj.update_analyses);
            addlistener(obj.MasterObj,'AnalysisState','PostSet',@obj.analysis_state);
        end
        
        
        function create(obj)
            g = uigridlayout(obj.Parent);
            g.ColumnWidth = {'1x','1x'};
            g.RowHeight   = {30,'1x'};
            obj.hGridLayout = g;
            
            h = uidropdown(g);
            h.Layout.Row = 1;
            h.Layout.Column = 1;
            h.Items = {};
            h.ItemsData = {};
            h.ValueChangedFcn = @obj.update_current_analysis;
            obj.hAnalysisDropdown = h;
            
            h = uibutton(g);
            h.Layout.Row = 1;
            h.Layout.Column = 2;
            h.Text = 'Run';
            h.ButtonPushedFcn = @obj.analysis_state;
            h.Enable = 'off';
            obj.hStateButton = h;
            
            h = uipanel(g);
            h.Layout.Row = 2;
            h.Layout.Column = [1 2];
            obj.hPanel = h;
            
            obj.update_analyses;
            
            obj.update_current_analysis;
        end
        
        function reset(obj)
            delete(obj.hPanel.Children)
        end
        
        
        function update_current_analysis(obj,src,event)

            caFnc = obj.CurrentAnalysis;
            try
                h = obj.CurrentAnalysisGUI.parent.Children;
                delete(h);
            end
            if ~isempty(caFnc)
                obj.CurrentAnalysisGUI = caFnc(obj.hPanel);
                obj.CurrentAnalysisGUI.create_gui;
            end

        end
        
        function update_analyses(obj,src,event)
            
            h = obj.hAnalysisDropdown;
            
            
            fh = ancestor(h,'figure');
            fh.Pointer = 'watch'; drawnow
            
            if isempty(obj.DataType)
                h.Enable = 'off';
                obj.hStateButton.Enable = 'off';
                return
            end
            
            
            [va,vafcn] = obj.MasterObj.get_valid_analyses(obj.DataType);
            
            h.Items = va;
            h.ItemsData = vafcn;
            h.Enable = 'on';

            obj.hStateButton.Enable = 'on';
            
            obj.update_current_analysis;
            
            
            fh.Pointer = 'arrow';
        end
        
        
        function analysis_state(obj,src,event)
            h = obj.hStateButton;
            
            if isequal(src.Name,'AnalysisState')
                
                switch obj.MasterObj.AnalysisState
                    % saeeg.enAnalysisState.list
                    case saeeg.enAnalysisState.ERROR
                        h.Enable = 'off';
                        h.Text = 'Reset After Error';
                    
                    case saeeg.enAnalysisState.SETUP
                        h.Enable = 'off';
                        h.Text = 'Run';
                        
                    case saeeg.enAnalysisState.READY
                        h.Enable = 'on';
                        h.Text = 'Run';
                        
                    case saeeg.enAnalysisState.PAUSED
                        h.Text = 'Resume';
                        
                    case [saeeg.enAnalysisState.START,saeeg.enAnalysisState.PROCESSING]
                        h.Text = 'Stop';
                        
                    case [saeeg.enAnalysisState.ERROR,saeeg.enAnalysisState.FINISHED]
                        h.Text = 'Reset';
                end
                
            else % gui
                
               switch h.Text
                   case 'Run'
                       newState = saeeg.enAnalysisState.START;
                       
                   case 'Stop'
                       newState = saeeg.enAnalysisState.STOP;
                       
                   case 'Resume'
                       newState = saeeg.enAnalysisState.RESUME;
               end
               
                obj.ParentObj.update_analysis_state(newState);
                
            end
            
            
        end
        
        
        
        function ca = get.CurrentAnalysis(obj)
            ca = obj.hAnalysisDropdown.Value;
        end


    end
    
    
end