classdef TextVideoEvent < StreamEvent & TextEvent
    % StudyEvent subclass for presenting a stream of text strings 

    methods
        function s = TextVideoEvent(textstr,st,varargin)
            s.textstr = textstr;
            sout = varargs2structfields(varargin,s);
            for fn = fieldnames(sout)'
                s.(fn{1}) = sout.(fn{1});
            end
            s.nframe = length(textstr);
            s.initialisetext(st);
            s.initialiseframes;
        end

        function call(self)
            self.ncalls = self.ncalls+1;
            self.time = GetSecs;
            frame = self.getframeind;
            DrawFormattedText(self.window,self.textstr{frame},self.x,...
                self.y,self.color,self.txtwrap,0,0,self.vspacing);
        end
    end
end
