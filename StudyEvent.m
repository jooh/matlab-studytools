classdef StudyEvent
    % Master class for Study events
    properties
        duration = 0; % how long to get called for
        units = 's'; % timing in s or scans (not yet supported)
        eventname = 'master'; % this field is useful for e.g. response logging
        skipahead = 0; % flag to break out of any waitloop
        ncalls = 0; % track call n
    end

    methods
        function s = StudyEvent(varargin)
            if nargin==0
                % initialisation of inherited objects etc
                return
            end
            s = varargs2structfields(varargin,s);
        end

        function call(self)
            % placeholder
            self.ncalls = self.ncalls+1;
            error('Use inherited classes.')
            return
        end
    end
end
