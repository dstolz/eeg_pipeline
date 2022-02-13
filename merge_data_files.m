function mergeFiles = merge_data_files(pth,ext,orderTokenIdx,orderRegSymbol,delimiter)
% mergeFiles = merge_data_files(pth,[ext],[orderTokenIdx],[orderRegSymbol],[delimiter])
% 
% Returns cell array of files to be merged based on tokens in the
% filenames.
% 

% DJS 2/2022

narginchk(1,5);

if nargin < 2 || isempty(ext), ext = 'mat'; end
if nargin < 3, orderTokenIdx = []; end
if nargin < 4 || isempty(orderRegSymbol), orderRegSymbol = "\w*"; end
if nargin < 5 || isempty(delimiter), delimiter = "_"; end

d = dir(fullfile(pth,['*.' ext]));

ffn = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);

fn = {d.name}';
fn = cellfun(@(a) a(1:end-4),fn,'uni',0);
s = string(split(fn,delimiter));

t = cell(1,size(s,2));
for i = 1:size(s,2)
    t{i} = unique(s(:,i));
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
    mergeFiles{i} = ffn(ind);
end
mergeFiles(cellfun(@isempty,mergeFiles)) = [];
mergeFiles = cellfun(@sort,mergeFiles,'uni',0);