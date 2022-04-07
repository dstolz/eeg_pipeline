function gui_clean_components(hObj,event,varargin)

ind = hObj.UserData.compToBeRejected;

r = questdlg(sprintf('%d components are marked to be rejected\n\nWhat do you want to do?',sum(ind)),'CLEANING','Save','Discard','Cancel','Save');

switch r
    case 'Cancel'
        return
        
    case 'Discard'
        delete(hObj);
        fprintf(2,'Changes were discarded\n')
        return
        
    case 'Save'
        hObj.Pointer = 'watch'; drawnow
        hObj.UserData.TimeStamp = now;
        fprintf('Saving ...')
        savefig(hObj,hObj.FileName);
        fprintf(' done\n')
        hObj.Pointer = 'hand'; drawnow
        delete(hObj);

end



assignin('base',varName,ind)

