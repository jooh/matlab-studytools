classdef Condition < hgsetget & dynamicprops
    % Store a cell array of study events as a condition. Use 
    % preparelog(ntrials) to initialise a log file, and then call to run
    % the condition (usually from Study subclass)
    properties
        studyevents = [];
        nevents = 0;
        time = [];
        response = {};
        result = struct;
        ncalls = 0;
        soa = 0; % 50ms above the sum of durations should be enough
        name = 'condition';
        timing = [];
        timecontrol = []; % ScanTiming / SecondTiming 
        logresponses = 1;
        duration = 0;
        skiponresponse = 0;
    end

    methods
        function t = Condition(studyevents,varargin);
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
            eventdurations = cellfun(@(x)x.duration,t.studyevents);
            % ideal timing relative to onset
            t.preparetiming(eventdurations);
        end

        function preparetiming(self,eventdurations)
            % initialise the timing either based on a simple cumsum call of
            % durations or something a bit more complicated when inf
            % durations are present
            infcheck = isinf(eventdurations);
            if any(infcheck)
                % can't do absolute timings, so need to ensure that you
                % haven't attempted to inf and THEN do something with a
                % duration
                firstinf = find(infcheck,1,'first');
                % there's only a problem if you didn't put the inf last
                if firstinf ~= self.nevents
                    hasdur = eventdurations > 0;
                    isbad = hasdur & ~infcheck;
                    assert(~any(isbad((firstinf+1):end)),...
                        'non-zero, non-inf eventdurations after inf duration');
                end
                % set timings to equal eventdurations - so either move
                % forward immediately (duration 0), or wait forever for a
                % response (duration inf)
                self.timing = eventdurations;
            else
                % if you've stayed away from infinite eventdurations this
                % is much easier
                % ideal timings relative to onset
                self.timing = cumsum(eventdurations);
                if isempty(self.timing)
                    self.timing = 0;
                end
            end
            assert((isinf(self.duration)&&~self.skiponresponse)==0,...
                'must set skiponresponse if using infinite duration')
            % Set condition duration to equal event duration by default (so
            % fixed dur or inf if you have infs in event timings)
            if self.duration==0
                self.duration = self.timing(end);
            end
        end

        function preparelog(self,ntrials)
            % time, responses, and 'score', which is the result of postcall
            self.result = struct('time',...
                repmat({self.time},[ntrials 1]),'response',...
                repmat({self.response},[ntrials 1]),'responsetime',...
                repmat({self.response},[ntrials 1]),...
                'score',[],'endtime',[]);
            % ensure ncalls is 0 (not always the case if doing subruns)
            self.ncalls = 0;
        end

        function call(self)
            self.ncalls = self.ncalls+1;
            % track ideal time when condition should end
            conendtime = self.timecontrol.check+self.duration;
            % flag for condition timer
            outofcontime = false;
            % flag for responses when skiponresponses
            skipcon = false;

            % keep running the condition until out of time or skipping on
            % response
            while ~any([outofcontime skipcon])
                % run event timings relative to this
                calltime = self.timecontrol.check;
                % iterate over events
                for e = 1:self.nevents
                    % flag for skiponresponse for the event (e.g. if
                    % infinite duration and waiting for a response)
                    skipevent = false;
                    % flag for event timer
                    outofeventtime = false;
                    % event timings are relative to this
                    self.result(self.ncalls).time(e) = ...
                        self.timecontrol.check;
                    % flag for responses inside to this event
                    responded = false;
                    % flag to ensure that each event gets called at least
                    % once. This is important to insure that flip events
                    % get called even if we are lagging.
                    ranonce = false;

                    % if we were awaiting a response (skipevent,skipcon),
                    % always skip ahead. If we were awaiting the end of the
                    % timer (outofcontime,outofeventtime), only skip once
                    % the event has been called. 
                    while ~(skipevent || skipcon) && ~(ranonce && (outofcontime || outofeventtime))
                        self.studyevents{e}.call;
                        ranonce = true;
                        if ~isempty(self.studyevents{e}.response)
                            responded = true;
                            if self.logresponses
                                % add response to log
                                self.result(self.ncalls).response{e} = ...
                                    [self.result(self.ncalls).response{e} ...
                                    self.studyevents{e}.response];
                                % remove from studyevent (prevent handle
                                % weirdness)
                                self.studyevents{e}.response = [];
                                self.result(self.ncalls).responsetime{e} = ...
                                    [self.result(self.ncalls).responsetime{e} ...
                                    self.studyevents{e}.responsetime];
                                % remove from studyevent (prevent handle
                                % weirdness)
                                self.studyevents{e}.responsetime = [];
                            end
                        end
                        % check for skipahead flag and timeout
                        skipevent = responded && ...
                            self.studyevents{e}.skiponresponse;
                        skipcon = responded && self.skiponresponse;
                        % now absolute timings to reduce lag
                        timenow = self.timecontrol.check;
                        outofeventtime = (calltime + self.timing(e)) < ...
                            timenow;
                        outofcontime = conendtime < timenow;
                    end % / while (this event)
                    if skipcon
                        % kill remainder of event loop
                        break
                    end
                end % / for e = 1:self.nevents
            end % / while (this condition)
            % store what time we got out of the condition
            self.result(self.ncalls).endtime = self.timecontrol.check;
        end % / call method
    end
end
