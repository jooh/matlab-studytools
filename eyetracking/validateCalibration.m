% Calibration routine for SMI IViewX eyetracker and Psychtoolbox,
% using the serial port for communication. This function validates
% a previous calibration. It's generally a good idea to pass the
% exact same params struct here as you provided to calibrateEyeTracker.
% NB, MeanDevXY is in deg visual angle, so is completely dependent on
% you appropriately configuring IViewX settings to match your setup. The
% other values are in pixels.
% Currently only reports validation parameters for the left eye if tracking
% binocular. As near as I can tell, this information is never transmitted,
% so little can be done at this end.
% Syntax:
% [success,RMSdev,RMSdevdist,MeanDevXY] = validateCalibration(window,ET_serial,ET_params)
% Inputs (all params are optional):
% window - Psychtoolbox screen handle
% ET_serial - Opened serial port object for scanner.
% ET_params - struct with eye tracking parameters. All are optional.
%   npoints - (13) calibration points. DO NOT change between calib and
%       validation.
% 	bgcolour - ([128 128 128]) background colour (RGB)
% 	targcolour - ([255 255 255]) target colour (RGB)
% 	targsize - (20) target height/width in pixels
% 	acceptkey - ([spacebar]) key for forcing point acceptance
% 	quitkey - ([escapekey]) key for aborting calibration
% 		Use KbName('UnifyKeyNames') to get names for other keys
% 13/4/2010 J Carlin
function [ready,RMSdev, RMSdevdist, MeanDevXY] = validateCalibration(window,ET_serial,ET_params)

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

% If you don't know what you want, we will fill this in with
% defaults.
if ~exist('ET_params','var')
	ET_params = struct;
end

% Screen settings
sc = Screen('Resolution',window);
schw = [sc.width sc.height];

KbName('UnifyKeyNames');

% These are the default settings
default_params = struct(...
	'bgcolour',[128 128 128],...
	'targcolour',[255 255 255],...
	'targsize',20, ...
	'npoints',13, ...
	'acceptkey',KbName('space'), ...
	'quitkey',KbName('escape') ...
	);

% Now put in defaults for whatever was left undefined
fns = fieldnames(default_params);
for fn = fns'
	if ~isfield(ET_params,fn{1})
		ET_params.(fn{1}) = default_params.(fn{1});
	end
end

% Draw background
Screen(window,'FillRect',ET_params.bgcolour);

% Display settings for targets
% Make a cross - studiously avoiding alpha blending here to
% maximise compatibility (but you will need to im processing toolbox)
% Settings
cross_orgsize = 100;
cross_linewidth = .05;
% Build cross
cs = round((cross_orgsize / 2) - (cross_orgsize * cross_linewidth));
ce = round((cross_orgsize / 2) + (cross_orgsize * cross_linewidth));
cr = zeros(cross_orgsize);
cr(:,cs:ce) = 1;
cr(cs:ce,:) = 1;
% Resize - Since square, no point to bicubic interpolation
cr_rs = imresize(cr,[ET_params.targsize ET_params.targsize],'nearest');
% Make target uint8, colour
rgb_t = ET_params.targcolour;
cros = uint8(cat(3,cr_rs*rgb_t(1),cr_rs*rgb_t(2),cr_rs*rgb_t(3)));
% Make an appropriately-coloured background
rgb = ET_params.bgcolour;
bg = uint8(ones(ET_params.targsize));
bg_rgb =cat(3,bg*rgb(1),bg*rgb(2),bg*rgb(3));
% Put background and target together
target = bg_rgb;
target(find(cros)) = cros(find(cros));
% Draw texture
targetbuf = Screen('MakeTexture',window,target);
% Set up basic rect
targetrect = [0 0 size(target,1) size(target,2)];

% Start validation
fprintf(ET_serial,sprintf('ET_VLS'));
ready = 0;
readyonce = 0; % Extra check to catch second eye in bino mode
ntries = 0;
points = zeros(ET_params.npoints,2);

% Initialise output vars for graceful errors
RMSdev = [];
RMSdevdist = [];
MeanDevXY = [];

