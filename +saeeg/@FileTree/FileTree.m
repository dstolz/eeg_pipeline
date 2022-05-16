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
        hFilePattern
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
            g.ColumnWidth = {100,100,'1x'};
            obj.hGridLayout = g;
            
            
            
            
            h = uibutton(g);
            h.Layout.Row = 1;
            h.Layout.Column = 1;
            h.Tag = 'DataRoot';
            h.Text = 'Data Source:';
            h.ButtonPushedFcn = @obj.select_pathfield;
            h.Tooltip = 'Click to select DataRoot path';
            h.HorizontalAlignment = 'right';
            
            h = uieditfield(g);
            h.Layout.Row = 1;
            h.Layout.Column = [2 3];
            h.Tag = 'DataRoot';
            h.Value = obj.MasterObj.DataRoot;
            h.ValueChangedFcn = @obj.path_updated;
            h.Enable = 'off';
            obj.hDataRoot = h;
            
            
            
            
            
            h = uibutton(g);
            h.Layout.Row = 2;
            h.Layout.Column = 1;
            h.Tag = 'OutputPath';
            h.Text = 'Analysis Output:';
            h.ButtonPushedFcn = @obj.select_pathfield;
            h.Tooltip = 'Click to select OutputPath';
            h.HorizontalAlignment = 'right';
            
            h = uieditfield(g);
            h.Layout.Row = 2;
            h.Layout.Column = [2 3];
            h.Tag = 'OutputPath';
            h.Value = obj.MasterObj.OutputPath;
            h.ValueChangedFcn = @obj.path_updated;
            h.Enable = 'off';
            obj.hOutputPath = h;
            
            
            
            
            
            
            h = uilabel(g);
            h.Layout.Row = 3;
            h.Layout.Column = 1;
            h.Text = 'File Pattern:';
            h.HorizontalAlignment = 'right';
            
            h = uieditfield(g);
            h.Layout.Row = 3;
            h.Layout.Column = 2;
            h.Tag = 'FilePattern';
            h.Value = obj.MasterObj.FilePattern;
            h.ValueChangedFcn = @obj.path_updated;
            h.Tooltip = 'Use pattern **/* to recursively search directories';
            h.Enable = 'off';
            h.HorizontalAlignment = 'center';
            obj.hFilePattern = h;
            
            
            
            
            h = uilabel(g);
            h.Layout.Row = 3;
            h.Layout.Column = 3;
            h.Text = 'Initializing ...';
            h.HorizontalAlignment = 'center';
            obj.hHeaderBox = h;
            
            
            
            
            
            h = uitree(g);
            h.Layout.Row = 4;
            h.Layout.Column = [1 3];
            h.Tag = 'FileList';
            h.Multiselect = 'on';
            h.SelectionChangedFcn = @obj.tree_selection_updated;
            obj.hFileTree = h;
            
            
            % not sure why the caller function has to be specified in the
            % @(src,event)... format here?
            addlistener(obj.MasterObj,{'DataRoot','FilePattern'},'PostSet',@obj.populate_filetree);
            addlistener(obj.MasterObj,'AnalysisState','PostSet',@obj.analysis_state);
        end
        
        
        
        function analysis_state(obj,src,event)
            switch obj.MasterObj.AnalysisState
                %["SETUP","READY","START","PROCESSING","PAUSED","STOPPING","FINISHED","ERROR"]
            end
        end
        
        
        
        function populate_filetree(obj,src,event)
            M = obj.MasterObj;
            
            obj.hFileTree.Enable = 'off';
            ha = ancestor(obj.hFileTree,'figure');
            hap = ha.Pointer; % original pointer
            ha.Pointer = 'watch'; drawnow
            
            try
                delete(obj.hFileTree.Children);
            end
                        
            saeeg.vprintf(1,'Searching for files under DataRoot: "%s"',fullfile(M.DataRoot,M.FilePattern));
            d = dir(fullfile(M.DataRoot,M.FilePattern));            
            d([d.isdir]) = [];
            dFilenames = {d.name};
            dFolders = {d.folder};
            dFiles = cellfun(@fullfile,dFolders,dFilenames,'uni',0);
                        
            udFolders = unique(dFolders);
            subFolders = cellfun(@(a) a(length(char(M.DataRoot))+1:end),udFolders,'uni',0);
            
            obj.hHeaderBox.Text = sprintf('%d directories with a total of %d files found',length(udFolders),length(d)); drawnow

            
            [~,DirM] = ipticondir;
            iconFolder = fullfile(DirM,'foldericon.gif');
            iconFile = fullfile(DirM,'file_new.png');
            
            obj.hDirNode = gobjects(0);
            for i = 1:length(subFolders)
                ind = endsWith(dFolders,subFolders{i});
                s = split(subFolders{i},filesep);
                s(cellfun(@isempty,s)) = [];
                
                for j = 1:length(s)
                    fpth = fullfile(M.DataRoot,s{1:j});
                    nd = get(obj.hDirNode,'NodeData');
                    nidx = [];
                    if ~isempty(nd)
                        nd = cellstr(nd);
                        nind = ismember(nd,char(fpth));
                        nidx = find(nind);
                    end
                    
                    if j == 1 && isempty(nidx)
                        h = obj.hFileTree;
                        
                    elseif isempty(nidx)
                        nidx = find(startsWith(nd,fileparts(fpth)));
                        [~,m] = min(cellfun(@numel,nd(nidx)));
                        nidx = nidx(m);
                        h = obj.hDirNode(nidx);
                    else
                        continue
                    end
                    
                	obj.hDirNode(end+1) = uitreenode(h, ...
                        'Text',s{j}, ...
                        'NodeData',fpth, ...
                        'UserData',dFiles(ind), ...
                        'Icon',iconFolder);
                end
            end
            
            nd = cellstr(get(obj.hDirNode,'NodeData'));
            
            for i = 1:length(nd)
                ind = ismember(dFolders,nd{i});
                if ~any(ind), continue; end
                
                x = dFilenames(ind);
                y = dFiles(ind);
                
                h = obj.hDirNode(i);
                
                for j = 1:length(x)
                    saeeg.vprintf(4,'FileTree: Adding file: "%s" under: "%s"',x{j},h.NodeData)

                    obj.hFileNode(end+1) = uitreenode(h, ...
                        'Text',x{j}, ...
                        'NodeData',y{j}, ...
                        'Icon',iconFile);
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