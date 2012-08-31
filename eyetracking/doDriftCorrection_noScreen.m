% Calibration routine for SMI IViewX eyetracker and Psychtoolbox,
% using the serial port for communication. This function carries out
% a one-point drift correction.
%
% This function is quicker and easier than the vanilla doDriftCorrection,
% because it makes some assumptions:
% a) The drift correction point will be the centre of the screen - this
% 	is always true if you've used calibrateEyeTracker.m
% b) When calling this function you are ALREADY presenting a fixation cross
% 	at the EXACT centre of the screen
%
% If your experiment meets these assumptions, you can use this function to
% quickly carry out a drift correction without needing PsychToolbox.
% (although the keyboard functionality does require PsychToolbox to be
% installed - sorry)
% The point can either be accepted at some fixed interval from calling
% function, or by a specified response key (keyboard OR buttonbox).
% Syntax:
% success = doDriftCorrection_noScreen(ET_serial,[respwait],[respkey],[esckey])
% Inputs (all except ET_serial are optional):
% ET_serial - Opened serial port object for scanner.
% respwait - (inf) Time to wait before automatically accepting point.
% respkey - (spacebar/leftmost button) Key to use for manual acceptance.
% esckey - (esc) Key to cancel drift correction.
% 		Use KbName('UnifyKeyNames') to get names for other keys
% ScanObj - ActiveX object for scanner. If supplied, we interpret acceptkey
% 	as a code for a buttonbox key, and look for responses there. If you are
% 	using this in MRI but do NOT want to relinquish control to the subject,
% 	don't input this, or input an empty/NaN variable
% 16/4/2010 J Carlin
function ready = doDriftCorrection_noScreen(ET_serial,respwait,acceptkey,esckey,ScanObj)

% If no serial object entered, crash out
if ~exist('ET_serial','var') || isempty(ET_serial)
    error('ET_serial must be defined! See calibrateEyeTracker')
end

% By default, calls time out in 10 SECONDS.
% This is clearly unacceptably slow for our
% purposes. Now 100 ms.
set(ET_serial,'timeout',.1);
% The downside is that Matlab spits out a lot of
% warnings. Let's disable these...
wstate=warning('off','MATLAB:serial:fgetl:unsuccessfulRead');

KbName('UnifyKeyNames');

% Fill in defaults as needed
if ~exist('respwait','var') || isempty(respwait)
	respwait = Inf;
end
% Figure out if we need button box logging
if exist('ScanObj','var') && ~isempty(ScanObj) % && ~isnan(ScanObj)
	bbresps = true;
else
	bbresps = false;
end
if (~exist('acceptkey','var') || isempty(acceptkey)) && ~bbresps
	acceptkey = KbName('space');
end
if (~exist('acceptkey','var') || isempty(acceptkey)) && bbresps
	acceptkey = 28; % leftmost
end
if ~exist('esckey','var') || isempty(esckey)
	esckey = KbName('escape');
end

% Add a message in the log
fprintf(ET_serial,sprintf('ET_REM Drift_Correction'));
% Start drift correction
fprintf(ET_serial,sprintf('ET_RCL'));
ready = 0;
ntries = 0;
rc = 0;
t_start = GetSecs;
while (GetSecs < t_start + respwait) && ~ready
    % Check for manual attempts to move things along
	acc = 0;
	[keyisdown, secs, keyCode] = KbCheck;
	k = NaN;
    if keyisdown
        k = find(keyCode);
        k = k(1);
    end
	if bbresps
		keyCode = bitand(30,invoke(ScanObj,'GetResponse'));
		if keyCode == acceptkey
			acc = 1;
        end
	else
		if keyisdown
			% Force acceptance of current point
			if k == acceptkey
				acc = 1;
                while KbCheck
                    WaitSecs(.1);
                end
            end
		end
	end
	if acc
		fprintf(ET_serial,'ET_ACC');
	end

	% Need separate check for escape key
	if k == esckey
		fprintf('Drift correction attempt aborted!\n')
		fprintf(ET_serial,'ET_BRK');
		return
	end

	% Check if the eye tracker has something to say
    response = fgetl(ET_serial);
    
	% What might the eye tracker have to say?
	if ~isempty(response)
		% Split by spaces
		command_etc = strread(regexprep(response,' ',' '),'%s');
		command = command_etc{1};

		%%% What we do next depends on the command we got:
		% Since this is the fast and loose version, we ignore
		% everything the eye tracker tells us, unless it tells us
		% we're done
        if strcmp(command,'ET_FIN')
            ready = 1;
        % Various commands we don't care about
        elseif strcmp(command,'ET_REC') || ...
                strcmp(command,'ET_CLR') || ...
                strcmp(command,'ET_PNT') || ...
                strcmp(command,'ET_CHG') || ...
                strcmp(command,'ET_CAL') || ...
                strcmp(command,'ET_CSZ') || ...
                strcmp(command,'ET_ACC') || ...
                strcmp(command,'ET_VLS') || ...
                strcmp(command,'ET_CPA') || ...
                strcmp(command,'ET_LEV')
            continue

		% Catch all
		else
			fprintf(sprintf(['Drift correction failed - received unrecognised '...
				'input: %s\n'],response));
            fprintf(ET_serial,'ET_BRK');
			break % DEBUG
		end % Resp interpretation
	end % Resp check
end % While

% Return warning state to whatever it started as
warning(wstate.state,wstate.identifier);
