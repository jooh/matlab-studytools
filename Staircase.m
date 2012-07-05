classdef Staircase < hgsetget
    % A simple fixed step staircase. The mandatory arguments are nup and
    % stepup. All remaining properties are optional and can be customised
    % by named inputs. If stepdown is left undefined we infer stepdown size
    % from stepup and nup/ndown rule (see Garcia-Perez, 1996, Vis Res). 
    %
    % Initialisation:
    % st = Staircase(nup,stepup,[varargin])
    %
    % Properties:
    % thresh = 0; current threshold
    % threshinrange = 0; current threshold rescored to threshinrange
    % threshrange = [-inf inf]; % range (e.g., contrast limits of display)
    % threshest = []; % threshold estimate (mean thresh at reversals)
    % nup = 3; % number of correct before incrementing
    % ndown = 1; % number of incorrect before incrementing
    % stepup = []; % size of up increment
    % stepdown = []; % size of down increment
    % accuracy = []; % accuracy on each trial so far
    % accest = []; % mean accuracy across trials
    % history = []; % thresh on each trial
    % reversals = []; % trial indices for reversals in staircase direction
    % nreversals = 0; % number of reversals
    % direction = -1; % -1 if lower means harder, 1 for the opposite
    % lastchange = []; % stepup/stepdown depending on what happened last
    % lasttrial = 0; % trial index of last thresh change
    % ntrials = 0; % number of total trials
    % garcia = [0.2845, 0.5488, 0.7393, 0.8415]; % suggested stepdown
    %   ratios for [1:4]up / 1down staircases (Garcia-Perez)
    % idealacc = [0.7785, 0.8035, 0.8315, 0.8584]; % given G-P rules above,
    %   your staircase *should* converge on these mean accuracies
    %
    % Methods:
    % update(wascorrect); update staircase according to logical scalar or
    % array

    properties
        thresh = 0;
        threshinrange = 0;
        threshrange = [-inf inf];
        threshest = [];
        nup = 3;
        ndown = 1;
        stepup = [];
        stepdown = []; 
        accuracy = [];
        accest = [];
        history = [];
        reversals = [];
        nreversals = 0;
        direction = -1;
        lastchange = [];
        lasttrial = 0;
        ntrials = 0;
        garcia = [0.2845, 0.5488, 0.7393, 0.8415];
        idealacc = [0.7785, 0.8035, 0.8315, 0.8584];
    end

    methods
        function st = Staircase(nup,stepup,varargin)
            st = varargs2structfields(varargin,st);
            st.nup = nup;
            st.stepup = stepup;
            if isempty(st.stepdown)
                % Use Garcia-Perez ratio
                assert(st.ndown==1,'garcia-perez only applies to 1 down');
                st.stepdown = st.stepup / st.garcia(st.nup);
            else
                st.stepdown = abs(st.stepdown);
            end
        end

        function update(self,wascorrect)
            % serial update mode
            if numel(wascorrect) > 1
                for wc = asrow(wascorrect)
                    self.update(wc);
                end
                return
            end
            self.ntrials = self.ntrials+1;
            self.accuracy(self.ntrials) = wascorrect;
            self.accest = mean(self.accuracy);
            self.history(self.ntrials) = self.thresh;
            if self.ntrials >= self.nup && ...
                    (self.ntrials-self.lasttrial)>=self.nup && ...
                    all(self.accuracy(...
                    self.ntrials-(self.nup-1):self.ntrials)==1)
                change = self.stepup*self.direction;
            elseif self.ntrials >= self.ndown && ...
                    (self.ntrials-self.lasttrial)>=self.ndown && ...
                    all(self.accuracy(...
                    self.ntrials-(self.ndown-1):self.ntrials)==0)
                change = self.stepdown*self.direction*-1;
            else
                return
            end
            self.thresh = self.thresh + change;
            self.threshinrange = inrange(self.thresh,self.threshrange);
            if ~isempty(self.lastchange) && change~=self.lastchange
                self.nreversals = self.nreversals+1;
                self.reversals(self.nreversals) = self.ntrials;
                self.threshest = mean(self.history(self.reversals));
            end
            self.lastchange = change;
            self.lasttrial = self.ntrials;
        end
    end
end
