function mergeFiles = merge_data_files(pth,orderTokenIdx,orderRegSymbol,delimiter)
% mergeFiles = merge_data_files(pth,[orderTokenIdx],[orderRegSymbol],[delimiter])
% 
% Returns cell array of files to be merged based on tokens in the
% filenames.
% 

% DJS 2/2022

narginchk(1,4);

ext = 'mat';
if nargin < 2, orderTokenIdx = []; end
if nargin < 3 || isempty(orderRegSymbol), orderRegSymbol = "\w*"; end
if nargin < 4 || isempty(delimiter), delimiter = "_"; end

d = dir(fullfile(pth,['*.' ext]));

ffn = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);

fn = {d.name}';
fn = cellfun(@(a) a(1:end-4),fn,'uni',0);
s = cellfun(@(a) string(split(a,delimiter))',fn,'uni',0); % may have unequal number of elements

ne = cellfun(@numel,s);
m = mode(ne);
ind = ne ~= m;
n = sum(ind);
if n > 0
    saeeg.vprintf(1,1,'Found %d files that do not conform to the most common format. Skipping:',n)
    cellfun(@(a,b) saeeg.vprintf(1,1,'\t\t%d. "%s"',a,b),num2cell(find(ind)),fn(ind))
    s(ind) = [];
end

for i = 1:length(s)
    x(i,:) = s{i};
end

t = cell(1,size(x,2));
for i = 1:size(x,2)
    t{i} = unique(x(:,i));
end

t{orderTokenIdx} = orderRegSymbol;
n = cellfun(@numel,t);
m = "";
for i = 1:length(t)
    if  n(i) > 1
        m = repmat(m,n(i),1);
        x = repmat(t{i}',size(m,1)/n(i),1);
        m(:,i) = x(:);
    else
        m(:,i) = t{i};
    end
end

mergeFiles = cell(size(m,1),1);
for i = 1:size(m,1)
    str = join(m(i,:),delimiter);
    r = regexp(fn,str);
    ind = ~cellfun(@isempty,r);
    mffn = ffn(ind);
    c = cellfun(@(a) textscan(a,'%s','delimiter','_'),mffn,'uni',0);
    id = cellfun(@(a) str2double(a{1}{orderTokenIdx}),c);
    [~,idx] = sort(id);
    mergeFiles{i} = mffn(idx);
end
mergeFiles(cellfun(@isempty,mergeFiles)) = [];
% mergeFiles = cellfun(@sort,mergeFiles,'uni',0);







