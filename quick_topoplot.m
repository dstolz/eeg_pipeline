function quick_topoplot(layout,z,chLabels,showMarkers)

if ischar(layout)
    cfg.layout = layout;
    layout = ft_prepare_layout(cfg);
end

x = zeros(size(z)); y = x;
for i = 1:length(chLabels)
    ind = ismember(layout.label,chLabels{i});
    
    x(i) = layout.pos(ind,1);
    y(i) = layout.pos(ind,2);
    
end

[xi,yi] = meshgrid(linspace(min(x),max(x),100),linspace(min(y),max(y),100));
zi = griddata(x,y,z,xi,yi);
surf(xi,yi,zi);
shading interp
view(2)

hold on

if showMarkers
    plot3(x,y,ones(size(x))*max(zi(:)),'.k');
    ind = ~ismember(layout.label,chLabels);
    xn = layout.pos(ind,1);
    yn = layout.pos(ind,2);
    plot3(xn,yn,ones(size(xn))*max(zi(:)),'xk');
end
for i = 1:length(layout.outline)
    plot(layout.outline{i}(:,1),layout.outline{i}(:,2),'-k')
end

hold off

axis equal
axis off
