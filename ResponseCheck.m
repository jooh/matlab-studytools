classdef ResponseCheck < StudyEvent
    % StudyEvent subclass for logging responses
    properties
        validkeys = []; % vector of possible responses
        eventname = 'responsecheck';
        waitresp = 0; % skip ahead in event loop if key press
        responsekeys = []; % store valid presses here
        responsetimes = []; % store valid times
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
            [validresp,inds] = union(self.validkeys,respk);
            if any(validresp)
                self.responsekeys = [self.responsekeys validresp];
                self.responsetimes = [self.responsetimes resptime(inds)];
            end
        end

        function [respk,resptime] = checkkeys(self);
            % placeholder
            error('Use inherited classes.')
            return
        end

    end
end
