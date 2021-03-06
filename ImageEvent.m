classdef ImageEvent < StudyEvent
    % StudyEvent subclass for presenting images
    properties
        %image = []; % image
        alpha = []; % alpha layer
        tex = []; % texture handle
        rect = []; % Psychtoolbox rect
        window = []; % window handle
        name = 'image';
    end

    methods
        function s = ImageEvent(im,st,varargin)
        % Initialise event by populating fields, possibly making texture
            sout = varargs2structfields(varargin,s);
            for fn = fieldnames(sout)'
                s.(fn{1}) = sout.(fn{1});
            end
            %s.image = im;
            s.window = st.window;
            if ieNotDefined('alpha')
                s.alpha = ones(size(im));
            end
            % do we need to make texture?
            if isempty(s.tex)
                s.tex = Screen('MakeTexture',s.window,...
                    cat(3,im,uint8(255*s.alpha)));
            end
        end

        function call(self)
            self.ncalls = self.ncalls+1;
            self.time = GetSecs;
            % nb we don't flip to allow multiple draws before flip
            Screen('DrawTexture',self.window,self.tex,[],self.rect);
        end
    end
end
