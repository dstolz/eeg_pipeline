function gui_clean_components(hObj,event,showall)

if nargin < 3 || isempty(showall), showall = false; end

if nargin >= 2 && ischar(hObj) && ischar(event) % path names
    figPath = hObj;
    cleanPath = event;
    listfiles(figPath,cleanPath,showall)
    return
end
    

if isempty(hObj.UserData), delete(hObj); return; end

ind = hObj.UserData.compToBeRejected;

r = questdlg(sprintf('%d components are marked to be rejected\n\nWhat do you want to do?',sum(ind)),'CLEANING', ...
    'Save','Discard','Cancel','Save');

figPath   = fileparts(hObj.UserData.ffnTopoFig);
cleanPath = fileparts(hObj.UserData.ffnOut);

ft = findobj('type','figure','-and','Name','cleaning');

switch r
    case 'Cancel'
        return
        
    case 'Discard'
        delete(hObj);
        delete(ft);
        fprintf(2,'Changes were discarded\n')
        
    case 'Save'
        hObj.Pointer = 'watch'; drawnow
        hObj.UserData.TimeStamp = now;
        fprintf('Saving ...')
        sgtitle(hObj,'Saving ...','Color','g'); drawnow
        
        rcfg = [];
        rcfg.outputfile = hObj.UserData.ffnOut;
        rcfg.component = find(hObj.UserData.compToBeRejected);
        ft_rejectcomponent(rcfg,hObj.UserData.comp);
        
        savefig(hObj,hObj.FileName);
        
        fprintf(' done\n')
        
        delete(ft);
        delete(hObj);
        
end

listfiles(figPath,cleanPath,showall)


function listfiles(figPath,cleanPath,showall)
dclean = dir(fullfile(cleanPath,'*.mat'));
nclean = cellfun(@(a) a(1:end-10),{dclean.name},'uni',0);

dfig = dir(fullfile(figPath,'*.fig'));
nfig = cellfun(@(a) a(1:end-12),{dfig.name},'uni',0);

if ~showall
    nfig = setdiff(nfig,nclean);
    if isempty(nfig)
        fsprintf(2,'No more files to be processed were found!\n\nTOPO path: %s\n\nCLEAN path: %s', ...
            figPath,cleanPath)
        return
    end
end

[s,ok] = listdlg('ListString',nfig, ...
    'SelectionMode','single', ...
    'PromptString',sprintf('%d datasets shown:',length(nfig)), ...
    'ListSize',[400 500]);

if ~ok, return; end

ffn = fullfile(figPath,dfig(s).name);

openfig(ffn);


