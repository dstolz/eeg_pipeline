classdef BatchGUI < saeeg.GUIComponent
    
    properties
        FileTreeObj
        AnalysisPanelObj
    end
    
    properties (Dependent)
        curDataFileType
        curDataFileQueue
        curAnalysisType
    end
    
    properties (SetAccess = private)
        hMainGridLayout
        
        hAnalysisListener
    end
    
    properties (Dependent)
        
        
    end
    
    properties (SetAccess = private, Hidden = true)
        
        
    end
    
    events
        
    end
    
    methods
        function obj = BatchGUI(Parent)
            saeeg.vprintf(3,'Building BatchGUI')
            
            if nargin > 1 && ~isempty(Parent), obj.Parent = Parent; end
            
            
            obj.MasterObj = saeeg.MasterObj;
            
            obj.MasterObj.eeg_preamble;
            %
            %             % Check if everything is ready for a state change
            %             addlistener(obj.MasterObj,'AnalysisState','PostSet',@obj.analysis_state);
            
            
            obj.create_figure; % uses parent if specified
            
            obj.create_layout;
            
            obj.gui_disable;
            
            obj.create_analysis_panel;
            
            obj.create_filetree;
            
            obj.create_menu;
            
            obj.finish_setup;
            
            % link the FileTree and AnalysisPanel objects
            addlistener(obj.FileTreeObj,'SelectionChanged',@obj.update_analysis_panel);
            
            obj.gui_enable;
            
            
            if nargout == 0, clear obj; end
            
            saeeg.vprintf(3,'Finished Building BatchGUI')
        end
        
        
        function update_analysis_state(obj,newState)
            % curState = obj.MasterObj.AnalysisState;

            M = obj.MasterObj;
            
            try
                M.AnalysisState = newState;
            catch me
                saeeg.vprintf(0,1,me)
                return
            end
            
            
            switch newState
                case "START"
                    M.FileQueueObj = saeeg.FileQueue(obj.FileTreeObj.SelectedFiles,M.OutputPath);
                    
                    M.FileQueueObj.OverwriteExisting = M.OverwriteExisting;
                    
                    delete(obj.hAnalysisListener);
                    h = addlistener(M.FileQueueObj,'UpdateAvailable',@obj.process_queue);
                    h.Recursive = 1;
                    obj.hAnalysisListener = h;
                    
                    ca = obj.AnalysisPanelObj.CurrentAnalysis;
                    
                    saeeg.vprintf(1,'Attempting to run analysis: %s',func2str(ca))
                    
                    obj.update_analysis_state("PROCESSING");
                    
                case "PROCESSING"
                    saeeg.vprintf(1,'Begin Processing %d files ...',M.FileQueueObj.NRemaining)
                    M.FileQueueObj.start_next;
                    
                case "STOP"
                    saeeg.vprintf(1,1,'Analysis stopped by user')
                    delete(obj.hAnalysisListener);

                case "FINISHED"
                    saeeg.vprintf(1,'Analysis completed')
                    delete(obj.hAnalysisListener);

                case "ERROR"
                    saeeg.vprintf(0,1,'Analysis failed on file: "%s"',M.FileQueueObj.CurrentFile)
                    delete(obj.hAnalysisListener);
            end
            
        end
        
        
        
        function process_queue(obj,src,event)
            
            drawnow
            if obj.MasterObj.AnalysisState == "STOP"
                saeeg.vprintf(0,1,'User stopped analysis.')
                return
            end
            
            Q = obj.MasterObj.FileQueueObj;
            
            d = event.Data;
            switch event.NewState
                case "STARTNEXT"
                    try
                        if obj.MasterObj.AnalysisState > 8
                            return
                        end
                        saeeg.vprintf(1,'Starting file %d, %d remaining. "%s"',d.FileIndex,d.NRemaining,d.FileStarting)
                        obj.AnalysisPanelObj.CurrentAnalysisGUI.run_analysis(Q);
                    catch me
                        saeeg.vprintf(0,1,me);
                        obj.update_analysis_state("ERROR");
                    end
                    
                case "FILEPROCESSED"
                    [h,m,s] = hms(seconds(d.ProcessDuration));
                    saeeg.vprintf(1,'Completed file %d in %d h %d m %d s: %s',d.FileIndex,h,m,round(s),d.FileCompleted)
                    
                case "FINISHED"
                    [h,m,s] = hms(d.TotalDurationSeconds);
                    saeeg.vprintf(1,'Processed %d files in %d h %d m %d s',d.NCompleted,h,m,s)
                    obj.MasterObj.AnalysisState = "FINISHED";                    
                    % this is slow. is there a faster way to refresh?
                    obj.FileTreeObj.populate_filetree; 
            end
            
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
            obj.FileTreeObj = saeeg.FileTree(obj.MasterObj,obj,obj.hMainGridLayout);
            obj.FileTreeObj.Layout.Row = 1;
            obj.FileTreeObj.Layout.Column = 1;
        end
        
        function create_analysis_panel(obj)
            obj.AnalysisPanelObj = saeeg.AnalysisPanel(obj.MasterObj,obj,obj.hMainGridLayout);
            obj.AnalysisPanelObj.Layout.Row = 1;
            obj.AnalysisPanelObj.Layout.Column = 2;
        end
        
        function create_menu(obj)
            f = ancestor(obj.Parent,'figure');
            m = uimenu(f,'Text','Settings');
            
            dflt = getpref('saeeg','SensorLayout','biosemi64.lay');
            mi(1) = uimenu(m,'Text',sprintf('Sensor Layout: "%s"',dflt),'Tag','SensorLayout');
            
            
            dflt = getpref('saeeg','GVerbosity',2);
            mi(end+1) = uimenu(m,'Text',sprintf('Verbosity: %d',dflt),'Tag','GVerbosity');
            
            dflt = getpref('saeeg','OverwriteExisting',false);
            mi(end+1) = uimenu(m,'Text','Overwrite existing files','Tag','OverwriteExisting', ...
                'Checked',dflt);
            obj.MasterObj.OverwriteExisting = dflt;
            
            
            
            mi(end+1) = uimenu(m,'Text','Open Log','Tag','OpenLog');            
            
            
            set(mi,'MenuSelectedFcn',@obj.menu_processor);
            
            
            
        end
        
        
        function menu_processor(obj,src,event)
            global GVerbosity GLogFID
            
            switch src.Tag
                case 'SensorLayout'
                    lay = obj.MasterObj.eeg_available_layouts;
                    
                    dflt = getpref('saeeg','SensorLayout','biosemi64.lay');
                    idx = find(ismember(lay,dflt));
                    if isempty(idx), idx = 1; end
                    
                    [idx,tf] = listdlg('ListString',lay, ...
                        'PromptString','Select a sensor layout:', ...
                        'SelectionMode','single', ...
                        'InitialValue',idx);
                    
                    if ~tf, return; end
                    
                    obj.MasterObj.update_sensor_layout(lay{idx});
                    
                    src.Text = sprintf('Sensor Layout: "%s"',lay{idx});
                    
                    setpref('saeeg','SensorLayout',lay{idx});
                    
                    saeeg.vprintf(1,'Sensor layout file: "%s"',lay{idx})
                    
                case 'GVerbosity'
                    v = {'0 - Stealth', ...
                        '1 - Normal', ...
                        '2 - Informative', ...
                        '3 - Annoying', ...
                        '4 - Insanity'};
                    
                    idx = min(GVerbosity + 1,5);
                    
                    [idx,tf] = listdlg('ListString',v, ...
                        'PromptString','Select verbosity:', ...
                        'SelectionMode','single', ...
                        'InitialValue',idx);
                    
                    if ~tf, return; end
                    
                    GVerbosity = idx - 1;
                    
                    src.Text = sprintf('Verbosity: "%s"',v{GVerbosity+1});
                    
                    setpref('saeeg','GVerbosity',GVerbosity);
                    
                    saeeg.vprintf(GVerbosity,'Verbosity set to: %s',v{GVerbosity+1});
                    
                case 'OverwriteExisting'
                    src.Checked = ~src.Checked;
                    setpref('saeeg','OverwriteExisting',src.Checked);
                    
                    obj.MasterObj.OverwriteExisting = isequal(src.Checked,'on');
                    
                    saeeg.vprintf(1,'OverwriteExisting set to "%s"',src.Checked)
                    
                    
                case 'OpenLog'
                    saeeg.vprintf(1,'Opening current log: "%s"',fopen(GLogFID));
                    saeeg.vprintf(-1,'OPENLOG');
            end
            figure(ancestor(src,'figure'));
        end
        
        
        
        
        
        function finish_setup(obj)
            lay = getpref('saeeg','SensorLayout','biosemi64.lay');
            obj.MasterObj.update_sensor_layout(lay);
        end
        
        
        function update_analysis_panel(obj,src,event)
            obj.gui_disable;
            obj.AnalysisPanelObj.reset;
            dt = obj.MasterObj.get_datatype(event.Filenames{1});
            obj.AnalysisPanelObj.DataType = dt;
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




