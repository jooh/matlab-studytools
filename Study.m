classdef Study < hgsetget & dynamicprops
    % Master class for running cognitive experiments
    properties
        %precision = 1e-3; % how often to re-call in s
        units = 's'; % timing in s or scans (not yet supported)
        trackscans = false; % keep track of triggers
        timing = struct('study',0,'trial',0,'event',0);
        debug = 0; % shorthand for debug=1, verbose=1
        verbose = 0;
        windowed = 0;
        ev = 0;
        screen = [];
        window = [];
        rect = [];
        totdist = 500;
        screenwidth = 380;
        validkeys = {'v','b','n','m'};
        location = 'pc';
        TR = [];
        scanobj = [];
        resolution = [1024 768];
        oldresolution = [NaN NaN];
        px2deg = [];
        deg2px = [];
        bgcolour = [];
        colours = struct('white',[],'black',[],'grey',[]);
        textpar = struct('font','tahoma','size',14,'style',0,...
            'vspacing',1.4,'colour',[1 1 1],'txtwrap',50);
        xcenter = [];
        ycenter = [];
        conditions = {}; % each unique condition
        trialorder = []; % indices into conditions
        trials = {}; % conditions{trialorder}
    end

    methods
        function s = Study(varargin)
            if nargin==0
                % initialisation of inherited objects etc
                return
            end
            s = varargs2structfields(varargin,s);
        end

        function openwindow(self)
            if self.debug
                self.verbose = 1;
                self.windowed = 1;
            end
            switch self.location
                case 'pc'
                    screens = Screen('Screens');
                    self.screen = screens(ceil(length(screens)/2));
                    self.totdist = '500';
                    self.screenwidth = '380';
                    self.validkeys = {'v','b','n','m'};
                case 'mri'
                    self.screen = 0;
                    self.totdist = 913;
                    self.screenwidth = 268;
                    self.validkeys = [28 26 24 22];
                    self.scanobj = actxserver('MRISync.ScannerSync');
                    err = invoke(f.scanobj,'Initialize','');
                    assert(~err,'Keithley error')
                    assert(isnumeric(self.TR),'must set TR for scanner sync!')
                    invoke(self.scanobj,'SetTimeout',double(20000)); % 20
                    invoke(self.scanobj,'SetMSPerSample',2);
                otherwise
                    error('unrecognised location: %s',self.location)
            end
            % On any recent Mac OS version, PPT works very poorly at the moment
            if ismac
                Screen('Preference','SkipSyncTests',1);
            else
                Screen('Preference','SkipSyncTests',0);
            end
            self.px2deg = (2 * atan(self.screenwidth/2/self.totdist) * ...
                (180/pi)) / self.resolution(1);
            % And the reciprocal
            self.deg2px = self.px2deg^-1;
            % Figure out a text colour
            if mean(self.bgcolour) > 200
                % black on light backgrounds
                self.textpar.colour = [0 0 0];
            else
                % white on dark backgrounds
                self.textpar.colour = [255 255 255];
            end
            % open window
            if self.windowed
                self.oldresolution = Screen('Resolution',self.screen);
                res = [0 0 self.resolution];
                [self.window self.rect] = Screen('OpenWindow',...
                    self.screen,self.bgcolour,res);
            else
                self.oldresolution = Screen('Resolution',self.screen,...
                    self.resolution(1),self.resolution(2));
                [self.window self.rect] = Screen('OpenWindow',...
                    self.screen,self.bgcolour);
            end
            % set default bgcolour
            %Screen(self.window,'FillRect',self.bgcolour);
            % screen center
            self.xcenter = self.rect(3)/2;
            self.ycenter = self.rect(4)/2;
            % enable alpha blending
            Screen('BlendFunction',self.window,GL_SRC_ALPHA,...
                GL_ONE_MINUS_SRC_ALPHA);
            % priority (0 for normal, 2 locks all non-Matlab)
            Priority(1);
            % basic colours
            self.colours.white = WhiteIndex(self.window); 
            self.colours.black = BlackIndex(self.window);
            self.colours.grey = ceil((...
                self.colours.white+self.colours.black)/2); 
            % and fonts
            Screen('TextFont',self.window,self.textpar.font);
            Screen('TextSize',self.window,self.textpar.size);
            Screen('TextStyle',self.window,self.textpar.style);
            Screen('TextColor',self.window,self.textpar.colour);
            HideCursor;
            Screen(self.window,'Flip');
        end

        function closewindow(self)
            Screen('Close',self.window);
        end

        function runtrials(self,trialorder)
            assert(isempty(self.trials),'TODO: handle repeated runs')
            ntrials = length(trialorder);
            % upcast conditions to full sequence
            self.trials = self.conditions(trialorder);
            timing.study = GetSecs;
            for t = 1:ntrials
                timing.trial = GetSecs;
                for e = 1:length(self.trials(t).studyevents)
                    self.timing.event = GetSecs;
                    % make sure we do all events once, even if impulse
                    done = 0;
                    while ~done
                        self.trials(t).studyevents{e}.call;
                        % check for skipahead flag and timeout
                        done = ...
                            (self.trials(t).studyevents{e}.skipahead==0)...
                            || (GetSecs < (self.timing.event + ...
                                self.trials(t).studyevents{e}.duration));
                    end
                    % analyse trial (across events)
                    self.trials(t).postcall;
                end
                % analyse study (across trials)
                self.postcall(t);
            end
        end
    end

    methods (Abstract)
        postcall(self,t)
    end
end
