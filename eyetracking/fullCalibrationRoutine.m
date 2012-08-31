% Run through calibration and validation with feedback for accepting
% and rejecting.
% success = fullCalibrationRoutine(window,ET_serial,varargin);
function success = fullCalibrationRoutine(window,ET_serial,varargin)

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

KbName('UnifyKeyNames');
txtwrap = 50;
vspacing = 1.5;
ET_params = struct;
respy = KbName('y');
respn = KbName('n');

Screen(window,'FillRect',bgcolour);
DrawFormattedText(window,['Follow the target as it moves around '...
    'the screen.'],'center','center',targcolour,txtwrap,0,0, ...
    vspacing);
Screen(window,'Flip');
waitResp(acceptkey,quitkey);
ready = 0;
while ~ready
	success = calibrateEyeTracker(window,ET_serial,varargin{:});
	if success
		validateCalibration(window,ET_serial,varargin{:});
	end
	DrawFormattedText(window,'Calibration ok?','center','center',...
		targcolour,txtwrap,0,0,vspacing);
	Screen(window,'Flip');
	response = waitRespAlts([respy respn]);
	if response == 1
		ready = 1;
		success = 1;
	else
		DrawFormattedText(window,'Try again?','center','center',...
			targcolour,txtwrap,0,0,vspacing);
		Screen(window,'Flip');
		resp2 = waitRespAlts([respy respn]);
		if resp2 == 2
			ready = 1;
			success = 0;
		end
	end
end
