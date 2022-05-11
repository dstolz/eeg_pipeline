classdef (ConstructOnLoad) evSelectionEventData < event.EventData
   properties
      NewSelection
      Filenames
   end
   
   methods
      function data = evSelectionEventData(NewSelection)
         data.NewSelection = NewSelection;
         data.Filenames = {NewSelection.NodeData};
      end
   end
end