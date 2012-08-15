classdef NBack < Study
    % Study subclass for running N-back tasks
    properties
        n = 1; % how many back to track
        targetfield = 'tex';
        targetname = 'image';
        responsename = '';
        time_hit = [];
        time_fa = [];
        time_onset = [];
        keyind = 1;
    end

    methods
        function s = NBack(varargin)
            s = varargs2structfields(varargin,s);
            % use the right default response eventname
            if isempty(s.responsename)
                if strcmp(s.location,'mri')
                    responsename = 'buttonboxcheck';
                else
                    responsename = 'keyboardcheck';
                end
            end
        end

        function postcall(self)
            % TODO
            keyboard;
            % this won't work but it's roughly the logic we want
            %targets = findStrInArray([self.eventvec.eventname],targetname);
        end
    end
end
