function gui_toggle_component(hObj,event)

global CLEAN_SELECTMODE

persistent PREVIOUS_ID

flags.process = true;


axCurrent = ancestor(hObj,'axes');
if isa(hObj,'matlab.graphics.primitive.Line')
    ID = hObj.UserData;
    ft = ancestor(hObj,'figure');
    fTopo = ft.UserData.fTopo;
    ax = findobj(fTopo,'type','axes');
    axIDs = arrayfun(@(a) str2double(a.Title.String(find(a.Title.String==' ')+1:end)),ax);
    axCurrent = ax(axIDs == ID);
    
elseif isa(hObj,'matlab.graphics.axis.Axes') || ~isempty(axCurrent) && startsWith(axCurrent.Title.String,'component')
    tstr = axCurrent.Title.String;
    tstr(1:find(tstr==' ')) = [];
    ID = str2double(tstr);
    fTopo = ancestor(hObj,'figure');
    ax = findobj(fTopo,'type','axes');
    axIDs = arrayfun(@(a) str2double(a.Title.String(find(a.Title.String==' ')+1:end)),ax);
    

elseif isa(hObj,'matlab.ui.Figure') && isvalid(hObj) && isequal(hObj.Tag,'CLEANING')
    ID = [];
    fTopo = findobj('type','figure','-and','tag','TOPO');
elseif isa(hObj,'matlab.ui.Figure') && isvalid(hObj) %&& isequal(hObj.Tag,'TOPO')
    ID = [];
    fTopo = hObj;
else
    return
end

ft = findobj('type','figure','-and','Name','cleaning');
if isempty(ft)
    ft = create_fig(fTopo);
end


sgtitle(ft,'updating ...')
sgtitle(fTopo,'updating...')
ft.Pointer = 'watch';
fTopo.Pointer = 'watch';
drawnow


indRej = fTopo.UserData.compToBeRejected;

if isempty(CLEAN_SELECTMODE), CLEAN_SELECTMODE = "none"; end

if startsWith(CLEAN_SELECTMODE,"range") && ~isempty(PREVIOUS_ID)
    if ID > PREVIOUS_ID
        ID = PREVIOUS_ID+1:ID;
    else
        ID = ID:PREVIOUS_ID-1;
    end
    
else
    PREVIOUS_ID = ID;
end

if ~isempty(ID)
    % false == "accept"; true == "reject"
    if endsWith(CLEAN_SELECTMODE,"uniform")
        indRej(ID) = ~indRej(PREVIOUS_ID);
        
    elseif CLEAN_SELECTMODE == "defer"
        indRej(ID) = ~indRej(ID);
        flags.process = false;
        
    elseif CLEAN_SELECTMODE == "process"
        indRej(ID) = ~indRej(ID);
        CLEAN_SELECTMODE = "none";
        flags.process = true;
        
    else
        indRej(ID) = ~indRej(ID);
    end
end


fTopo.UserData.compToBeRejected = indRej;


xindRej = flipud(indRej);
for i = 1:length(xindRej)
    if xindRej(i)
        ax(i).Title.Color = 'r';
    else
        ax(i).Title.Color = 'k';
    end
end






axComponents = fTopo.UserData.compPlotAxes;

h = fTopo.UserData.compLines;
for i = 1:length(h)
    if indRej(i)
        h(i).Color = [.8 .8 .8];
    else
        h(i).Color = fTopo.UserData.origCompColor(i,:);
    end
end

if isempty(axComponents.Children)
    xm = fTopo.UserData.comp.time{1}([1 end]);
else
    xm = xlim(axComponents);
end
xlim(axComponents,xm);



if flags.process
    cfg = [];
    cfg.component = find(indRej);
    data = ft_rejectcomponent(cfg,fTopo.UserData.comp);
    
    y = data.trial{1}./max(abs(data.trial{1}),[],2);
    y = (1:size(data.trial{1},1))' + y;
    
    h = fTopo.UserData.dataLines;
    for i = 1:length(h)
        h(i).YData = y(i,:);
        h(i).Color = fTopo.UserData.origDataColor{i};
    end
else
    set(fTopo.UserData.dataLines,'Color',[.8 .8 .8]);
end


nRej = sum(indRej);
if CLEAN_SELECTMODE == "defer"
    sgstr = sprintf('%d components waiting to be updated ...',nRej);
    sgclr = "#ffa500";
else
    sgstr = sprintf('%d components marked',nRej);
    sgclr = 'k';
end
sgtitle(fTopo,sgstr,'Color',sgclr);
sgtitle(ft,sgstr,'Color',sgclr);

ft.Pointer = 'arrow';
fTopo.Pointer = 'hand';

drawnow



function f = create_fig(fTopo,cfg)
if nargin < 2 || isempty(cfg), cfg.component = []; end

f = figure('name','cleaning','color','w');

ax = subplot(121,'parent',f);
ax.Tag = 'comp';
fTopo.UserData.compPlotAxes = ax;

ax = subplot(122,'parent',f);
ax.Tag = 'data';
fTopo.UserData.dataPlotAxes = ax;

movegui(f,'onscreen');





ax1 = fTopo.UserData.compPlotAxes;

y = fTopo.UserData.comp.trial{1}./max(abs(fTopo.UserData.comp.trial{1}),[],2);

cm = prism(size(y,1));
for i = 1:size(y,1)
    h(i) = line(ax1,fTopo.UserData.comp.time{1},i+y(i,:), ...
        'color',cm(i,:),'UserData',i);
end
set(h,'ButtonDownFcn',@gui_toggle_component);
f.UserData.fTopo = fTopo;

fTopo.UserData.compLines = h;
fTopo.UserData.origCompColor = cm;

axis(ax1,'tight');
grid(ax1,'on');
xlabel(ax1,'time (s)');
ylabel(ax1,'component #');
box(ax1,'on');

ax1.YTick = 5:5:length(h);
ylim(ax1,[0 max(ylim(ax1))]);





ax2 = fTopo.UserData.dataPlotAxes;

data = ft_rejectcomponent(cfg,fTopo.UserData.comp);

y = data.trial{1}./max(abs(data.trial{1}),[],2);

for i = 1:size(y,1)
    h(i) = line(ax2,data.time{1},i+y(i,:),'UserData',i);
end
fTopo.UserData.dataLines = h;
fTopo.UserData.origDataColor = get(h,'Color');


xm = fTopo.UserData.comp.time{1}([1 end]);
xlim(ax1,xm);

axis(ax2,'tight');
xlim(ax2,xm);
grid(ax2,'on');
xlabel(ax2,'time (s)');
ylabel(ax2,'channel');
box(ax2,'on');

ax2.YTick = 5:5:length(h);
ylim(ax2,[0 max(ylim(ax2))]);


linkaxes([ax1 ax2],'x');



f.WindowKeyPressFcn     = @comp_gui_keyprocessor;
f.WindowKeyReleaseFcn   = @comp_gui_keyprocessor;
fTopo.WindowKeyPressFcn = @comp_gui_keyprocessor; 
fTopo.WindowKeyReleaseFcn = @comp_gui_keyprocessor;

f.Tag = 'CLEANING';
fTopo.Tag = 'TOPO';


