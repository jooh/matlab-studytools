% Run through calibration and validation with feedback for accepting
% and rejecting.
% success = fullCalibrationRoutine(window,ET_serial,varargin);
function success = fullCalibrationRoutine(window,ET_serial,varargin)

% Screen settings
sc = Screen('Resolution',window);
schw = [sc.width sc.height];
KbName('UnifyKeyNames');


getArgs(varargin,...
	{'npoints',13,...
	'calibarea',schw,... % Full screen size
	'bgcolour',[128 128 128],...
	'targcolour',[0 0 0],...
	'targsize',20, ...
	'acceptkey',KbName('space'), ...
	'quitkey',KbName('escape'), ...
    'skipkey',KbName('s'),...
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
success = 0;
response = waitRespAlts([acceptkey,skipkey]);
if response==2
    return
end
% to release key
WaitSecs(.2);
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
