function gui_toggle_component(hObj,event)


axCurrent = ancestor(hObj,'axes');
if isempty(axCurrent), return; end

% tstr = axCurrent.Title.String;
% tstr(1:find(tstr==' ')) = [];
% id = str2double(tstr);

f = ancestor(axCurrent,'figure');

axAll = findobj(f,'type','axes');

id = find(axCurrent == axAll);

ind = f.UserData.compToBeRejected;

% false == "accept"; true == "reject"
ind(id) = ~ind(id);

f.UserData.compToBeRejected = ind;

for i = 1:length(axAll)
    if ind(i)
        axAll(i).Title.Color = 'r';
    else
        axAll(i).Title.Color = 'k';
    end
end

sgtitle(sprintf('%d components marked',sum(ind)))


