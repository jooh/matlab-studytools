classdef ResponseCheck < StudyEvent
    % StudyEvent subclass for logging responses
    properties
        validkeys = []; % vector of possible responses
        eventname = 'responsecheck';
    end

    methods
        function s = ResponseCheck(varargin)
            if nargin==0
                return
            end
            s = varargs2structfields(varargin,s);
        end

        function call(self)
            self.ncalls = self.ncalls + 1;
            [respk,resptime] = self.checkkeys;
            [validresp,x,inds] = intersect(self.validkeys,respk);
            self.response = validresp;
            self.time = resptime(inds);
        end
    end

    methods (Abstract)
        [respk,resptime] = checkkeys(self);
    end
end
