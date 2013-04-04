% Null object with dummy invoke method to enable standard scannersync calls
% when no scanner is present. Ignores all invoke commands except
% CheckPulseSyncronyForTime (which waits but does nothing) and GetResponse
% (which returns 0). This is only really useful for easily swapping out
% ScannerSync specific code.
classdef ScanObjNull < handle
    properties
        tr = [];
        firstscantime = [];
    end

    methods
        function s = ScanObjNull;
            %fprintf('WARNING: null scanobj - NO SCANNER SYNC\n')
        end

        function varargout = invoke(self,varargin);
            switch varargin{1}
                case 'CheckPulseSynchronyForTime'
                    WaitSecs(varargin{2}/1000);
                case {'GetResponse','Initialize'}
                    varargout{1} = 0;
                case 'StartExperiment'
                    self.firstscantime = GetSecs * 1000;
                    self.tr = varargin{2};
                    varargout{1} = 0;
                case 'GetMeasuredTR'
                    varargout{1} = self.tr;
                case 'GetLastPulseNum'
                    varargout{1} = floor(...
                        (GetSecs*1000-self.firstscantime)/ self.tr);
            end
        end
    end
end
