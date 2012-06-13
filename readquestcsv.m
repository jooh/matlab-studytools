% Read in a questionnaire CSV with the following columns: 
% [item# question lowoption highoption construct#]
% items = readquestcsv(csvpath)
function items = readquestcsv(csvpath)

fid = fopen(csvpath);
rows = textscan(fid,'%s','delimiter','\n','whitespace','');
rows = rows{1};
nitems = length(rows);

% Preallocate struct arr
items = struct('question',cell([1 nitems]),'scoring',[],'label_low',[],...
    'label_high',[]);

for n = 1:nitems
    tline = textscan(rows{n},'%s %s %s %d','delimiter',',');
    items(n).question =  tline{1}{:};
    items(n).label_low = tline{2}{:};
    items(n).label_high = tline{3}{:};
    items(n).scoring = tline{4};
end
