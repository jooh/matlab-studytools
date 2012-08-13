classdef NBack < Study
    % Study subclass for running N-back tasks
    properties
        n = 1; % how many back to track
        respkey = []; % response button (buttonbox/keypress)
        targetfield = 'tex';
        targetname = 'image';
        time_hit = [];
        time_fa = [];
        time_onset = [];
    end

    methods
        function s = NBack(varargin)
            s = varargs2structfields(varargin,s);
        end

        function callback(self)
            % this won't work but it's roughly the logic we want
            targets = findStrInArray([self.eventvec.eventname],targetname);
            if length(targets) < 
            
        end
    end
end
