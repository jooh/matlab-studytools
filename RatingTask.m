classdef RatingTask < Study
    % Study subclass for running rating tasks. The responsename field
    % identifies which event to log, while conditionname provides the
    % underlying construct and scoring provides the modality (+,-)
    % field of Condition instances
    properties
        responsename = '';
        noptions = 5;
        keyind = [];
        timeind = 1; % score RTs relative to this studyevent
        conditionname = 'name'; % construct
        scoring = 1; % positive by default
        score = struct;
        constructs = {}; % cell array of unique conditionnames
    end

    methods
        function s = RatingTask(varargin)
            s = varargs2structfields(varargin,s);
            % use the right default response name
            if isempty(s.responsename)
                s.responsename = 'responsecheck';
            end
        end

        function initialisescore(self,trialorder);
            % prepare the score field for study (clearing out whatever is
            % already in there)
            self.constructs = unique(...
                self.conditions(unique(trialorder)).conditionname);
            % struct arr with one entry per construct (collapsing
            % individual items)
            self.score = struct('construct',constructs,...
                'mean',[],'stdev',[],'n',0,'median',[],'rawresp',[],...
                'rawrt',[]);
        end

        function scoretrial(self,t)
            % Populate 'score' field in self.trials(t) with result of
            % current trial
            % find index into correct construct for this condition
            conind = findStrInArray(self.constructs,...
                self.trials(t).condition.conditionname);
            % extract keys and times
            respkeys = cell2mat(self.trials(t).response(respinds));
            responsetime = cell2mat(self.trials(t).responsetime(respinds));
            % Convert to RT
            rts = responsetime - self.trials(t).time(self.timeind);
            % restrict to the correct key, first press
            correctkey = respkeys==self.validkeys(self.keyind);
            firstind = find(correctkey,1,'first');
            % set trial score
            rt = rts(firstind);
            % TODO: SCORE - 1 / -1 etc
            respkey = respkeys(firstind);
            self.trials(t).score.rt = rt;
            self.trials(t).score.respk = respkey;
            self.trials(t).score.construct = self.constructs{conind};
            if isempty(correctkey)
                return
            end
            % copy score to condition as well
            self.trials(t).condition.result(...
                self.trials(t).condition.ncalls).score = ...
                self.trials(t).score;
            % set running totals
            n = self.score(conind).n + 1;
            self.score(conind).n = n;
            self.score(conind).respk(n) = respk;
            self.score(conind).rawrt(n) = rt;
        end
    end
end
