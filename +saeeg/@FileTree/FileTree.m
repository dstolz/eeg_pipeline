classdef FileTree < saeeg.GUIComponent
    
    
    properties (SetObservable = true)
        
    end
    
    properties (SetAccess = protected)
        hFileNode
        hDirNode
        hFileTree        
        hHeaderBox
        hDataRoot
        hOutputPath
    end
    
    properties (Dependent)        
        SelectedFiles
        NSelected
    end
    
    events
        SelectionChanged
    end
    
    methods
        
        function obj = FileTree(MasterObj,ParentObj,Parent)
            if nargin < 3 || isempty(Parent), Parent = uifigure; end
            
            obj.MasterObj = MasterObj;
            obj.ParentObj = ParentObj;
            obj.Parent = Parent;
            
            obj.create;
            
            obj.populate_filetree;
        end
        
        function create(obj)
            g = uigridlayout(obj.Parent);
            g.RowHeight = {30,30,30,'1x'};%,150};
            g.ColumnWidth = {100,'1x'};
            obj.hGridLayout = g;
            
            
            h = uibutton(g);
            h.Layout.Row = 1;
            h.Layout.Column = 1;
            h.Tag = 'DataRoot';
            h.Text = 'Data Root:';
            h.ButtonPushedFcn = @obj.select_pathfield;
            h.Tooltip = 'Click to select DataRoot path';
            h.HorizontalAlignment = 'right';
            
            h = uieditfield(g);
            h.Layout.Row = 1;
            h.Layout.Column = 2;
            h.Tag = 'DataRoot';
            h.Value = obj.MasterObj.DataRoot;
            h.ValueChangedFcn = @obj.path_updated;
            h.Enable = 'off';
            obj.hDataRoot = h;
            
            
            h = uibutton(g);
            h.Layout.Row = 2;
            h.Layout.Column = 1;
            h.Tag = 'OutputPath';
            h.Text = 'Output Path:';
            h.ButtonPushedFcn = @obj.select_pathfield;
            h.Tooltip = 'Click to select OutputPath';
            h.HorizontalAlignment = 'right';
            
            h = uieditfield(g);
            h.Layout.Row = 2;
            h.Layout.Column = 2;
            h.Tag = 'OutputPath';
            h.Value = obj.MasterObj.OutputPath;
            h.ValueChangedFcn = @obj.path_updated;
            h.Enable = 'off';
            obj.hOutputPath = h;
            
            
            
            
            h = uilabel(g);
            h.Layout.Row = 3;
            h.Layout.Column = 2;
            h.Text = 'Initializing ...';
            obj.hHeaderBox = h;
            
            
            h = uitree(g);
            h.Layout.Row = 4;
            h.Layout.Column = [1 2];
            h.Tag = 'FileList';
            h.Multiselect = 'on';
            h.SelectionChangedFcn = @obj.tree_selection_updated;
            obj.hFileTree = h;
            
            
            % not sure why the caller function has to be specified in the
            % @(src,event)... format here?
            addlistener(obj.MasterObj,'DataRoot','PostSet',@obj.populate_filetree);
            addlistener(obj.MasterObj,'AnalysisState','PostSet',@obj.analysis_state);
        end
        
        
        
        function analysis_state(obj,src,event)
            switch obj.MasterObj.AnalysisState
                %["SETUP","READY","START","PROCESSING","PAUSED","STOPPING","FINISHED","ERROR"]
            end
        end
        
        
        
        function populate_filetree(obj,src,event)
            obj.hFileTree.Enable = 'off';
            ha = ancestor(obj.hFileTree,'figure');
            hap = ha.Pointer; % original pointer
            ha.Pointer = 'watch'; drawnow
            
            delete(obj.hFileNode);
            delete(obj.hDirNode);
            
            saeeg.vprintf(1,'Searching for files under DataRoot: "%s"',obj.MasterObj.DataRoot);
            d = dir(obj.MasterObj.DataRoot);
            d(startsWith({d.name},'.')|startsWith({d.name},'+')) = [];
            df = cellfun(@fullfile,{d.folder},{d.name},'uni',0);
            
            a = cellfun(@(a) dir(fullfile(a,'**/*')),df,'uni',0);

