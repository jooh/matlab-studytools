classdef ResponseCheck < StudyEvent
    % StudyEvent subclass for logging responses
    properties
        validkeys = []; % vector of possible responses
        name = 'responsecheck';
        keyisdown = 0;
        lastkey = NaN;
    end

    methods
        function s = ResponseCheck(varargin)
            if nargin==0
                return
            end
            sout = varargs2structfields(varargin,s);
            for fn = fieldnames(sout)'
                s.(fn{1}) = sout.(fn{1});
            end
        end

        function call(self)
            self.ncalls = self.ncalls + 1;
            [respk,resptime] = self.checkkeys;
            [validresp,x,inds] = intersect(self.validkeys,respk);
            self.response = validresp;
            self.responsetime = resptime(inds);
        end
    end

    methods (Abstract)
        [respk,resptime] = checkkeys(self);
    end
end
