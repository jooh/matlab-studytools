classdef StudyEvent < hgsetget & dynamicprops
    % Abstract class for Study events - must be inherited to use
    properties
        duration = 0; % how long to get called for
        %name = 'master'; % this field is useful for e.g. response logging
        ncalls = 0;
        time = [];
        response = [];
        responsetime = [];
        skiponresponse = 0;
    end

    properties (Abstract)
        name
    end

    methods
        function s = StudyEvent(varargin)
            if nargin==0
                % initialisation of inherited objects etc
                return
            end
            sout = varargs2structfields(varargin,s);
            for fn = fieldnames(sout)'
                s.(fn{1}) = sout.(fn{1});
            end
        end
    end

    methods (Abstract)
        call(self)
    end
end
