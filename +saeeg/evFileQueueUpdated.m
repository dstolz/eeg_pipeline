classdef (ConstructOnLoad) evFileQueueUpdated < event.EventData
   properties
      NewState
      Data
   end
   
   methods
      function data = evFileQueueUpdated(NewState,Data)
         data.NewState = NewState;
         data.Data = Data;
      end
   end
end