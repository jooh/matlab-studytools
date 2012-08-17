classdef Condition < hgsetget & dynamicprops
    % Store a cell array of study events as a condition. Use 
    % preparelog(ntrials) to initialise a log file, and then call to run
    % the condition (usually from Study subclass)
    properties
        studyevents = [];
        eventname = 'condition';
        nevents = 0;
        time = [];
        response = {};
        result = struct;
        ncalls = 0;
    end

    methods
        function t = Condition(varargin);
            if nargin==0
                return
            elseif nargin==1 && isempty(varargin{1})
                t = t([]);
                return
            end
            t.studyevents = varargin;
            % preallocate fields
            t.nevents = nargin;
            t.time = zeros(1,t.nevents);
            t.response = cell(1,t.nevents);
        end

        function preparelog(self,ntrials)
            % time, responses, and 'score', which is the result of postcall
            self.result = struct('time',...
                repmat({self.time},[ntrials 1]),'response',...
                repmat({self.response},[ntrials 1]),...
                'score',[]);
        end

        function call(self)
            self.ncalls = self.ncalls+1;
            for e = 1:self.nevents
                self.result(self.ncalls).time(e) = GetSecs;
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
                    end
                    % check for skipahead flag and timeout
                    skip = responded && self.studyevents{e}.skiponresponse;
                    outoftime = (self.studyevents{e}.duration + ...
                        self.result(self.ncalls).time(e)) < GetSecs;
                    done = skip || outoftime;
                end
            end
        end
    end
end