rc = 0;
while ~ready
	ntries = ntries+1;

	% If no connection with serial, return anyway
	if ntries > 500
		fprintf('Serial port communication failure!\n')
		break
	end

	% Check for manual attempts to move things along
	[keyisdown, secs, keyCode] = KbCheck;
	if keyisdown
		k = find(keyCode);
		k = k(1);
		% Force acceptance of current point
		if k == ET_params.acceptkey
			fprintf('Accepting point...\n')
            %WaitSecs(.2); % Time to let go of key...
            % Now stop execution until the key is released
            while KbCheck
                WaitSecs(.01);
            end
            fprintf(ET_serial,'ET_ACC');
		% Give up on calibration
		elseif k == ET_params.quitkey
			fprintf('Calibration attempt aborted!\n')
			fprintf(ET_serial,'ET_BRK');
			break
		end
    end

    % Ensure a second run through after receiving the first
    % ET_VLS return, so that we catch the second eye too.
    if readyonce
        ready = 1;
    end

	% Check if the eye tracker has something to say
    response = fgetl(ET_serial);
    
	% What might the eye tracker have to say?
	if ~isempty(response)
		% Save each response - mainly for debugging
		rc = rc+1;
        resplog{rc} = response;
		% Split by spaces
		command_etc = strread(regexprep(response,' ',' '),'%s');
		command = command_etc{1};

		%%% What we do next depends on the command we got:
		% Calibration point change
        if strcmp(command,'ET_CHG')
            % Coordinates for point
            xy = points(str2num(command_etc{2}),:);
			% Rect for point
			pointrect = CenterRectOnPoint(targetrect,xy(1),xy(2));
			% Draw into rect
			Screen('DrawTexture',window,targetbuf,[],pointrect);
            Screen(window,'Flip');
            % Reset timeout counter
            ntries = 0;

            % Calibation point definition
        elseif strcmp(command,'ET_PNT')
            points(str2num(command_etc{2}),:) = ...
				[str2num(command_etc{3}) str2num(command_etc{4})];

		% Screen size verification
		%elseif strcmp(command,'ET_CSZ')
		% Actually, we don't want calibration area
			% to match screen size.
			% So arguments are X and Y size
			%sc = Screen('Resolution',window);
			%if str2num(command_etc{2}) ~= sc.width
				%fprintf('Calibration failed - Screen width mismatch\n')
				%break
			%elseif str2num(command_etc{3}) ~= sc.height
				%fprintf('Calibration failed - Screen height mismatch\n')
				%break
			%end
       
        % Validation finished
        % The twist here is that ET_VLS returns twice if
        % in binocular mode... So need to go through a last
        % check after finishing this.
        elseif strcmp(command,'ET_VLS')
            % Command_etc should now contain various numbers
            values = str2num(char(command_etc(3:5)))';
            % SMI for some reason insists on including a degree
            % symbol for the last 2, which complicates things...
            values(end+1) = str2num(command_etc{6}(1:end-1));
            values(end+1) = str2num(command_etc{7}(1:end-1));
            
            if ~readyonce
                RMSdev = values(1:2);
                RMSdevdist = values(3);
                MeanDevXY = values(4:5);
            else % Right eye
                RMSdev(2,:) = values(1:2);
                RMSdevdist(2,:) = values(3);
                MeanDevXY(2,:) = values(4:5);
            end            
            readyonce = 1;
            
        
        % Various commands we don't care about
        elseif strcmp(command,'ET_REC') || ...
                strcmp(command,'ET_CLR') || ...
                strcmp(command,'ET_CAL') || ...
                strcmp(command,'ET_CSZ') || ...
                strcmp(command,'ET_ACC') || ...
                strcmp(command,'ET_CPA') || ...
                strcmp(command,'ET_FIN') || ...
                strcmp(command,'ET_LEV')
            continue

		% Catch all
		else
			fprintf(sprintf(['Validation failed - received unrecognised '...
				'input: %s\n'],response));
            fprintf(ET_serial,'ET_BRK');
			break % DEBUG
		end % Resp interpretation
	end % Resp check
end % While

% Clear the target texture from memory
Screen('Close',targetbuf);
% Return warning state to whatever it started as
warning(wstate.state,wstate.identifier);
