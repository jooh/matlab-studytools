classdef Timing < hgsetget & dynamicprops
    % Store timing information for a Study. Handle object, so the same
    % instance is updated throughout the experiment to track timings. This
    % is a master object - use inherited SecondTiming / ScanTiming for
    % instances.
    properties
        first = 0; % absolute time at beginning of runtrials
        current = [];% best current estimate of time
        previous = []; % former current
        units = ''; % string describing what sort of timings we work with
    end

    methods
        function t = Timing(varargin)
            if nargin==0
                return
            end
            sout = varargs2structfields(varargin,t);
            for fn = fieldnames(sout)'
                t.(fn{1}) = sout.(fn{1});
            end
        end

        function update(self,newtime)
            [self.previous,self.current] = deal(self.current,newtime);
        end
    end

    methods (Abstract)
        t = begin(self);
        t = check(self);
        waituntil(self,abstime)
    end
end
