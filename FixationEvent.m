classdef FixationEvent < StudyEvent
    % StudyEvent subclass for presenting a fixation dot
    properties
        x = [];
        y = [];
        radius = [];
        color = [];
        rect = []; % Psychtoolbox rect
        window = []; % window handle
        name = 'fixation';
    end

    methods
        function s = FixationEvent(st,varargin)
        % Initialise event by populating fields, possibly making texture
            sout = varargs2structfields(varargin,s);
            for fn = fieldnames(sout)'
                s.(fn{1}) = sout.(fn{1});
            end
            if isempty(s.radius)
                radius = st.deg2px * 1/10;
            end
            if isempty(s.x)
                s.x = st.xcenter;
            end
            if isempty(s.y)
                s.y = st.ycenter;
            end
            if isempty(s.color)
                % default font color should be someting that contrasts
                % with background
                s.color = st.textpar.color;
            end
            if isempty(s.rect)
                s.rect = round(CenterRectOnPoint([0 0 radius radius],...
                    s.x,s.y));
            end
            s.window = st.window;
        end

        function call(self)
            self.ncalls = self.ncalls+1;
            Screen('FillOval',self.window,self.color,self.rect);
        end
    end
end
