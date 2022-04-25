function comp_gui_keyprocessor(hObj,event)

global CLEAN_SELECTMODE CLIM_MODE

persistent ZOOM_MODE 

M = event.Modifier;

hManager = uigetmodemanager(hObj);



switch event.Character
    case {'/','?'}
        if isequal(event.EventName,'WindowKeyPress')
            msg = '';
%             msg = [msg sprintf('\n%s\n',repmat('v',1,50))];
            msg = [msg sprintf('Key mappings:\n')];
            msg = [msg sprintf(' - mouse click: select/deselect component for rejection\n')];
            msg = [msg sprintf(' - shift + click: select/deselect range of components for rejection\n')];
            msg = [msg sprintf(' - control + shift +click: defer updating until released\n')];
            msg = [msg sprintf(' - control + r: deselect all components\n')];
            msg = [msg newline];
            msg = [msg sprintf('Time plots:\n')];
            msg = [msg sprintf(' - control + h: enable/disable horizontal zoom.\n')];
            msg = [msg sprintf('\nTopographic plots:\n')];
            msg = [msg sprintf(' - control + m: cycle color scale mode\n')];
%             msg = [msg sprintf('\n%s\n',repmat('^',1,50))];
            h = msgbox(msg,'Key mapping','modal');
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
                
            case 'M'
                f = findobj('type','figure','-and','tag','TOPO');
                ax = findobj(f,'type','axes');
                if isempty(CLIM_MODE) || CLIM_MODE == "excluded"
                    CLIM_MODE = "individually";
                    set(ax,'climmode','auto');
                    fprintf('Color scale components individually\n')
                    
                elseif CLIM_MODE == "alltogether"
                    CLIM_MODE = "individually";
                    c = cell2mat(get(ax,'clim'));
                    set(ax,'clim',[min(c(:,1)) max(c(:,2))]);
                    fprintf('Color scale components all together\n')
                    
                elseif CLIM_MODE == "individually"
                    CLIM_MODE = "bydistribution";
                    set(ax,'climmode','auto')
                    c = cell2mat(get(ax,'clim'));
                    pd = fitdist(c(:),'logistic');
                    nc = pd.icdf([.25 0.75]);
                    set(ax,'clim',nc);
                    fprintf('Color scale components by distribution\n')
                    
                elseif CLIM_MODE == "bydistribution"
                    CLIM_MODE = "excluded";
                    ind = f.UserData.compToBeRejected;
                    set(ax,'climmode','auto')
                    c = cell2mat(get(ax(~ind),'clim'));
                    pd = fitdist(c(:),'logistic');
                    nc = pd.icdf([.1 0.9]);
                    set(ax,'clim',nc)
                    fprintf('Color scale with only unmarked components\n')
                end
                
            case 'R' % mark all components as ok
                fTopo = findobj('type','figure','-and','tag','TOPO');
                fTopo.UserData.compToBeRejected = false(size(fTopo.UserData.compToBeRejected));
                gui_toggle_component(fTopo);
        end
    end
    
    
end

