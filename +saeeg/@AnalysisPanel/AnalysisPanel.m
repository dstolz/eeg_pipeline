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
            h.FontWeight = 'bold';
            h.ButtonPushedFcn = @obj.analysis_state_button;
            h.Enable = 'off';
            obj.hStateButton = h;
            
            h = uipanel(g);
            h.Layout.Row = 2;
            h.Layout.Column = [1 2];
            obj.hPanel = h;
            
            obj.update_analyses;
            
            obj.update_current_analysis;
            
            obj.analysis_state(obj.MasterObj.AnalysisState);
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
                obj.CurrentAnalysisGUI = caFnc(obj.MasterObj,obj.hPanel);
                obj.CurrentAnalysisGUI.create_gui;
            end

        end
        
        function update_analyses(obj,src,event)
            
            h = obj.hAnalysisDropdown;
            
            fh = ancestor(h,'figure');
            fhap = fh.Pointer;
            fh.Pointer = 'watch'; drawnow
            
            if isempty(obj.DataType)
                h.Enable = 'off';
                obj.hStateButton.Enable = 'off';
                fh.Pointer = fhap;
                return
            end
            
            [va,vafcn] = obj.MasterObj.get_valid_analyses(obj.DataType);
            
            h.Items = va;
            h.ItemsData = vafcn;
            h.Enable = 'on';

            obj.hStateButton.Enable = 'on';
            
            obj.update_current_analysis;
            
            
            fh.Pointer = fhap;
        end
        
        function analysis_state_button(obj,src,event)
            switch src.Text
                case 'Run'
                    newState = "START";
                    
                case 'Stop After File'
                    newState = "STOP";
                    
                case 'Resume'
                    newState = "RESUME";
                    
                case 'Setting up'
                    saeeg.vprintf(0,1,'Must first select file(s) and analysis')
                    return
                    
                case 'Reset After Error'
                    newState = "READY";
            end
            
            obj.ParentObj.update_analysis_state(newState);
        end
        
        function analysis_state(obj,src,event)
            h = obj.hStateButton;                     
            
            h.Enable = 'on';
            switch obj.MasterObj.AnalysisState
                % saeeg.enAnalysisState.list
                case "ERROR"
                    h.Enable = 'off';
                    h.Text = 'Reset After Error';
                    h.BackgroundColor = '#D40000';
                    
                case "SETUP"
                    h.Enable = 'off';
                    h.Text = 'Setting up';
                    h.Enable = 'off';
                    h.BackgroundColor = '#FFFFA9';
                    
                case "READY"
                    h.Enable = 'on';
                    h.Text = 'Run';
                    h.BackgroundColor = '#A9FFA8';
                    
                case "PAUSED"
                    h.Text = 'Resume';
                    h.BackgroundColor = '#FFDA65';
                    
                case {"START","PROCESSING"}
                    h.Text = 'Stop After File';
                    h.Tooltip = ["Clicking 'Stop' will cancel analysis after current file is complete"; ...
                                 "Use 'Ctrl+C' in command window to interrupt analysis"];
                    h.BackgroundColor = '#FF8E76';
                    saeeg.vprintf(1,1,'Clicking ''Stop'' will cancel analysis after current file is complete')
                    saeeg.vprintf(1,1,'Use ''Ctrl+C'' in command window to interrupt analysis');
                    
                case "ERROR"
                    h.Text = 'Reset';
                    h.BackgroundColor = 'D40000';
                    
                case {"STOP","FINISHED"}
                    h.Enable = 'on';
                    h.Text = 'Run';
                    h.BackgroundColor = '#A9FFA8';
                    h.Tooltip = "";
                    
            end
            drawnow
            
            
        end
        
        
        
        function ca = get.CurrentAnalysis(obj)
            ca = obj.hAnalysisDropdown.Value;
        end


    end
    
    
end