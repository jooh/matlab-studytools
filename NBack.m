classdef NBack < Study
    % Study subclass for running N-back tasks
    properties
        n = 1; % how many back to track
        targetfield = 'tex';
        targetname = 'image';
        responsename = '';
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

        function scoretrial(self,t)
            % Populate 'score' field in self.trials(t) with result of
            % current trial
        end
    end
end
