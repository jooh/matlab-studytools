classdef ScanPreCondition < Condition
    % Condition subclass that runs through the studyevents with its own
    % SecondTiming and ends on a timecontrol.begin (your timecontrol
    % instance will be in units scans). Used as a precondition to get
    % through instructions and eye tracking, then wait for dummies and sync
    % experiment start to the scanner TR. Note that your final events
    % should be something like TextEvent('get ready..',st) and a flip since
    % this is what will remain on the screen during the dummies that follow
    % the last studyevent.
    %
    % This special case is only really necessary for scanner experiments
    % where you want to run your trials in seconds. If your entire paradigm
    % is in scan units you can just use a standard Condition instance for
    % your precondition since Study already does a call to
    % timecontrol.begin.
    properties
        roughtiming = SecondTiming; % used to track events before scan
    end

    methods
        function t = ScanPreCondition(studyevents,varargin);
            if nargin==0
                return
            elseif nargin==1 && isempty(studyevents)
                t = t([]);
                return
            end
            t = varargs2structfields(varargin,t);
            t.studyevents = studyevents;
            % preallocate fields
            t.nevents = length(studyevents);
            t.time = zeros(1,t.nevents);
            t.response = cell(1,t.nevents);
            % extract vector of durations
            durations = cellfun(@(x)x.duration,t.studyevents);
            % and use to figure out when events should appear
            t.preparetiming(durations);
            % start the rough timer on init since we don't care about this
            % timer anyway
            t.roughtiming.begin;
            % need to preparelog since this won't happen inside runtrials
        end

        function call(self)
            % NB we overwrite the log every time here. 
            self.preparelog(1);
            calltime = self.roughtiming.check;
            self.ncalls = self.ncalls+1;
            for e = 1:self.nevents
                self.result.time(e) = self.roughtiming.check;
                done = 0;
                responded = 0;
                while ~done
                    self.studyevents{e}.call;
                    if ~isempty(self.studyevents{e}.response)
                        responded = 1;
                        % add response to log
                        self.result.response{e} = ...
                            [self.result.response{e} ...
                            self.studyevents{e}.response];
                        % remove from studyevent (prevent handle weirdness)
                        self.studyevents{e}.response = [];
                        self.result.responsetime{e} = ...
                            [self.result.responsetime{e} ...
                            self.studyevents{e}.responsetime];
                        % remove from studyevent (prevent handle weirdness)
                        self.studyevents{e}.responsetime = [];
                    end
                    % check for skipahead flag and timeout
                    skip = responded && self.studyevents{e}.skiponresponse;
                    % now absolute timings to reduce lag
                    outoftime = self.roughtiming.check > ...
                        (calltime+self.timing(e));
                    done = skip || outoftime;
                end
            end
            % ok, all events done - time for scanner sync
            self.timecontrol.begin;
        end
    end
end
