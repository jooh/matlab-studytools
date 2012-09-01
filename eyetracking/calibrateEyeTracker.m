% Calibration routine for SMI IViewX eyetracker and Psychtoolbox,
% using the serial port for communication.
% This function is fairly robust - if calibration fails for some
% reason it will quietly print out some warnings and return. If
% calibration failures are catastrophic for your experiment, you will
% need to check the output flag for success==1 in your own script.
% Syntax:
% [success,points] = calibrateEyeTracker(window,[ET_serial],[varargin])
% 
% INPUTS:
% window - Psychtoolbox screen handle
% ET_serial - Opened serial port object
%
% Named varargins (all optional):
% 	npoints - (13) number of calibration points
% 	calibarea - ([screenx screeny]) calibration area on screen
% 	bgcolour - ([128 128 128]) background colour (RGB)
% 	targcolour - ([255 255 255]) target colour (RGB)
% 	targsize - (20) target height/width in pixels
% 	acceptkey - ([spacebar]) key for forcing point acceptance
% 	quitkey - ([escapekey]) key for aborting calibration
% 		Use KbName('UnifyKeyNames') to get names for other keys
%   waitforvalid - (1) wait for valid data during calibration
%   randompointorder - (0) randomise point order during calibration
%   autoaccept - (1) Auto-accept points after some fixation dur.
%   checklevel - (2) Fussiness when accepting points (0-3). SMI recommends
%       2 for every-day use. Drop if subject is problematic.
% 13/4/2010 J Carlin, heavily indebted to Maarten van Caasteren's
% VB script for E-Prime
% 31/8/2012 update - refactored with better arguments through varargin

function [ready,points] = calibrateEyeTracker(window,ET_serial,varargin)

% If no serial object entered, try to set one up
%if ieNotDefined('ET_serial')
    %ET_serial = serial('COM1','BaudRate',9600,'Databits',8);
    %fopen(ET_serial);
%end

% Screen settings
sc = Screen('Resolution',window);
schw = [sc.width sc.height];
KbName('UnifyKeyNames');

% These are the default settings
getArgs(varargin,...
	{'npoints',13,...
	'calibarea',schw,... % Full screen size
	'bgcolour',[128 128 128],...
	'targcolour',[0 0 0],...
	'targsize',20, ...
	'acceptkey',KbName('space'), ...
	'quitkey',KbName('escape'), ...
    'waitforvalid',1,...
    'randompointorder',0,...
    'autoaccept',1,...
    'checklevel',2});

% Quick sanity check
assert(any(npoints==[2,5,9,13]),...
    'SMI eye trackers only support 2,5,9 or 13 point calibration')

% Start and stop calibration once. This somehow
% solves a lot of problems
fprintf(ET_serial,sprintf('ET_CAL %d',npoints));
fprintf(ET_serial,'ET_BRK');
% Wait for various crap to go through
w = 0;
while w == 0
    if isempty(fgetl(ET_serial))
        w = 1;
    end
end

% Draw background
Screen(window,'FillRect',bgcolour);

% Display settings for targets
% Make a cross - studiously avoiding alpha blending here to
% maximise compatibility (but you will need im processing toolbox)
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

% Various calibration settings
fprintf(ET_serial,sprintf('ET_CPA %d %d',0,waitforvalid));
fprintf(ET_serial,sprintf('ET_CPA %d %d',1,randompointorder));
fprintf(ET_serial,sprintf('ET_CPA %d %d',2,autoaccept));
fprintf(ET_serial,sprintf('ET_LEV %d',checklevel));

% Set calibration area (ie screen res)
fprintf(ET_serial,sprintf('ET_CSZ %d %d',schw(1),schw(2)));

% These are the default ET points for a 13 point calibration on
% a 1280x1024 screen. We can tweak this according to our needs...
standardpoints = [640 512;
    64 51;
    1216 51;
    64 973;
    1216 973;
    64 512;
    640 51;
    1216 512;
    640 973;
    352 282;
    928 282;
    352 743;
    928 743];

% Scale up/down to match calibration area
scaledpoints = standardpoints .* repmat(calibarea ...
    ./ [1280 1024],13,1);

% If the calibration area doesn't match the screen res,
% need to shift everything to centre
%shift = @(xy) round(xy + ([sc.width sc.height]/2) - (calibarea/2));

% Shift the calibration points to centre on the screen
shiftedpoints = round(scaledpoints + repmat(schw/2,13,1) ...
    - repmat(calibarea/2,13,1));

% Set to appropriate npoints
shiftedpoints = shiftedpoints(1:npoints,:);

% Send custom points to eye tracker
for p = 1:length(shiftedpoints)
    fprintf(ET_serial,sprintf('ET_PNT %d %d %d',p, ...
        shiftedpoints(p,1),shiftedpoints(p,2)));
end
% Start calibration
fprintf(ET_serial,sprintf('ET_CAL %d',npoints));

ready = 0;
ntries = 0;

% Point coordinates go here - just to validate
points = zeros(npoints,2);

rc = 0;
while ~ready
	ntries = ntries+1;

	% If no connection with serial, return anyway
	if ntries > 5000
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
        switch command
            case 'ET_CHG'
                % Coordinates for point
                xy = points(str2num(command_etc{2}),:);
                % Rect for point
                pointrect = CenterRectOnPoint(targetrect,xy(1),xy(2));
                % Draw into rect
                Screen('DrawTexture',window,targetbuf,[],pointrect);
                Screen(window,'Flip');
                % Reset timeout counter
                ntries = 0;
            case 'ET_PNT'
                % Calibation point definition
                points(str2num(command_etc{2}),:) = ...
                    [str2num(command_etc{3}) str2num(command_etc{4})];
            case 'ET_FIN'
                % Calibration finished
                ready = 1;
            case {'ET_REC','ET_CLR','ET_CAL','ET_CSZ','ET_ACC','ET_CPA',...
                    'ET_LEV'}
                % Various commands we don't care about
                continue
            otherwise
                % Catch all
                fprintf(...
                    'Calibration failed. Unrecognised input: %s\n',...
                    response);
                fprintf(ET_serial,'ET_BRK');
                break % DEBUG
		end % Resp interpretation
	end % Resp check
end % While

% Clear the target texture from memory
Screen('Close',targetbuf);
