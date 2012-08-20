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
        end

        function call(self)
            self.ncalls = self.ncalls+1;
            self.time = GetSecs;
            self.frame = self.frame+self.direction;
            % nb we don't flip to allow multiple draws before flip
            Screen('DrawTexture',self.window,self.tex(self.frame),[],...
                self.rect);
            if self.frame == 1 && self.direction==-1
                % if we hit frame 1 going backwards, reverse
                self.direction = 1;
            elseif self.frame == self.nframe
                if self.rewind
                    % if we hit nframe in rewind mode...
                    self.frame = 0;
                else
                    % if we are looping back and forth, just change
                    % direction
                    self.direction = -1;
                end
            end
        end
    end
end
