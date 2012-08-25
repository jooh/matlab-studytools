classdef TextEvent < StudyEvent
    % TextEvent subclass for presenting text on the screen
    properties
        textstr = '';
        x = [];
        y = [];
        color = [];
        rect = []; % Psychtoolbox rect
        window = []; % window handle
        name = 'fixation';
        txtwrap = [];
        vspacing = [];
    end

    methods
        function s = TextEvent(textstr,st,varargin)
            s.textstr = textstr;
            s = varargs2structfields(varargin,s);
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
            if isempty(s.txtwrap)
                s.txtwrap = st.textpar.txtwrap;
            end
            if isempty(s.vspacing)
                s.vspacing = st.textpar.vspacing;
            end
            s.window = st.window;
        end

        function call(self)
            self.ncalls = self.ncalls+1;
            Screen('DrawFormattedText',self.window,self.textstr,self.x,...
                self.y,self.color,self.txtwrap,0,0,self.vspacing);
        end
    end
end
