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
% [success,RMSdev,RMSdevdist,MeanDevXY] = validateCalibration(window,ET_serial,varargin)
% Inputs:
% window - Psychtoolbox screen handle
% ET_serial - Opened serial port object for scanner.
%
% Named, optional inputs:
%   npoints - (13) calibration points. DO NOT change between calib and
%       validation.
% 	bgcolour - ([128 128 128]) background colour (RGB)
% 	targcolour - ([255 255 255]) target colour (RGB)
% 	targsize - (20) target height/width in pixels
% 	acceptkey - ([spacebar]) key for forcing point acceptance
% 	quitkey - ([escapekey]) key for aborting calibration
% 		Use KbName('UnifyKeyNames') to get names for other keys
% 13/4/2010 J Carlin
function [ready,RMSdev, RMSdevdist, MeanDevXY] = validateCalibration(window,ET_serial,varargin)

% Screen settings
sc = Screen('Resolution',window);
schw = [sc.width sc.height];

KbName('UnifyKeyNames');

% These are the default settings - some of these are unused but convenient
% to have same as in calibrateEyeTracker so the same args can be passed to
% each
getArgs(varargin,...
	{'npoints',13,...
	'calibarea',schw,... % Full screen size
	'bgcolour',[128 128 128],...
	'targcolour',[255 255 255],...
	'targsize',20, ...
	'acceptkey',KbName('space'), ...
	'quitkey',KbName('escape'), ...
    'waitforvalid',1,...
    'randompointorder',0,...
    'autoaccept',1,...
    'checklevel',2});

% Draw background
Screen(window,'FillRect',bgcolour);

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
cr_rs = imresize(cr,[targsize targsize],'nearest');
% Make target uint8, colour
rgb_t = targcolour;
cros = uint8(cat(3,cr_rs*rgb_t(1),cr_rs*rgb_t(2),cr_rs*rgb_t(3)));
% Make an appropriately-coloured background
rgb = bgcolour;
bg = uint8(ones(targsize));
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
points = zeros(npoints,2);

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
		if k == acceptkey
			fprintf('Accepting point...\n')
            %WaitSecs(.2); % Time to let go of key...
            % Now stop execution until the key is released
            while KbCheck
                WaitSecs(.01);
            end
            fprintf(ET_serial,'ET_ACC');
		% Give up on calibration
		elseif k == quitkey
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
