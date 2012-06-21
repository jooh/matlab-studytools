% Log any keyboard responses matching respkey for waitdur s
% [resptime,respcode] = logrespkeyboard(waitdur,respkey,esckey,ScanObj);
function [resptime,respcode] = logrespkeyboard(waitdur,respkey,esckey,ScanObj);

resptime = NaN;
respcode = NaN;

t_in = GetSecs;
while GetSecs < t_in + waitdur
    [keyisdown, secs, keyCode] = KbCheck;
    if keyisdown
        k = find(keyCode);
        k = k(1);
        hit = find(k==respkey);
        if ~isempty(hit)
            resp = GetSecs;
            % Only log if first response
            if isnan(resptime)
                resptime = resp;
                respcode = k;
                return
            end
        elseif k == esckey
            Screen('CloseAll')
            error('ESC KEY DETECTED - experiment aborted')
            return
        end
    end
end
