classdef ScanTiming < Timing
    % Timing object for running events relative to scans from scannersync
    properties
        tr = [];
    end

    methods
        function t = ScanTiming(varargin)
        % Set pulse and run through dummy volumes, provide a first
        % estimate of tr.
        % t = ScanTiming(varargin)
            t = varargs2structfields(varargin,t);
            if t.tr < 60
                % assume you've provided the tr in s rather than ms
                t.tr = t.tr * 1e3;
            end
            t.units = 'scans';
        end

        function scan = begin(self)
            err = invoke(self.scanobj,'StartExperiment',self.tr);
            assert(~err,'StartExperiment failed!');
            % figure out tr
            oldtr = self.tr;
            % should now have an ok idea of what the actual tr is
            self.estimatetr;
            assert(isempty(oldtr) || (abs(oldtr-self.tr)<200),...
                'tr diverges by more than 200 ms from tr estimate');
            % set first scan as whatever we've got at this point
            [self.first,scan] = deal(self.check);
        end

        function tim = check(self)
        % returns the current estimated scan number and updates the
        % previous and current properties
        % tim = check;
            self.previous = self.current;
            [self.current,tim] = deal(invoke(self.scanobj,...
                'GetLastPulseNum',0));
        end

        function waituntil(self,abstime)
        % keep synchronising until check returns abstime
        % waituntil(vol)
            while self.check < abstime
                invoke(self.scanobj,'SynchroniseExperiment',1,0);
            end
        end

        function syncseconds(self,s)
        % update tr estimate by waiting around for s duration
        % syncseconds(s)
            invoke(self.scanobj,'CheckPulseSynchronyForTime',s*1e3);
        end

        function tr = estimatetr(self)
        % return an estimate of the tr (in ms) from scanobj. Will be more
        % accurate the more time you spend on syncseconds or waituntil.
        % tr = estimatetr;
            [tr,self.tr] = deal(invoke(self.scanobj,'GetMeasuredTR'));
        end
    end
end
