% Store timing information for a Study. Handle object, so the same
% instance is updated throughout the experiment to track timings. Use the
% ScantTiming sub-class for pulse sync.
classdef SecondTiming < Timing

    % Timing object for running events relative to Psychtoolbox clock
    % (ie GetSecs).
    methods
        function t = SecondTiming(varargin)
            t = t@Timing(varargin{:});
            t.units = 's';
        end

        function tim = begin(self)
        % start the clock
        % tim = begin();
            [tim, t.first] = deal(GetSecs);
            update(self);
        end

        function tim = check(self)
        % return the current clock time
        % tim = check()
            update(self,GetSecs);
            tim = self.current;
        end

        function waituntil(self,abstime)
        % wait until an absolute clock time. 
        % waituntil(abstime)
            % NB, we update not with the intended abstime but the actual return
            % time, which will be very slightly later
            update(self,WaitSecs('UntilTime',abstime));
        end

    end
end
