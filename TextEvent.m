classdef TextEvent < StudyEvent
    % TextEvent subclass for presenting text on the screen
    properties
        textstr = '';
        x = [];
        y = [];
        color = [];
        window = []; % window handle
        name = 'text';
        txtwrap = [];
        vspacing = [];
    end

    methods
        function s = TextEvent(textstr,st,varargin)
            if nargin==0
                return
            end
            s.textstr = textstr;
            s = varargs2structfields(varargin,s,0);
            % in principle we should use st.x and st.y here but
            % unfortunately DrawFormattedText is pretty dumb with placement
            % (x and y are for top left corner, not centre of text box) so
            % using the 'center' keyword is probably preferable in most
            % cases
            s.initialisetext(st);
        end

        function initialisetext(self,st)
            self.window = st.window;
            if isempty(self.x)
                self.x = 'center';
            end
            if isempty(self.y)
                self.y = 'center';
            end
            if isempty(self.color)
                % default font color should be someting that contrasts
                % with background
                self.color = st.textpar.color;
            end
            if isempty(self.txtwrap)
                self.txtwrap = st.textpar.txtwrap;
            end
            if isempty(self.vspacing)
                self.vspacing = st.textpar.vspacing;
            end
        end

        function call(self)
            self.ncalls = self.ncalls+1;
            DrawFormattedText(self.window,self.textstr,self.x,...
                self.y,self.color,self.txtwrap,0,0,self.vspacing);
        end
    end
end
