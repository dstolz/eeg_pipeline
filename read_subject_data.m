function S = read_subject_data(ffn,sheet,range)
% S = read_subject_data(ffn,sheet,range)

[~,~,raw] = xlsread(ffn,sheet,range);

clear S
for j = 2:size(raw,1)
    for i = 1:size(raw,2)
        v = raw{j,i};
        if ischar(v), v = string(v); end
        S(j-1,1).(raw{1,i}) = v;
    end
end
