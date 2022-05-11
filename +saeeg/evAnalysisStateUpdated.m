classdef (ConstructOnLoad) evAnalysisStateUpdated < event.EventData
   properties
      NewState
   end
   
   methods
      function data = evAnalysisStateUpdated(NewState)
         data.NewState = NewState;
      end
   end
end