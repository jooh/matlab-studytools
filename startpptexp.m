% Open a psychtoolbox screen, return some basic parameters in a struct
% location: 'pc' or 'scanner'
% windowed: 0 for fullscreen, 1 for window (default 0)
% conf = startpptexp(location,windowed)
function conf = startpptexp(location,windowed)

if ieNotDefined('windowed')
    windowed = 0;
end

% ----- GENERAL CONFIGS ------ %
display('Configuring experiment...')

% Keyboard
KbName('UnifyKeyNames');
conf.spacebar = KbName('space');
conf.esc = KbName('escape');

% Location specific display settings, Keithley config
switch lower(location)
	case 'pc'
		display('Running in PC mode')

		% A bit of trickery to ensure that if multi display,
		% the screen is 1, but if single display, the screen
		% is 0.
		screens = Screen('Screens');
		conf.whichScreen=screens(ceil(length(screens)/2));

		conf.ScanObj = NaN; % Dummy variable

		% Stimulus sizing - assume 50 cm (headrest in facelab)
		conf.totdist = 500;
		conf.screenwidth = 380;

        conf.respkeys = KbName({'v','b','n','m'});

        conf.logfun = @logrespkeyboard;

	case 'scanner'
		display('Running in Scanner mode')

		% Screen
		conf.whichScreen=0;
		VTOTAL=806;
		Screen('Preference','VBLEndlineOverride',VTOTAL);
		% Transplanted these, unsure if needed
		clear conf.ScanObj;
		warning('off','MATLAB:dispatcher:InexactMatch')

		% Keithley config
		conf.TR = 2000;
		conf.dummies = 5;
		conf.ScanObj = actxserver('MRISync.ScannerSync');
		Err = invoke(conf.ScanObj,'Initialize','');
		if Err ~= 0,
			Screen('CloseAll');
			error(sprintf('Keithley Error Code: %d',Err));
		end
		invoke(conf.ScanObj,'SetTimeout',double(20000)); % 20 s
		invoke(conf.ScanObj,'SetMSPerSample',2);

		% Stimulus sizing
		conf.totdist = 823+90; % distance to screen in mm
		conf.screenwidth = 268;

        conf.respkeys = [28 26 24 22];

        conf.logfun = @logrespbuttonbox;
end


%% PPT Setups
resolution = [1024 768];
if windowed
	re = [20 20 resolution];
	% Don't change resolution
	conf.oldres = Screen('Resolution',conf.whichScreen);
	% Just open in window
	[conf.window,conf.rect] = Screen(conf.whichScreen,'OpenWindow',[],re);
else
	conf.oldres = Screen('Resolution',conf.whichScreen,resolution(1),resolution(2));
	%% PPT setups
	[conf.window, conf.rect] = Screen(conf.whichScreen, 'OpenWindow');
end

conf.px2deg = (2 * atan(conf.screenwidth/2/conf.totdist) * (180/pi)) / ...
    resolution(1);
% And the reciprocal
conf.deg2px = conf.px2deg^-1;

% Alpha blending!
Screen('BlendFunction',conf.window,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

% Priority mode
Priority(1); % 0 normal, 2 will lock everything non-matlab, including keyboard

% Finds the absolute pixel values for white and black, and define gray as
% somewhere in the middle
conf.white = WhiteIndex(conf.window); % pixel value for white
conf.black = BlackIndex(conf.window); % pixel value for black
conf.grey = ceil((conf.white+conf.black)/2); % ceil to avoid weirdness
% when going from double to uint8

% Get the centre of the screen in pixels
conf.xcenter=conf.rect(3)/2;
conf.ycenter=conf.rect(4)/2;

% Text wrap (in characters)
conf.txtwrap = 50;

Screen('TextFont',conf.window, 'Tahoma');
Screen('TextSize',conf.window, 14);
Screen('TextStyle', conf.window, 0);
conf.vspacing = 1.5;

% Timing precision in s
conf.prec = 0.0001;
conf.tcatchup = 0.05;

% Fill the screen with grey
Screen(conf.window, 'FillRect', conf.grey);
Screen(conf.window, 'Flip');

HideCursor;
