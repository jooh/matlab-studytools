classdef ButtonboxCheck < ResponseCheck
    % ButtonboxCheck < StudyEvent subclass for logging button responses
    properties
        scanobj = [];
    end

    methods
        function s = ButtonboxCheck(st,varargin)
            s = varargs2structfields(varargin,s);
            s.validkeys = st.validkeys;
            s.scanobj = st.scanobj;
        end

        function [respkey,resptime] = checkkeys(self);
            respk = bitand(30,invoke(self.scanobj,'GetResponse'));
            rawtime = GetSecs;
            keyisdown = any(respk)
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
        end
    end
end
