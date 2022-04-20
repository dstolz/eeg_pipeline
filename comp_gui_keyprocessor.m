function comp_gui_keyprocessor(hObj,event)

global CLEAN_SELECTMODE

persistent ZOOM_MODE

M = event.Modifier;

hManager = uigetmodemanager(hObj);



switch event.Character
    case {'/','?'}
        if isequal(event.EventName,'WindowKeyPress')
            
            fprintf('\n%s\n',repmat('v',1,50))
            fprintf('Key mappings:\n')
            fprintf('\t>mouse click: select/deselect component for rejection\n')
            fprintf('\t>shift + click: select/deselect range of components for rejection\n')
            fprintf('\t>control + shift +click: defer updating until released\n')
            fprintf('\n\n')
            fprintf('\t>control + h: enable/disable horizontal zoom. time plots only\n')
            fprintf('\n%s\n',repmat('^',1,50))
            return
        end
end


if isequal(event.EventName,'WindowKeyRelease') ...
        && CLEAN_SELECTMODE == "defer" ...
        && ~isequal(M,{'shift'})
        CLEAN_SELECTMODE = "process";
        gui_toggle_component(ancestor(hObj,'figure'));
end

if isequal(M,{'shift'})
    if isequal(event.EventName,'WindowKeyPress')
        CLEAN_SELECTMODE = "range";
    else
        CLEAN_SELECTMODE = "none";
    end
    
elseif isequal(sort(M),{'control' 'shift'})
    if isequal(event.EventName,'WindowKeyPress')
        CLEAN_SELECTMODE = "defer";
    end
    
elseif isequal(M,{'control'})
    if isequal(event.EventName,'WindowKeyPress')
        CLEAN_SELECTMODE = "none";
        switch upper(event.Key)
            case 'H' % HORIZONTAL ZOOM
                if isempty(ZOOM_MODE) || ~isvalid(ZOOM_MODE) || isequal(ZOOM_MODE.Enable,'off')
                    ZOOM_MODE = zoom(hObj);
                    ZOOM_MODE.Motion = 'horizontal';
                    ZOOM_MODE.Enable = 'on';
                    [hManager.WindowListenerHandles.Enabled] = deal(false);
                    hObj.WindowKeyPressFcn = @comp_gui_keyprocessor;
                    hObj.KeyPressFcn = @comp_gui_keyprocessor;
                    hObj.WindowKeyReleaseFcn = @comp_gui_keyprocessor;
                    hObj.KeyReleaseFcn = @comp_gui_keyprocessor;
                else
                    ZOOM_MODE.Enable = 'off';
                end
                
            
        end
    end
    
    
end

