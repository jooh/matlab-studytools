classdef VideoEvent < StudyEvent
    % StudyEvent subclass for presenting a video frame 
    properties
        videoframes = []; % [x y color frame] matrix
        alpha = []; % alpha layer
        tex = []; % texture handle
        rect = []; % Psychtoolbox rect
        window = []; % window handle
        name = 'video';
        rewind = 0; % play videos in one direction only if 0
        direction = 1; % 1 forward, -1 backward
        frame = 0; % track which frame we are on - incremented on each trial
        nframe = []; 
        frameind = [];
        nind = []; % track number of frames - >nframe if rewind
    end

    methods
        function s = VideoEvent(vidframes,st,varargin)
        % Initialise event by populating fields, possibly making texture
            s = varargs2structfields(varargin,s);
            s.videoframes = vidframes;
            s.window = st.window;
            if ieNotDefined('alpha')
                alpha = ones(size(vidframes));
            end
            s.nframe = size(vidframes,4);
            % do we need to make texture?
            if isempty(s.tex)
                s.tex = NaN([1 s.nframe]);
                for f = 1:s.nframe
                    s.tex(f) = Screen('MakeTexture',s.window,...
                    cat(3,s.videoframes(:,:,:,f),uint8(255*s.alpha)));
                end
            end
            if ieNotDefined('frameind')
                if s.direction==1
                    s.frameind = 1:s.nframe;
                else
                    s.frameind = s.nframe:-1:1;
                end
            end
            if s.rewind
                s.frameind = [s.frameind s.frameind(end-1:-1:2)];
            end
            s.nind = length(s.frameind);
        end

        function call(self)
            self.ncalls = self.ncalls+1;
            self.time = GetSecs;
            % this operation ensures we are always passing through the
            % 1:nind range
            self.frame = self.frameind(rem(self.ncalls-1,self.nind)+1);
            % nb we don't flip to allow multiple draws before flip
            Screen('DrawTexture',self.window,self.tex(self.frame),[],...
                self.rect);
        end
    end
end
