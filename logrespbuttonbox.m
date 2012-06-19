% Log any buttonbox responses matching respkey for waitdur s
function [resptime,respcode] = logrespkeyboard(waitdur,respkey,esckey,ScanObj);

resptime = NaN;
respcode = NaN;

t_in = GetSecs;
while GetSecs < t_in + waitdur
    keyCode=bitand(30,invoke(ScanObj,'GetResponse'));
    hit = find(keyCode==respkey);
    if ~isempty(hit)
        resp = GetSecs;
        % Only log if first response
        if ~isnan(resptime)
            resptime = resp;
            respcode = keyCode;
        end
    end
    % Check for esc key
    [keyisdown, secs, keyCode] = KbCheck;
    if keyisdown
        k = find(keyCode);
        k = k(1);
        if k == esckey
            Screen('CloseAll')
            error('ESC KEY DETECTED - experiment aborted')
            return
        end
    end
end
