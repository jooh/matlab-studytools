classdef ButtonboxCheck < ResponseCheck
    % ButtonboxCheck < StudyEvent subclass for logging button responses
    properties
        scanobj = [];
        keyboardhand = KeyboardCheck;
    end

    methods
        function s = ButtonboxCheck(varargin)
            s = varargs2structfields(varargin,s);
        end

        function [respkey,resptime] = checkkeys(self);
            respk = bitand(30,invoke(self.scanobj,'GetResponse'));
            rawtime = GetSecs;
            keyisdown = respk ~= 30;
            resptime = [];
            respkey = [];
            if keyisdown
                % ignore held keys
                if self.keyisdown && respk==self.lastkey
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
            % check for escape key on keyboard
            self.keyboardhand.call;
        end
    end
end
