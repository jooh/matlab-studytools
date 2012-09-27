classdef RatingTask < Study
    % Study subclass for running rating tasks. The responsename field
    % identifies which event to log, while conditionname provides the
    % underlying construct and scoring provides the modality (+,-)
    % field of Condition instances
    properties
        responsename = '';
        noptions = 5;
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
            allconstructs = cell2mat(get(...
                self.conditions,self.conditionname));
            self.constructs = unique(allconstructs);
            % struct arr with one entry per construct (collapsing
            % individual items)
            self.score = struct('construct',num2cell(self.constructs),...
                'mean',[],'stdev',[],'n',0,'median',[],'rawresp',[],...
                'rawrt',[]);
        end

        function scoretrial(self,t)
            % Populate 'score' field in self.trials(t) with result of
            % current trial
            % find index into correct construct for this condition
            conind = find(self.constructs ==  ...
                self.trials(t).condition.construct);
            % extract keys and times
            respinds = findStrInArray(cellfun(@(x)x.name,...
                self.trials(t).condition.studyevents,'uniformoutput',...
                false),self.responsename);
            % keys
            respkeys = cell2mat(self.trials(t).response(respinds));
            % times
            responsetime = cell2mat(self.trials(t).responsetime(respinds));
            % Convert to RT
            rts = responsetime - self.trials(t).time(self.timeind);
            % Restrict to correct keys
            [goodkeys,goodinds,validind] = intersect(respkeys,...
                self.validkeys);
            if isempty(goodkeys)
                return
            end
            % only consider first resp
            respk = goodkeys(1);
            % set trial score
            rt = rts(goodinds(1));
            self.trials(t).score.rt = rt;
            % store as score - with negative scoring support
            self.trials(t).score.respk = abs(validind - ...
                ((1+self.noptions)*(self.constructs(conind)<0)));
            self.trials(t).score.construct = abs(self.constructs(conind));
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
