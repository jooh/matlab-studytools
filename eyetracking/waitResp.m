% Wait for an assigned keyboard press. Also kills the run if escape is detected.
function waitResp(respkey,esckey)

r = 0;
while r == 0
	[keyisdown, secs, keyCode] = KbCheck;
	if keyisdown
		k = find(keyCode);
		k = k(1);
		if k == respkey
			WaitSecs(.2);
			return
		elseif k == esckey
			Screen('CloseAll')
			error('ESC KEY DETECTED - experiment aborted')
			return
		end
	end
end
