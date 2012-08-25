classdef NBack < Study
    % Study subclass for running N-back tasks. The NBack is on the 'name'
    % field of Condition instances
    properties
        n = 1; % how many back to track
        responsename = '';
        keyind = 1;
        timeind = 1; % score RTs relative to this studyevent
        conditionname = 'name'; % use custom field for flexible 1-back
        nhit = 0; % running totals
        nmiss = 0;
        nfa = 0; 
        ncr = 0;
    end

    methods
        function s = NBack(varargin)
            s = varargs2structfields(varargin,s);
            % use the right default response name
            if isempty(s.responsename)
                s.responsename = 'responsecheck';
            end
        end

        function scoretrial(self,t)
            % Populate 'score' field in self.trials(t) with result of
            % current trial
            % find indices for events with correct name
            respinds = findStrInArray(cellfun(@(x)x.name,...
                self.trials(t).condition.studyevents,'uniformoutput',...
                false),self.responsename);
            % extract keys and times
            respkeys = cell2mat(self.trials(t).response(respinds));
            responsetime = cell2mat(self.trials(t).responsetime(respinds));
            % Convert to RT
            rts = responsetime - self.trials(t).time(self.timeind);
            % restrict to the correct key
            correctkey = respkeys==self.validkeys(self.keyind);
            self.trials(t).score.didrespond = any(correctkey);
            self.trials(t).score.rt = rts(find(correctkey,1,'first'));
            if (t-self.n) < 1
                % responses to first trials must be FAs
                self.trials(t).score.wasrespeat = 0;
                return
            end
            self.trials(t).score.wasrepeat = strcmp(...
                self.trials(t).condition.(self.conditionname),...
                self.trials(t-self.n).condition.(self.conditionname));
            % copy score to condition as well
            self.trials(t).condition.result(...
                self.trials(t).condition.ncalls).score = ...
                self.trials(t).score;
            % update running totals
            self.nhit = self.nhit + (self.trials(t).score.didrespond && ...
                self.trials(t).score.wasrepeat);
            self.nfa = self.nfa + (self.trials(t).score.didrespond && ...
                ~self.trials(t).score.wasrepeat);
            self.ncr = self.ncr + (~self.trials(t).score.didrespond && ...
                ~self.trials(t).score.wasrepeat);
            self.nmiss = self.nmiss + ...
                (~self.trials(t).score.didrespond && ...
                self.trials(t).score.wasrepeat);
        end
    end
end
