% Null object with dummy invoke method to enable standard scannersync calls
% when no scanner is present.
classdef ScanObjNull
    methods
        function varargout = invoke(self,varargin);
            switch varargin{1}
                case 'CheckPulseSynchronyForTime'
                    WaitSecs(varargin{2}/1000);
                case 'GetResponse'
                    varargout{1} = NaN;
            end
        end
    end
end
