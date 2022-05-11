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
        subdirs
        filelist
        
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
            
            
            h = uilabel(g);
            h.Layout.Row = 1;
            h.Layout.Column = 1;
            h.Text = 'Data Root:';
            h.HorizontalAlignment = 'right';
            
            h = uieditfield(g);
            h.Layout.Row = 1;
            h.Layout.Column = 2;
            h.Value = obj.MasterObj.DataRoot;
            h.ValueChangedFcn = @obj.path_updated;
            h.Enable = 'off';
            obj.hDataRoot = h;
            
            
            h = uilabel(g);
            h.Layout.Row = 2;
            h.Layout.Column = 1;
            h.Text = 'Output Path:';
            h.HorizontalAlignment = 'right';
            
            h = uieditfield(g);
            h.Layout.Row = 2;
            h.Layout.Column = 2;
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
            addlistener(obj.MasterObj,'DataRoot','PostSet',@(src,event) obj.tree_selection_updated(src,event));
            
            addlistener(obj.MasterObj,'AnalysisState','PostSet',@obj.analysis_state);
        end
        
        
        
        function analysis_state(obj,src,event)
            switch obj.MasterObj.AnalysisState
                %["SETUP","READY","START","PROCESSING","PAUSED","STOPPING","FINISHED","ERROR"]
            end
        end
        
        
        
        function populate_filetree(obj)
            obj.hFileTree.Enable = 'off';
            a = ancestor(obj.hFileTree,'figure');
            a.Pointer = 'watch'; drawnow
            delete(obj.hFileNode);
            delete(obj.hDirNode);
            obj.hFileNode = [];
            obj.hDirNode = [];

            
            d = obj.subdirs;
            s = obj.filelist;
            
            obj.hHeaderBox.Text = sprintf('%d directories with a total of %d files found',length(d),sum(cellfun(@numel,s))); drawnow
            
            for i = 1:length(d)
                h = uitreenode(obj.hFileTree,'Text',d{i});
                obj.hDirNode(i) = h;
                for j = 1:length(s{i})
                    obj.hFileNode(j) = uitreenode(h,'Text',s{i}{j},'NodeData',fullfile(obj.MasterObj.DataRoot,d{i},s{i}{j}));
                end
            end
            
            obj.hFileTree.Enable = 'on';
            a.Pointer = 'arrow'; drawnow
        end
        
        
        
        function path_updated(obj,src,event)
            
            try
                obj.MasterObj.OutputPath = src.Value;
                obj.MasterObj.field_indicator(src,'a');
            catch me
                obj.hOutputPath.Value = src;
                obj.MasterObj.field_indicator(src,'r');
            end
            
        end
        
        
        
        function tree_selection_updated(obj,src,event)
            
            sn = obj.hFileTree.SelectedNodes;
            if isempty(sn), return; end

            ind = ~cellfun(@isempty,{sn.NodeData});
            if all(ind) % individual files selected
                
                snc = sn;
                
            else % subdir selected - select all files
                
                collapse(obj.hFileTree,'all')
                
                arrayfun(@expand,sn);
                
                snc = sn.Children;
                if isempty(snc), return; end
                
                n = cellfun(@transpose,{snc},'uni',0);
                obj.hFileTree.SelectedNodes = [n{:}];
                
            end
            
            obj.hHeaderBox.Text = sprintf('%d files selected',obj.NSelected);            
            
            ev = saeeg.evSelectionEventData(snc);
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
        
        function d = get.subdirs(obj)
            d = dir(obj.MasterObj.DataRoot);
            d = {d.name};
            d(startsWith(d,'.')|startsWith(d,'+')) = []; % ignore directories with '.' or '+' prefix
        end
        
        function s = get.filelist(obj)
            d = obj.subdirs;
            a = dir(fullfile(obj.MasterObj.DataRoot,'**/*'));
            an = {a.name};
            af = {a.folder};
            an([a.isdir]) = [];
            af([a.isdir]) = [];
            s = cell(size(d));
            for i = 1:length(d)
                ind = endsWith(af,d{i});
                s{i} = an(ind);
            end
        end
        
        function sf = get.SelectedFiles(obj)
            sn = obj.hFileTree.SelectedNodes;
            ind = cellfun(@isempty,{sn.NodeData});
            sn(ind) = [];
            sf = {sn.NodeData}';
        end
        
        function n = get.NSelected(obj)
            n = length(obj.SelectedFiles);
        end
        
    end
    
    
    
end