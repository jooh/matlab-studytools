classdef FlipEvent > StudyEvent
    % subclass for StudyEvent.
    properties
        actualtime = NaN;
        when = 0;
        window = [];
        dontclear = 0;
    end

    methods
        function s = FlipEvent(st,varargin)
            s = varargs2structfields(varargin,s);
            s.window = st.window;
        end

        function call(self)
            self.actualtime = Screen('Flip',self.window,self.when,...
                self.dontclear);
        end
    end
end
