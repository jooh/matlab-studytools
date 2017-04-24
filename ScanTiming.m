% Scanner pulse-based timing control. This code operates in scanner time units
% and relies on scansync internally. 
%
% ScanTiming < Timing
classdef ScanTiming < Timing
    % Timing object for running events relative to scans from scannersync
    properties
        tr = NaN;
        scanobj = @scansync;
    end

    methods
        function t = ScanTiming(varargin)
        % t = ScanTiming(varargin)
            t = t@Timing(varargin{:});
            t.units = 'scans';
            assert(~isnan(t.tr),'must set TR for accurate scan timing')
        end

        function scan = begin(self)
            % initialise
            self.scanobj('reset',self.tr);
            % catch the first pulse
            [self.first,scan] = deal(waitpulse(self,1));
            update(self,self.first);
        end

        function scan = check(self)
        % returns the current estimated scan number and updates the
        % previous and current properties
        % tim = check;
            self.previous = self.current;
            % check for scan number and return immediately
            [~,scan] = self.scanobj(1,0);
            update(self,scan);
        end

        function waituntil(self,abstime)
        % keep synchronising until check returns abstime
        % waituntil(vol)
            % are the current and target time on the same pulse, if so wait for
            % those pulses
            ch = waitpulse(self,floor(abstime)-floor(check(self)));
            % this if block could be omitted theoretically (WaitSecs just
            % returns immediately if there is no time to wait), but by keeping
            % it in we avoid calling PsychToolbox unnecessarily (if all your
            % timings are integers you may not need it at all)
            if abstime > ch
                % need to wait in second units
                stime = WaitSecs('UntilTime',abstime*self.tr);
                % and convert back for the update
                update(self,stime/self.tr);
            end
        end

        function scan = waitpulse(self,npulse)
        % wait for npulse triggers, return the pulse number of the last.
        % scan = waitpulse(self,npulse)
            for n = 1:npulse
                [~,scan] = self.scanobj(1,Inf);
                update(self,scan);
            end
            % nb this field is set implicitly by update, so if npulse<1 we just
            % get the current estimated time
            scan = self.current;
        end
    end
end
