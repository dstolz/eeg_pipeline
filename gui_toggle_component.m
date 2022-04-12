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

idx = find(ind);
cfg = [];
cfg.component = idx;
data = ft_rejectcomponent(cfg,f.UserData.comp);


sgtitle(sprintf('%d components marked',sum(ind)))

if ~isfield(f.UserData,'timePlotFigure') ...
        || isempty(f.UserData.timePlotFigure) ...
        || ~isvalid(f.UserData.timePlotFigure)
    f.UserData.timePlotFigure = figure('color','w');
    movegui(f.UserData.timePlotFigure,'onscreen');
    f.UserData.timePlotAxes = axes(f.UserData.timePlotFigure);
end

plot_data(data,f.UserData.timePlotFigure);
    
function plot_data(data,ax)
if nargin < 2 || isempty(ax), ax = gca; end

y = data.trial{1}./max(abs(data.trial{1}),[],2);
y = (1:size(data.trial{1},1))' + y;

plot(ax,data.time{1},y','color','k');

axis(ax,'tight');

