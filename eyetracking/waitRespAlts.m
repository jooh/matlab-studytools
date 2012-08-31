% Wait for one of a list of keyboard presses. Return the index of the alt.
% Also kills the run if escape is detected.
% response = waitRespAlts(keylist,[esckey],[waitdur])
function resp = waitRespAlts(keylist,esckey,waitdur)

KbName('UnifyKeyNames');

if ~exist('esckey','var') || isempty(esckey)
	esckey = KbName('escape');
end
if ~exist('waitdur','var') || isempty(waitdur)
	waitdur = Inf;
end

ts = GetSecs;
WaitSecs(.2); % Small delay to stop previous response carry-over
r = 0;
while r == 0 && GetSecs - ts < waitdur
	[keyisdown, secs, keyCode] = KbCheck;
	if keyisdown
		k = find(keyCode);
		k = k(1);
		hit = find(k==keylist);
		if ~isempty(hit)
			resp = hit;
			WaitSecs(.2);
			return
		elseif k == esckey
			error('ESC KEY DETECTED - experiment aborted')
		end
	end
end
