classdef FileQueue < handle
    
    properties (SetObservable,AbortSet)
        Queue        (:,1) string
        ProcessOrder (1,1) string {mustBeMember(ProcessOrder,["serial","random"])} = "serial";
        
        OutputPath   (1,1) string
        
        NextIndex    (1,1) double
        
        OverwriteExisting (1,1) logical = false;
    end
    
    properties (SetAccess = private)
        ProcessStartTime (:,1) double
        ProcessEndTime   (:,1) double
    end    
    
    properties (Access = protected)
%         QueueTimer % maybe add for status
        CurrentIndex (1,1) double
    end
    
    properties (Dependent)
        N           (1,1) double
        NCompleted  (1,1) double
        NRemaining  (1,1) double
        Completed   (:,1) logical
        Processing  (:,1) logical
        ProcessDuration (:,1) double
        EstTotalRemaingSeconds (1,1) seconds
        TotalElapsedSeconds    (1,1) seconds
        PercCompleted (1,1) double
        CurrentFile     (1,1) string
        CurrentFilename (1,1) string
        CurrentFilepath (1,1) string
    end
    
    events
        UpdateAvailable
    end
    
    methods
        function obj = FileQueue(filenames,outpath)
            if nargin == 0 || isempty(filenames), return; end
            if nargin >= 1 && ~isempty(outpath), obj.OutputPath = outpath; end
            
            obj.add_to_queue(filenames);
        end
        
        
        function idx = start_next(obj)
            
            idx = obj.NextIndex;
            
            if ~isempty(idx) && idx > 0
                obj.ProcessStartTime(idx) = now;
            end
            
            obj.CurrentIndex = idx;
            
            d.Queue = obj.Queue;
            d.NCompleted = obj.NCompleted;
            d.NRemaining = obj.NRemaining;
            
            if idx > 0
                d.FileStarting = obj.Queue(idx);
                d.FileIndex    = idx;
                d.EstTotalRemaingSeconds = obj.EstTotalRemaingSeconds;
                d.TotalDurationSeconds = obj.TotalElapsedSeconds;
            end
            ev = saeeg.evFileQueueUpdated("STARTNEXT",d);
            notify(obj,'UpdateAvailable',ev);
        end
        
        function mark_completed(obj,idx)
            if nargin == 1 || isempty(idx), idx = obj.CurrentIndex; end
            
            obj.ProcessEndTime(idx) = now;
                        
            d.Queue = obj.Queue;
            d.FileCompleted = obj.Queue(idx);
            d.FileIndex    = idx;
            d.NCompleted = obj.NCompleted;
            d.NRemaining = obj.NRemaining;
            d.ProcessDuration = obj.ProcessDuration(idx);
            d.EstTotalRemaingSeconds = obj.EstTotalRemaingSeconds;
            d.TotalDurationSeconds = obj.TotalElapsedSeconds;
            ev = saeeg.evFileQueueUpdated("FILEPROCESSED",d);
            notify(obj,'UpdateAvailable',ev);
            
            if all(obj.Completed)
                d.Queue = obj.Queue;
                d.NCompleted = obj.NCompleted;
                d.TotalDurationSeconds = obj.TotalElapsedSeconds;
                ev = saeeg.evFileQueueUpdated("FINISHED",d);
                notify(obj,'UpdateAvailable',ev);
            end
        end
        
        function q = add_to_queue(obj,filenames)
            
            filenames = string(filenames);
            filenames = filenames(:);
            
            %%% skip assertion; can take way too long to get going
%             assert(all(isfile(filenames)),'saeeg:FileQueue:add_to_queue:InvalidFile', ...
%                 'One or more files do not exist')
                
            
            obj.Queue = [obj.Queue; filenames];
            obj.ProcessStartTime(obj.N) = 0;
            obj.ProcessEndTime(obj.N)   = 0;
            
            q = obj.Queue;
            
            d.Queue = q;
            d.NewFiles = filenames;
            ev = saeeg.evFileQueueUpdated("FILESADDED",d);
            notify(obj,'UpdateAvailable',ev);
        end
        
        
        function idx = get.NextIndex(obj)
            idx = obj.NextIndex;
            
            ind = ~obj.Completed;
            
            if ~any(ind), return; end
            if ismember(find(ind),idx), return; end
            
            switch obj.ProcessOrder
                case "serial"
                    idx = find(ind,1);
                    
                case "random"
                    idx = find(ind);
                    idx = idx(randi(length(idx),1));
            end
            
        end
      
        
        function set.OutputPath(obj,p)
            if ~isfolder(p)
                try
                    mkdir(p);
                    saeeg.vprintf(1,'Created output path: "%s"',p)
                catch me
                    saeeg.vprintf(0,1,me)
                    return
                end
            end
            
            obj.OutputPath = p;
            saeeg.vprintf(1,'Output path set to: "%s",p')
        end
        
        function n = get.N(obj)
            n = length(obj.Queue);
        end
        
        function n = get.NCompleted(obj)
            n = sum(obj.Completed);
        end
        
        function n = get.NRemaining(obj)
            n = obj.N - obj.NCompleted;
        end
        
        function c = get.Completed(obj)
            c = obj.ProcessEndTime > 0;
        end
        
        function p = get.Processing(obj)
            p = obj.ProcessStartTime > 0 && obj.ProcessEndTime == 0;
        end
        
        function d = get.ProcessDuration(obj)
            d = etime(datevec(obj.ProcessEndTime),datevec(obj.ProcessStartTime));
        end
        
        function s = get.EstTotalRemaingSeconds(obj)
            s = mean(obj.ProcessDuration) .* obj.NRemaining;
            s = seconds(s);
        end
        
        function t = get.TotalElapsedSeconds(obj)
            t = seconds(etime(datevec(max(obj.ProcessStartTime)),datevec(min(obj.ProcessStartTime))));
        end
        
        function p = get.PercCompleted(obj)
            p = obj.NCompleted ./ obj.N .* 100;
        end
        
        function f = get.CurrentFile(obj)
            f = obj.Queue(obj.CurrentIndex);
        end
        
        function f = get.CurrentFilename(obj)
            [~,f] = fileparts(obj.Queue(obj.CurrentIndex));
        end
        
        function p = get.CurrentFilepath(obj)
            [p,~] = obj.Queue(obj.CurrentIndex);
        end
        
        function idx = get.CurrentIndex(obj)
            if isempty(obj.CurrentIndex) || obj.CurrentIndex == 0
                obj.CurrentIndex = obj.start_next;
            end
            idx = obj.CurrentIndex;
        end
        
    end
    
    methods (Access = protected)
        
    end
    
    methods (Access = private)
        
        
    end
end