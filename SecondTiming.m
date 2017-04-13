classdef SecondTiming < Timing
    % Timing object for running events relative to Psychtoolbox clock
    % (ie GetSecs).
    methods
        function t = SecondTiming(varargin)
            t = varargs2structfields(varargin,t);
            t.units = 's';
        end

        function tim = begin(self)
        % start the clock
        % tim = begin();
            [tim, t.first] = deal(GetSecs);
        end

        function tim = check(self)
        % return the current clock time
        % tim = check()
            self.previous = self.current;
            [self.current,tim] = deal(GetSecs);
        end

        function waituntil(self,abstime)
        % wait until an absolute clock time. 
        % waituntil(abstime)
            WaitSecs('UntilTime',abstime);
        end
    end
end
