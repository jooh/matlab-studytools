% ScanTiming < Timing
classdef ScanTiming < Timing
    % Timing object for running events relative to scans from scannersync
    properties
        tr
        scanobj
    end

    methods
        function t = ScanTiming(varargin)
        % Set pulse and run through dummy volumes, provide a first
        % estimate of tr.
        % t = ScanTiming(varargin)
            t = varargs2structfields(varargin,t);
            t.units = 'scans';
        end

        function scan = begin(self)
            % initialise
            self.scanobj('reset',self.tr);
            % wait for first pulse - I think this is where things go weird.
            [starttime,scan] = self.scanobj(1,Inf);
            self.first = scan;
        end

        function tim = check(self)
        % returns the current estimated scan number and updates the
        % previous and current properties
        % tim = check;
            self.previous = self.current;
            % check for scan number and return immediately
            [~,scan] = self.scanobj(1,0);
            [self.current,tim] = deal(scan);
        end

        function waituntil(self,abstime)
        % keep synchronising until check returns abstime
        % waituntil(vol)
            % wait until we are 1 short of the intended time (the final time we
            % want to proceed)
            while self.check < abstime
                ch = self.check;
            end
        end
    end
end
