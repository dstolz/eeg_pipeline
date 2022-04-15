function gui_toggle_component(hObj,event)

axCurrent = ancestor(hObj,'axes');
if isempty(axCurrent)
    fTopo = hObj;
    create_fig(fTopo);
    id = [];
else
    fTopo = axCurrent.Parent;
    tstr = axCurrent.Title.String;
    tstr(1:find(tstr==' ')) = [];
    id = str2double(tstr);    
end


ind = fTopo.UserData.compToBeRejected;



if ~isempty(id)
    % false == "accept"; true == "reject"
    ind(id) = ~ind(id);
end

fTopo.UserData.compToBeRejected = ind;


if ind(id)
    axCurrent.Title.Color = 'r';
else
    axCurrent.Title.Color = 'k';
end



sgtitle(fTopo,sprintf('%d components marked',sum(ind)))

ft = findobj('type','figure','-and','Name','cleaning');
if isempty(ft)
    create_fig(fTopo);
end


idx = find(ind);
cfg = [];
cfg.component = idx;

ax1 = fTopo.UserData.compPlotAxes;

arrayfun(@(a,b) set(a,'Color',b{1}),ax1.Children,ft.UserData.origCompColor);
set(ax1.Children(flipud(ind)),'color',[.8 .8 .8]);

if isempty(ax1.Children)
    xm = fTopo.UserData.comp.time{1}([1 end]);
else
    xm = xlim(ax1);
end
xlim(ax1,xm);

% update line data
data = ft_rejectcomponent(cfg,fTopo.UserData.comp);

y = data.trial{1}./max(abs(data.trial{1}),[],2);
y = (1:size(data.trial{1},1))' + y;

h = fTopo.UserData.dataLines;
for i = 1:length(h)
    h(i).YData = y(i,:);
end

fTopo.Pointer = 'hand';
drawnow



function f = create_fig(fTopo,cfg)
if nargin < 2 || isempty(cfg), cfg.component = []; end

f = figure('name','cleaning','color','w');

ax = subplot(121,'parent',f);
ax.Tag = 'comp';
ax.YDir = 'reverse';
fTopo.UserData.compPlotAxes = ax;

ax = subplot(122,'parent',f);
ax.Tag = 'data';
ax.YDir = 'reverse';
fTopo.UserData.dataPlotAxes = ax;

movegui(f,'onscreen');

% only need to plot ocmponents once since they don't change
ax1 = fTopo.UserData.compPlotAxes;

y = fTopo.UserData.comp.trial{1}./max(abs(fTopo.UserData.comp.trial{1}),[],2);
y = (1:size(fTopo.UserData.comp.trial{1},1))' + y;
plot(ax1,fTopo.UserData.comp.time{1},y');
f.UserData.origCompColor = get(ax1.Children,'Color');

axis(ax1,'tight');
grid(ax1,'on');
xlabel(ax1,'time (s)');
ylabel(ax1,'component #');



ax2 = fTopo.UserData.dataPlotAxes;

data = ft_rejectcomponent(cfg,fTopo.UserData.comp);

y = data.trial{1}./max(abs(data.trial{1}),[],2);
y = (1:size(data.trial{1},1))' + y;

for i = 1:size(y,1)
    h(i) = line(ax2,data.time{1},y(i,:));
end
fTopo.UserData.dataLines = h;


if isempty(ax1.Children)
    xm = fTopo.UserData.comp.time{1}([1 end]);
else
    xm = xlim(ax1);
end
xlim(ax1,xm);

axis(ax2,'tight');
xlim(ax2,xm);
grid(ax2,'on');
xlabel(ax2,'time (s)');
ylabel(ax2,'channel');

zoom(ax2.Parent,'xon');

linkaxes([ax1 ax2],'x');


