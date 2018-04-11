classdef FlipEvent < StudyEvent
    % subclass for StudyEvent.
    properties
        when = 0;
        window = [];
        dontclear = 0;
        name = 'flip';
    end

    methods
        function s = FlipEvent(st,varargin)
            sout = varargs2structfields(varargin,s);
            for fn = fieldnames(sout)'
                s.(fn{1}) = sout.(fn{1});
            end
            s.window = st.window;
        end

        function call(self)
            self.ncalls = self.ncalls+1;
            self.time = Screen('Flip',self.window,self.when,...
                self.dontclear);
        end
    end
end
