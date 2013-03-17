classdef VideoEvent < StreamEvent
    % StudyEvent subclass for presenting a video frame 
    properties
        %videoframes = []; % [x y color frame] matrix
        alpha = []; % alpha layer
        tex = []; % texture handle
        rect = []; % Psychtoolbox rect
        window = []; % window handle
        name = 'video';
    end

    methods
        function s = VideoEvent(vidframes,st,varargin)
        % Initialise event by populating fields, possibly making texture
            s = varargs2structfields(varargin,s);
            %s.videoframes = vidframes;
            s.window = st.window;
            if ieNotDefined('alpha')
                alpha = ones(size(vidframes));
            end
            s.nframe = size(vidframes,4);
            % do we need to make texture?
            if isempty(s.tex)
                % add singleton dims if necessary (e.g. image rather than
                % vid)
                nd = ndims(vidframes);
                if nd < 4
                    vidframes = reshape(vidframes,...
                        [size(vidframes) ones(1,4-nd)]);
                end
                s.tex = NaN([1 s.nframe]);
                for f = 1:s.nframe
                    s.tex(f) = Screen('MakeTexture',s.window,...
                    cat(3,vidframes(:,:,:,f),uint8(255*s.alpha)));
                end
            end
            s.initialiseframes;
        end

        function call(self)
            self.ncalls = self.ncalls+1;
            self.time = GetSecs;
            frame = self.getframeind;
            % nb we don't flip to allow multiple draws before flip
            Screen('DrawTexture',self.window,self.tex(frame),[],...
                self.rect);
        end
    end
end
