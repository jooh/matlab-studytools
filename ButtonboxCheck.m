classdef ButtonboxCheck < ResponseCheck
    % ButtonboxCheck < StudyEvent subclass for logging button responses
    properties
        scanobj
        keyboardhand = KeyboardCheck;
    end

    methods
        function s = ButtonboxCheck(varargin)
            sout = varargs2structfields(varargin,s);
            for fn = fieldnames(sout)'
                s.(fn{1}) = sout.(fn{1});
            end
        end

        function [respkey,resptime] = checkkeys(self);
            % single call check for buttons
            resptime = self.scanobj(2:5,0);
            valid = ~isnan(resptime);
            respkey = find(valid);
            resptime = resptime(valid);
            if any(valid)
                % ignore held keys
                if self.keyisdown && respk==self.lastkey
                    respkey = [];
                    resptime = [];
                    return
                end
                % update internal state
                self.keyisdown = true;
                self.lastkey = respkey;
            else
                % reset to record repeated distinct presses of the same key
                self.keyisdown = false;
                self.lastkey = NaN;
            end
            % check for escape key on keyboard
            self.keyboardhand.call;
        end
    end
end