%             obj.hHeaderBox.Text = sprintf('%d directories with a total of %d files found',length(d),sum(cellfun(@numel,s))); drawnow
            [~,DirM] = ipticondir;
            iconFolder = fullfile(DirM,'foldericon.gif');
            iconFile = fullfile(DirM,'file_new.png');
            
            s = sum(cellfun(@(a) sum([a.isdir]),a));
            obj.hDirNode = gobjects(s,1);
            s = sum(cellfun(@(a) sum(~[a.isdir]),a));
            obj.hFileNode = gobjects(s,1);
            
            kDir = 1;
            kFile = 1;
            for i = 1:length(a)
                
                fn = {a{i}.name};
                ind = startsWith(fn,'.')|startsWith(fn,'+'); % ignore directories with '.' or '+' prefix
                a{i}(ind) = [];
                fn(ind) = [];
                ffn = cellfun(@fullfile,{a{i}.folder},fn,'uni',0);

                aisdir = [a{i}.isdir];
                
                saeeg.vprintf(4,'FileTree: Adding main dir: "%s"',df{i})
                h = uitreenode(obj.hFileTree,'Text',d(i).name, ...
                    'NodeData',df{i}, ...
                    'UserData',ffn(~aisdir), ...
                    'Icon',iconFolder);
                obj.hDirNode(kDir) = h;
                kDir = kDir + 1;
                

                for j = 1:length(ffn)
                    if aisdir(j)
                        saeeg.vprintf(4,'FileTree: Adding dir: "%s"',ffn{j})
                        ind = startsWith(ffn,ffn(j)) & ~aisdir;
                        obj.hDirNode(kDir) = uitreenode(h, ...
                            'Text',fn{j}, ...
                            'NodeData',ffn{j}, ...
                            'UserData',ffn(ind), ...
                            'Icon',iconFolder);
                        kDir = kDir + 1;
                    else
                        nd = get(obj.hDirNode(1:kDir-1),'NodeData');
                        ind = ismember(nd,{a{i}(j).folder});
                        saeeg.vprintf(4,'FileTree: Adding file: "%s" under: "%s"',ffn{j},obj.hDirNode(ind).NodeData)
                        obj.hFileNode(kFile) = uitreenode(obj.hDirNode(ind), ...
                            'Text',fn{j},'NodeData',ffn{j}, ...
                            'Icon',iconFile);
                        kFile = kFile + 1;
                    end
                end
            end
            
            obj.hFileTree.Enable = 'on';
            ha.Pointer = hap; drawnow
        end
        
        
        function select_pathfield(obj,src,event)
            p = obj.MasterObj.(src.Tag);
            d = uigetdir(p,sprintf('Select %s',src.Tag));
            figure(ancestor(src,'figure'));
            if isequal(d,0), return; end
            obj.path_updated(src,d);
        end
        
        
        function path_updated(obj,src,event)
            if isequal(src.Type,'uibutton')
                % redirect to text field; event is new path
                src = obj.(sprintf('h%s',src.Tag));
                src.Value = event;
            end
            
            try
                obj.MasterObj.(src.Tag) = src.Value;
                obj.MasterObj.field_indicator(src,'a');
            catch me
                obj.MasterObj.field_indicator(src,'r');
                saeeg.vprintf(0,1,'Invalid path');
            end
        end
        
        
        
        function tree_selection_updated(obj,src,event)
            
            sn = obj.hFileTree.SelectedNodes;
            if isempty(sn), return; end
            h = findobj(sn,'type','uitreenode');
            collapse(obj.hFileTree,'all')
            arrayfun(@expand,h);
            ind = arrayfun(@(a) isempty(a.UserData),h);
            obj.hFileTree.SelectedNodes = h(ind);
            
            obj.hHeaderBox.Text = sprintf('%d files selected',obj.NSelected);            
            
            ev = saeeg.evSelectionEventData(h(ind));
            notify(obj,'SelectionChanged',ev);
            
            
            if obj.NSelected > 0
                newState = saeeg.enAnalysisState.READY;
            else
                newState = saeeg.enAnalysisState.SETUP;
            end
            
            try
                obj.ParentObj.update_analysis_state(newState);
            end
        end
        
        
        
        
        function sf = get.SelectedFiles(obj)
            sn = obj.hFileTree.SelectedNodes;
            if isempty(sn)
                sf = {};
                return
            end
            ind = cellfun(@isempty,{sn.NodeData});
            sn(ind) = [];
            sf = {sn.NodeData}';
        end
        
        function n = get.NSelected(obj)
            n = length(obj.SelectedFiles);
        end
        
    end
    
    
    
end