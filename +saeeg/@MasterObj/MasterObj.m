classdef (Hidden) MasterObj < handle
    % One class to rule them all
    
    properties (SetObservable,AbortSet)
        DataRoot   (1,1) string 
        OutputPath (1,1) string 
        FilePattern (1,:) char
        
        AnalysisState (1,1) saeeg.enAnalysisState = 1;
        
        SensorLayout
        
        OverwriteExisting (1,1) logical = false;
    end
    
    properties
        FileQueueObj (1,1) saeeg.FileQueue
    end
    
    properties (Dependent)
        AvailableAnalyses
        AvailableAnalysesFcn
    end
    
    properties (SetAccess = immutable)
        SoftwareRoot = fileparts(fileparts(mfilename('fullpath')));
    end
    
    properties (Constant)
        Version = '22A';
    end
    
    
    events

    end
    
    methods
        function set.AnalysisState(obj,newState)
            % saeeg.enAnalysisState enumerated class
            % ERROR       (0)
            % SETUP       (1)
            % READY       (2)
            % START       (3)
            % PROCESSING  (4)
            % PAUSED      (5)
            % RESUME      (6)
            % STOP        (7)
            % STOPPING    (8)
            % FINISHED    (9)

            prevState = obj.AnalysisState;
%             if obj.AbortUpdateAnalysisState
%                 saeeg.vprintf(4,'Updating from %s(%d) -> %s(%d) aborted\n',prevState,prevState,newState,newState)
%                 obj.AbortUpdateAnalysisState = false;
%                 return
%             end
            
            test = true;
            if newState > 0 && prevState < 9 && newState ~= 6 && ~any(prevState ~= [5 6])
                % most new states must ascend
                test = prevState < newState;
            
            elseif prevState == 6 % resume -> processing
                test = newState == 4;
                
            elseif prevState == 5 || newState == 6 % paused or resume -> any state
                % can go to any other state
                test = true;
                
            elseif prevState == 9 % finished -> error|setup
                test = true;
                
            elseif prevState == 255 % error -> setup
                test = newState < 3;
                
            end
            
            assert(test, 'saeeg:MasterObj:AnalysisState:InvalidNewState', ...
                    'States must be updated in the correct order');
                
            saeeg.vprintf(4,'AnalysisState: %s (%d) -> %s (%d)',prevState,prevState,newState,newState)
            
            obj.AnalysisState = newState;

        end
        
        function update_sensor_layout(obj,lay)
            obj.eeg_preamble;
            
            cfg = [];
            cfg.layout = lay;
            obj.SensorLayout = ft_prepare_layout(cfg);
        end
        
        function aa = get.AvailableAnalyses(obj)
            aa = dir(fullfile(obj.SoftwareRoot,'+agui'));
            aa = {aa.name};
            aa(startsWith(aa,'.')) = [];
            aa(ismember(aa,'AnalysisGUI.m')) = [];
            aa = cellfun(@(a) a(1:end-2),aa,'uni',0);
        end
        
        function fa = get.AvailableAnalysesFcn(obj)
            aa = obj.AvailableAnalyses;
            fa = cellfun(@(a) str2func(['saeeg.agui.' a]),aa,'uni',0);
        end
        
        function [va,vafcn] = get_valid_analyses(obj,datatype)
            aa = obj.AvailableAnalyses;
            ind = startsWith(aa,datatype);
            va = aa(ind);
            
            af = obj.AvailableAnalysesFcn;
            vafcn = af(ind);
        end
        
        
        function set.FilePattern(obj,p)
            if isempty(p), p = '**/*'; end
            
            obj.FilePattern = p;
            
            setpref('saeeg','FilePattern',p);
            saeeg.vprintf(1,'New File Pattern specified: "%s"',p)
        end
        
        
        function p = get.FilePattern(obj)
            p = obj.FilePattern;
            if isempty(p)
                p = getpref('saeeg','FilePattern','**/*');
            end
        end
        
        
        function set.DataRoot(obj,p)
            assert(isfolder(p),'saeeg:MasterObj:DataRoot:InvalidPath', ...
                '"%s" is an invalid path',strrep(p,'\','\\'));
            
            obj.DataRoot = p;
            setpref('saeeg','DataRoot',p);
            
            saeeg.vprintf(1,'New Data Root path specified: "%s"',p)
        end

        
        function p = get.DataRoot(obj)
            p = obj.DataRoot;
            if ~isfolder(p)
                p = getpref('saeeg','DataRoot',cd);
            end
            
            if ~isfolder(p)
                p = uigetdir('','Select DataRoot');
            end
            obj.DataRoot = p;
        end
        
        
        function set.OutputPath(obj,p)
            try
                if ~isfolder(p)
                    mkdir(p);
                    saeeg.vprintf('New OutputPath specified: %s',p)
                end
            end
            
            assert(isfolder(p),'saeeg:MasterObj:OutputPath:InvalidPath', ...
                '"%s" is an invalid path',p);
            
            obj.OutputPath = p;
            setpref('saeeg','OutputPath',p);
            
            saeeg.vprintf(1,'New output path specified: "%s"',p)
        end
        
        
        function p = get.OutputPath(obj)
            p = obj.OutputPath;
            if ~isfolder(p)
                p = getpref('saeeg','OutputPath',cd);
            end
            
            if ~isfolder(p)
                p = uigetdir('','Select OutputPath');
            end
            obj.OutputPath = p;
        end
        
    end
    
    
    methods (Static)
        
        
        function eeg_preamble
            try
                ft_defaults;
            catch me
                saeeg.vprintf(0,1,me);
            end
        end
        
        function lay = eeg_available_layouts(pth)
            if nargin == 0 || isempty(pth)
                w = which('ft_defaults');
                [pth,~] = fileparts(w);
            end
            d = dir(fullfile(pth,'**\*.lay'));
            lay = {d.name};
        end
        
        function type = get_datatype(ffn)
            
            [~,~,ext] = fileparts(ffn);
            
            switch lower(ext)
                case '.bdf'
                    type = "biosemi";
                    
                case '.fig'
                    type = "fig";
                    
                case '.mat'
                    w = who('-file',ffn);
                    dataTypes = ["data","comp","freq","model"];
                    ind = ismember(dataTypes,w);
                    type = dataTypes(ind);
                    
                otherwise
                    type = '';
            end
        end
        
        function field_indicator(hObj,state)
            obg = hObj.BackgroundColor;
            ofc = hObj.FontColor;
            
            state = char(state);
            
            switch lower(state(1))
                case 'a'
                    bg = '#b0ffbc';
                    fc = '#000000';
                    
                case 'r'
                    bg = '#ffb3b9';
                    fc = '#ffffff';
                    
                otherwise
                    bg = obg;
                    fc = ofc;
            end
            
            hObj.BackgroundColor = bg;
            hObj.FontColor = fc;
            pause(1);
            hObj.BackgroundColor = obg;
            hObj.FontColor = ofc;
            
            
        end
        
        
        
    end
end