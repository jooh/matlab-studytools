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
            durations = cellfun(@(x)x.duration,t.studyevents);
            % ideal timings relative to onset
            t.timing = cumsum(durations);
        end

        function preparelog(self,ntrials)
            % time, responses, and 'score', which is the result of postcall
            self.result = struct('time',...
                repmat({self.time},[ntrials 1]),'response',...
                repmat({self.response},[ntrials 1]),'responsetime',...
                repmat({self.response},[ntrials 1]),...
                'score',[]);
        end

        function call(self)
            calltime = self.timecontrol.check;
            self.ncalls = self.ncalls+1;
            for e = 1:self.nevents
                self.result(self.ncalls).time(e) = self.timecontrol.check;
                done = 0;
                responded = 0;
                while ~done
                    self.studyevents{e}.call;
                    if ~isempty(self.studyevents{e}.response)
                        responded = 1;
                        % add response to log
                        self.result(self.ncalls).response{e} = ...
                            [self.result(self.ncalls).response{e} ...
                            self.studyevents{e}.response];
                        % remove from studyevent (prevent handle weirdness)
                        self.studyevents{e}.response = [];
                        self.result(self.ncalls).responsetime{e} = ...
                            [self.result(self.ncalls).responsetime{e} ...
                            self.studyevents{e}.responsetime];
                        % remove from studyevent (prevent handle weirdness)
                        self.studyevents{e}.responsetime = [];
                    end
                    % check for skipahead flag and timeout
                    skip = responded && self.studyevents{e}.skiponresponse;
                    % now absolute timings to reduce lag
                    outoftime = (calltime + self.timing(e)) < ...
                        self.timecontrol.check;
                    done = skip || outoftime;
                end
            end
        end
    end
end
