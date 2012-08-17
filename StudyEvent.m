classdef StudyEvent < hgsetget & dynamicprops
    % Abstract class for Study events - must be inherited to use
    properties
        duration = 0; % how long to get called for
        units = 's'; % timing in s or scans (not yet supported)
        %eventname = 'master'; % this field is useful for e.g. response logging
        ncalls = 0;
        time = [];
        response = [];
        skiponresponse = 0;
    end

    properties (Abstract)
        eventname
    end

    methods
        function s = StudyEvent(varargin)
            if nargin==0
                % initialisation of inherited objects etc
                return
            end
            s = varargs2structfields(varargin,s);
        end
    end

    methods (Abstract)
        call(self)
    end
end
