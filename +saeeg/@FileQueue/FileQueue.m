classdef FileQueue < handle
    
    properties (SetObservable,AbortSet)
        Queue        (:,1) string
        ProcessOrder (1,1) string {mustBeMember(ProcessOrder,["serial","random"])} = "serial";
        
        NextIndex    (1,1) double
    end
    
    properties (SetAccess = private)
        ProcessStartTime (:,1) double
        ProcessEndTime   (:,1) double
    end    
    
    properties (Access = protected)
%         QueueTimer % maybe add for status
    end
    
    properties (Dependent)
        N           (1,1) double
        NCompleted  (1,1) double
        NRemaining  (1,1) double
        Completed   (:,1) logical
        Processing  (:,1) logical
        ProcessDuration (:,1) double
        EstTotalRemaingSeconds (1,1) seconds
        PercCompleted (1,1) double
    end
    
    events
        UpdateAvailable
    end
    
    methods
        function obj = FileQueue(filenames)
            if nargin == 0 || isempty(filenames), return; end
            
            obj.add_to_queue(filenames);
        end
        
        
        function index = start_next(obj)
            index = obj.NextIndex;
            
            if ~isempty(index)
                obj.ProcessStartTime(index) = now;
                
            end
            
            d.Queue = obj.Queue;
            d.FileStarting = obj.Queue(index);
            d.FileIndex    = index;
            d.NCompleted = obj.NCompleted;
            d.NRemaining = obj.NRemaining;
            d.EstTotalRemaingSeconds = obj.EstTotalRemaingSeconds;
            d.TotalDurationSeconds = seconds(etime(datevec(max(obj.ProcessStartTime)),datevec(min(obj.ProcessStartTime))));
            ev = saeeg.evFileQueueUpdated("STARTNEXT",d);
            notify(obj,'UpdateAvailable',ev);
        end
        
        function mark_completed(obj,index)
            obj.ProcessEndTime(index) = now;
            
            
            d.Queue = obj.Queue;
            d.FileCompleted = obj.Queue(index);
            d.FileIndex    = index;
            d.NCompleted = obj.NCompleted;
            d.NRemaining = obj.NRemaining;
            d.EstTotalRemaingSeconds = obj.EstTotalRemaingSeconds;
            d.TotalDurationSeconds = seconds(etime(datevec(max(obj.ProcessStartTime)),datevec(min(obj.ProcessStartTime))));
            ev = saeeg.evFileQueueUpdated("FILEPROCESSED",d);
            notify(obj,'UpdateAvailable',ev);
            
            if all(obj.Completed)
                d.Queue = obj.Queue;
                d.NCompleted = obj.NCompleted;
                d.TotalDurationSeconds = seconds(etime(datevec(max(obj.ProcessStartTime)),datevec(min(obj.ProcessStartTime))));
                ev = saeeg.evFileQueueUpdated("FINISHED",d);
                notify(obj,'UpdateAvailable',ev);
            end
        end
        
        function q = add_to_queue(obj,filenames)
            filenames = string(filenames);
            filenames = filenames(:);
            
            assert(all(isfile(filenames)),'saeeg:FileQueue:add_to_queue:InvalidFile', ...
                'One or more files do not exist')
                
            
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
            
            if ismember(find(ind),idx), return; end
            
            switch obj.ProcessOrder
                case "serial"
                    idx = find(ind,1);
                    
                case "random"
                    idx = find(ind);
                    idx = idx(randi(length(idx),1));
            end
            
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
        
        function p = get.PercCompleted(obj)
            p = obj.NCompleted ./ obj.N .* 100;
        end
        
    end
    
    methods (Access = protected)
        
    end
    
    methods (Access = private)
        
        
    end
end