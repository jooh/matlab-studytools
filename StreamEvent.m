classdef StreamEvent < StudyEvent
    % StudyEvent intermediate class for presenting a stream of stimuli 
    properties
        rewind = 0; % play videos in one direction only if 0
        direction = 1; % 1 forward, -1 backward
        nframe = []; 
        frameind = [];
        nind = []; % track number of frames - >nframe if rewind
    end

    methods

        function s = StreamEvent(varargin)
            if nargin==0
                return
            end
            error('must subclass this event type to use')
        end

        function initialiseframes(self)
            if isempty(self.frameind)
                if self.direction==1
                    self.frameind = 1:self.nframe;
                else
                    self.frameind = self.nframe:-1:1;
                end
            end
            if self.rewind
                self.frameind = [self.frameind self.frameind(end-1:-1:2)];
            end
            self.nind = length(self.frameind);
        end

        function ind = getframeind(self);
            % this operation ensures we are always passing through the
            % 1:nind range
            ind = self.frameind(rem(self.ncalls-1,self.nind)+1);
        end
    end
end
