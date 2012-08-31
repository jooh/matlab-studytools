% Run through calibration and validation with feedback for accepting
% and rejecting.
% success = fullCalibrationRoutine(ET_serial,conf,[window])
function success = fullCalibrationRoutine(ET_serial,conf,window)

% Small concession to those who have yet to see the brilliance
% of storing every little thing in a big struct
if exist('window','var') && ~isempty(window) && ~isnan(window)
	conf.window = window;
end
if ~exist('conf','var') || isempty(conf)
	conf = struct;
end

KbName('UnifyKeyNames');

% Let's make absolutely no assumptions about what inputs you've provided
confdef.white = WhiteIndex(conf.window);
confdef.txtwrap = 50;
confdef.vspacing = 1.5;
confdef.spacebar = KbName('space');
confdef.esc = KbName('escape');
confdef.ET_params = struct;
confdef.respy = KbName('y');
confdef.respn = KbName('n');
for fn = fieldnames(confdef)'
	if ~isfield(conf,fn{1})
		conf.(fn{1}) = confdef.(fn{1});
	end
end

DrawFormattedText(conf.window,['Follow the target as it moves around '...
    'the screen.'],'center','center',conf.white,conf.txtwrap,0,0, ...
    conf.vspacing);
Screen(conf.window,'Flip');
waitResp(conf.spacebar,conf.esc);
ready = 0;
while ~ready
	success = calibrateEyeTracker(conf.window,ET_serial,conf.ET_params);
	if success
		validateCalibration(conf.window,ET_serial,conf.ET_params);
	end
	DrawFormattedText(conf.window,'Calibration ok?','center','center',...
		conf.white,conf.txtwrap,0,0,conf.vspacing);
	Screen(conf.window,'Flip');
	response = waitRespAlts([conf.respy conf.respn]);
	if response == 1
		ready = 1;
		success = 1;
	else
		DrawFormattedText(conf.window,'Try again?','center','center',...
			conf.white,conf.txtwrap,0,0,conf.vspacing);
		Screen(conf.window,'Flip');
		resp2 = waitRespAlts([conf.respy conf.respn]);
		if resp2 == 2
			ready = 1;
			success = 0;
		end
	end
end
