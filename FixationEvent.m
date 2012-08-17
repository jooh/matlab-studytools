classdef FixationEvent < StudyEvent
    % StudyEvent subclass for presenting a fixation dot
    properties
        x = [];
        y = [];
        radius = [];
        colour = [];
        rect = []; % Psychtoolbox rect
        window = []; % window handle
        name = 'fixation';
    end

    methods
        function s = FixationEvent(st,varargin)
        % Initialise event by populating fields, possibly making texture
            s = varargs2structfields(varargin,s);
            if isempty(s.radius)
                % default size 1/8 of a degree
                radius = st.deg2px * 1/8;
            end
            if isempty(s.x)
                s.x = st.xcenter;
            end
            if isempty(s.y)
                s.y = st.ycenter;
            end
            if isempty(s.colour)
                % default font colour should be someting that contrasts
                % with background
                s.colour = st.textpar.colour;
            end
            if isempty(s.rect)
                s.rect = CenterRectOnPoint([0 0 radius radius],s.x,s.y);
            end
            s.window = st.window;
        end

        function call(self)
            self.ncalls = self.ncalls+1;
            Screen('FillOval',self.window,self.colour,self.rect);
        end
    end
end
