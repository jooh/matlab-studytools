classdef KeyboardCheck < ResponseCheck
    % ResponseCheck < StudyEvent subclass for logging keyboard responses
    properties
        esc = []; % code for escape key
        spacebar = [] % code for spacebar
    end

    methods
        function s = KeyboardCheck(st,varargin)
            s = varargs2structfields(varargin,s);
            KbName('UnifyKeyNames');
            s.esc = KbName('escape');
            s.spacebar = KbName('space');
            s.validkeys = KbName(st.validkeys);
        end

        function [respk,resptime] = checkkeys(self);
            [keyisdown, rawtime, keyCode] = KbCheck;
            resptime = [];
            respk = [];
            if keyisdown
                resptime = rawtime;
                respk = find(keyCode);
                respk = respk(1);
                if respk == self.esc
                    error('ESC KEY DETECTED - experiment aborted')
                    return
                end
            end
        end
    end
end
