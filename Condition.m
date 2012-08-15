classdef Condition
    % Organise a cell array of StudyEvents and a postcall method (default
    % null) that defines behaviour to apply to SEs after executing
    % condition.  Inherited classes provide custom postcalls for e.g.
    % scoring responses in different ways
    properties
        studyevents = {};
        eventname = 'condition';
    end

    methods
        function t = Condition(studyevents,varargin);
            t.studyevents = studyevents;
            t = varargs2structfields(varargin,t);
        end

        function postcall(self)
            % summarise trial events
            % placeholder - but no raise. Maybe you really have no
            % behaviour here.
        end
    end
end
