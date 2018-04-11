classdef NBack < Study
    % Study subclass for running N-back tasks. The NBack is on the 'name'
    % field of Condition instances
    properties
        n = 1; % how many back to track
        responsename = '';
        keyind = 1;
        timeind = 1; % score RTs relative to this studyevent
        conditionname = 'name'; % use custom field for flexible 1-back
        compfun = @strcmp;
        feedbackhit = Condition([]);
        feedbackmiss = Condition([]);
        feedbackfa = Condition([]);
        feedbackcr = Condition([]);
    end

    methods
        function s = NBack(varargin)
            sout = varargs2structfields(varargin,s);
            for fn = fieldnames(sout)'
                s.(fn{1}) = sout.(fn{1});
            end
            % use the right default response name
            if isempty(s.responsename)
                s.responsename = 'responsecheck';
            end
            if isnumeric(s.conditionname)
                s.compfun = @isequal;
            end 
        end

        function initialisescore(self,trialorder)
            % prepare the score field for study (clearing out whatever is
            % already in there)
            self.score = struct('ntrials',length(trialorder),...
                'nhit',0,'nmiss',0,'nfa',0,'ncr',0,'acc',[],'d',[]);
        end

        function scoretrial(self,t)
            % Populate 'score' field in self.trials(t) with result of
            % current trial
            % find indices for events with correct name
            respinds = strfindcell(cellfun(@(x)x.name,...
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
            self.trials(t).score.wasrepeat = self.compfun(...
                self.trials(t).condition.(self.conditionname),...
                self.trials(t-self.n).condition.(self.conditionname));
            % copy score to condition as well
            self.trials(t).condition.result(...
                self.trials(t).condition.ncalls).score = ...
                self.trials(t).score;
            % update running totals
            self.score.nhit = self.score.nhit + ...
                (self.trials(t).score.didrespond && ...
                self.trials(t).score.wasrepeat);
            self.score.nfa = self.score.nfa + ...
                (self.trials(t).score.didrespond && ...
                ~self.trials(t).score.wasrepeat);
            self.score.ncr = self.score.ncr + ...
                (~self.trials(t).score.didrespond && ...
                ~self.trials(t).score.wasrepeat);
            self.score.nmiss = self.score.nmiss + ...
                (~self.trials(t).score.didrespond && ...
                self.trials(t).score.wasrepeat);
            % also show feedback?
            if self.feedback
                % only show feedback when behaviourally correct AND you
                % have defined a feedback condition for that outcome
                if self.trials(t).score.wasrepeat
                    if self.trials(t).score.didrespond && ~isempty(self.feedbackhit)
                        self.feedbackhit.call;
                    elseif ~self.trials(t).score.didrespond && ~isempty(self.feedbackmiss)
                        self.feedbackmiss.call;
                    end
                else
                    if self.trials(t).score.didrespond && ~isempty(self.feedbackfa)
                        self.feedbackfa.call;
                    elseif ~self.trials(t).score.didrespond && ~isempty(self.feedbackcr)
                        self.feedbackcr.call;
                    end
                end
            end
        end

    end
end
