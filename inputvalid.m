% Get input that is restricted to certain classes or specific values
% o = inputvalid(question,[validoptions],[validclass])
function o = inputvalid(question,validoptions,validclass)

% TODO repair findStrInArray
if ieNotDefined('validclass')
    validclass = '';
end

if ieNotDefined('validoptions')
    validoptions = '';
end

optcell = ~isempty(validoptions) && iscell(validoptions);
optstr = ~isempty(validoptions) && isstr(validoptions);
optnum = ~isempty(validoptions) && isnumeric(validoptions);

done = 0;
while ~done
    o = input(question,'s');
    onum = str2num(o);
    if ~isempty(onum)
        o = onum;
        % Not good enough if we want a str
        if strcmp(validclass,'str')
            fprintf('invalid response. Try again.\n')
            continue
        end
        % Check against numbers
        if optnum && ~any(o == validoptions)
            fprintf('invalid response. Try again.\n')
            continue
        end
        % Check against cell array of numbers
        if optcell && ~any(findStrInArray(validoptions,o,1))
            fprintf('invalid response. Try again.\n')
            continue
        end
        done = 1;
    else
        % not good enough if we want a num
        if strcmp(validclass,'num') || optnum
            fprintf('invalid response. Try again.\n')
            continue
        end
        % Check against str
        if optstr && ~any(strfind(validoptions,o))
            fprintf('invalid response. Try again.\n')
            continue
        end
        % Check against cell array of strings
        if optcell && ~any(findStrInArray(validoptions,o,1))
            fprintf('invalid response. Try again.\n')
            continue
        end
        done = 1;
    end
end
