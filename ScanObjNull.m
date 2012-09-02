% Null object with dummy invoke method to enable standard scannersync calls
% when no scanner is present. Ignores all invoke commands except
% CheckPulseSyncronyForTime (which waits but does nothing) and GetResponse
% (which returns 0). This is only really useful for easily swapping out
% ScannerSync specific code.
classdef ScanObjNull
    methods
        function s = ScanObjNull;
            fprintf('WARNING: null scanobj - NO SCANNER SYNC\n')
        end

        function varargout = invoke(self,varargin);
            switch varargin{1}
                case 'CheckPulseSynchronyForTime'
                    WaitSecs(varargin{2}/1000);
                case 'GetResponse'
                    varargout{1} = 0;
            end
        end
    end
end
