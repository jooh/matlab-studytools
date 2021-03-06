classdef KeyboardCheck < ResponseCheck
    % ResponseCheck < StudyEvent subclass for logging keyboard responses
    properties
        esc = []; % code for escape key
        spacebar = [] % code for spacebar
    end

    methods
        function s = KeyboardCheck(varargin)
            sout = varargs2structfields(varargin,s);
            for fn = fieldnames(sout)'
                s.(fn{1}) = sout.(fn{1});
            end
            s.esc = KbName('escape');
            s.spacebar = KbName('space');
        end

        function [respkey,resptime] = checkkeys(self);
            [keyisdown, rawtime, keyCode] = KbCheck;
            resptime = [];
            respkey = [];
            if keyisdown
                respk = find(keyCode);
                respk = respk(1);
                % ignore held keys
                if self.keyisdown && respk==self.lastkey
                    return
                elseif respk == self.esc
                    error('ESC KEY DETECTED - experiment aborted')
                    return
                end
                resptime = rawtime;
                respkey = respk;
                % update internal state
                self.keyisdown = keyisdown;
                self.lastkey = respkey;
            else
                % reset to record repeated distinct presses of the same key
                self.keyisdown = 0;
                self.lastkey = NaN;
            end
        end
    end
end
