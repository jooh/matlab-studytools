% synchronise with triggers and record button presses from CBU National
% Instruments scanner interface.
%
% We support a crude emulation mode (a pretend trigger is sent every tr seconds,
% pretend buttonbox presses are logged on keyboard keys [v,b,n,m]), which is
% triggered automatically whenever the NI box cannot be detected. 
%
% USAGE:
% % initialise a scansync session
% tr = 2; % TR in s
% scansync('reset',tr);
% % wait for the first trigger
% scansync(1,Inf);
%
% % wait for 4s and return early if the first button is pressed
% scansync(2,GetSecs+4); % absolute time stamps
%
% % wait 2s no matter what (but keep track of triggers and button presses
% scansync([],GetSecs+2);
%
% % wait for the next pulse and return its time stamp and estimated number
% [triggertime,triggernum] = scansync(1,Inf);
%
% % advanced use - inspect the scansync session by assigning the third return
% variable. you can use this e.g. to pull out logged responses from the example
% above global daqstate
% lastpulse = daqstate.lastresp(1); % time stamp for last recording trigger,
% which may have occurred during the 2s interval in the example above.
%
% 2017-04-13 J Carlin, MRC CBU.
%
% [resptime,respnumber,daqstate] = scansync(ind,waituntil)
function [resptime,respnumber,daqret] = scansync(ind,waituntil)

persistent daqstate

if strcmp(lower(ind),'reset')
    % special case to handle re-initialising sync e.g. on run transitions
    if ~isempty(daqstate)
        daqstate.hand.release();
    end
    daqstate = [];
    ind = [];
end

if ~exist('waituntil','var') || isempty(waituntil) || isnan(waituntil)
    waituntil = 0;
end

if isempty(daqstate)
    % special initialisation mode
    tr = waituntil;
    % ordinarily infinite wait durations are fine, but not if you're
    % initialising a new session
    assert(~isinf(tr),'tr must be finite, numeric');
    if isscalar(tr)
        % usual mode - don't really want to estimate pulses for button presses
        % (channels 2:5)
        tr = [tr, NaN(1,4)];
    end
    % check for DAQ
    hasdaq = false;
    try
        D = daq.getDevices;
        hasdaq = D.isvalid && any(strcmp({D.Vendor.ID},'ni')) && ...
                D.Vendor.isvalid && D.Vendor.IsOperational;
    catch err
        if ~strcmp(err.identifier,'MATLAB:undefinedVarOrClass')
            rethrow(err);
        end
    end
    if hasdaq
        fprintf('initialising new scanner card connection\n');
        warning off daq:Session:onDemandOnlyChannelsAdded
        daqstate.hand = daq.createSession('ni');
        daqstate.tr = tr;
        % Add channels for scanner pulse
        daqstate.hand.addDigitalChannel('Dev1', 'port0/line0', 'InputOnly');
        % Add channels for button 1-4
        daqstate.hand.addDigitalChannel('Dev1', 'port0/line1', 'InputOnly');
        daqstate.hand.addDigitalChannel('Dev1', 'port0/line2', 'InputOnly');
        daqstate.hand.addDigitalChannel('Dev1', 'port0/line3', 'InputOnly');
        daqstate.hand.addDigitalChannel('Dev1', 'port0/line4', 'InputOnly');
        daqstate.emulate = false;
    else
        fprintf(['NI CARD NOT AVAILABLE - entering emulation mode with tr=' ...
            mat2str(tr) '\n']);
        fprintf('if you see this message in the scanner, DO NOT PROCEED\n')
        % struct with a function handle in place of inputSingleScan
        daqstate = daqemulator(tr);
    end
    daqstate.firstresp = NaN([1,5]);
    daqstate.lastresp = NaN([1,5]);
    daqstate.thisresp = NaN([1,5]);
    daqstate.nrecorded = zeros(1,5);
    % we count pulses if they are >.02s apart, and button presses if they are
    % more than .2s apart
    daqstate.pulsedur = [.006,ones(1,4)*.2];
end

% always call once (so we get an update even if waituntil==0)
daqstate = checkdaq(daqstate);
while (GetSecs < waituntil) && all(isnan(daqstate.thisresp(ind)))
    daqstate = checkdaq(daqstate);
    % avoid choking the CPU, but don't wait so long that we might miss a pulse
    WaitSecs(min(daqstate.pulsedur)/3);
end

% so now this will be NaN if no responses happened, or otherwise not nan. Note
% that if you entered multiple indices we will return when the FIRST of these is
% true. So resptime will practically always only have a single non-nan entry
% (barring simultaneous key presses), and to the extent that you have multiple
% entries, they'll all show the same time.
resptime = daqstate.thisresp(ind);

% time to estimate the current pulse. mainly useful for scanner triggers
% (channel 1), but we may as well estimate it across the board
if nargout > 1
    respnumber = floor((GetSecs - daqstate.firstresp) ./ daqstate.tr);
    respnumber = respnumber(ind);
end

if nargout > 2
    daqret = daqstate;
end

function daqstate = checkdaq(daqstate)
timenow = GetSecs;
% call the DAQ - trigger, buttons 1:4
daqflags = ~daqstate.hand.inputSingleScan();

% wipe whatever we had in thisresp from the last call
daqstate.thisresp = NaN([1,5]);

% if any of the responses are new, keep track of when this occurred
newresp = isnan(daqstate.firstresp);
daqstate.firstresp(daqflags & newresp) = timenow;
daqstate.lastresp(daqflags & newresp) = timenow;
daqstate.thisresp(daqflags & newresp) = timenow;

% were any responses sufficiently far past a previous response to count as a
% discrete event?
valid = daqflags & timenow>((daqstate.lastresp+daqstate.pulsedur));
if any(valid)
    % if so, we need to update lastresp and thisresp
    daqstate.lastresp(valid) = timenow;
    daqstate.thisresp(valid) = timenow;
    daqstate.nrecorded(valid) = daqstate.nrecorded(valid)+1;
end

function daqstate = daqemulator(tr)

daqstate.tr = tr;
daqstate.emulate = true;
% fake method
daqstate.hand.inputSingleScan = @emulatecard;
% dummy 
daqstate.hand.release = @(x)fprintf('reset scansync session.\n');
daqstate.emulatekeys = [KbName('v'),KbName('b'),KbName('n'),KbName('m')];
daqstate.firstcall = true;

function flags = emulatecard()

% pull in the current daqstate
daqstate = evalin('caller','daqstate');

% NB inverted coding on NI cards
flags = true(1,5);
if daqstate.firstcall
    % make sure we return nothing the very first time we call (on init). This is
    % hacky but important to avoid starting the pulse emulator too early.
    daqstate.firstcall = false;
    % write it back to the caller
    assignin('caller','daqstate',daqstate);
    return
end

if isnan(daqstate.firstresp(1))
    % record a pulse on first call to start the emulated pulse sequence
    flags(1) = false;
else
    % use the start time to work out whether we should be sending a pulse
    timenow = GetSecs;
    if rem(timenow-daqstate.firstresp(1),daqstate.tr(1))<daqstate.pulsedur(1)
        flags(1) = false;
    end
end

% check for buttons
[keyisdown,rawtime,keyCode] = KbCheck;
if keyisdown
    % flip any keys that match the emulator keys
    respk = find(keyCode);
    [~,ind] = intersect(daqstate.emulatekeys,respk);
    % need to offset by 1 to stay clear of pulse channel
    flags(ind+1) = false;
end
