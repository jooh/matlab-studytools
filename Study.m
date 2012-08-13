classdef Study < hgsetget & dynamicprops
    % Master class for running cognitive experiments
    properties
        %precision = 1e-3; % how often to re-call in s
        units = 's'; % timing in s or scans (not yet supported)
        trackscans = false; % keep track of triggers
        time_study = GetSecs;
        time_event = 0;
        time_resp = 0;
        eventvec = [];
        ev = 0;
    end

    methods
        function s = Study(varargin)
            if nargin==0
                % initialisation of inherited objects etc
                return
            end
            s = varargs2structfields(varargin,s);
        end

        function runevents(self,eventvec)
            if nargin==2
                self.eventvec = eventvec;
            end
            nevents = length(self.eventvec);
            for self.ev = 1:nevents
                self.time_event = GetSecs;
                % make sure we do all events once, even if impulse
                % check for skipahead flag also
                while self.eventvec(self.ev).ncalls==0 && ...
                        self.eventvec(self.ev).skipahead==0 &&
                        (GetSecs < ...
                        (self.time_event+eventvec(self.ev).duration))
                    eventvec(self.ev).call;
                    calledonce = 1;
                end
                self.callback;
            end
        end
        
        function callback(self,output)
            % placeholder
            self.ncalls = self.ncalls+1;
            error('Use inherited classes.')
            return
        end
    end
end
