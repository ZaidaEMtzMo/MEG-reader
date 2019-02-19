% Elis_PIP
% The script is designed to use PsychToolBox and PsychPortAudio to present
% audio stimulus (.wav files).
% Modification of Elizabeth Bock's 2013 script by JC

%% DEFINE PARAMETERS FOR EXPERIMENT
clear mex
ISI = 0.650;
pulseLength = 0.002;


freq = 1000;
duration = 0.5;
sampleFreq = 44100;
dt = 1/sampleFreq;
t = [0:dt:duration];
s=sin(2*pi*freq*t);
ss = [s;s]; 

isDebug = 1; % this will be 1 for debug and 0 on the stim PC

%% INITIALIZE THE LOW_LATENCY PARALLEL PORT DRIVER
if ~isDebug
    ioObj=io64;%create a parallel port handle
    status=io64(ioObj);%if this returns '0' the port driver is loaded & ready 
    address=hex2dec('D010');%address of LPT1 in hex
    io64(ioObj,address,0);
end

%% Initialize Audio Device

% Initialize driver, request low-latency preinit:
InitializePsychSound(1);
% Requested output frequency, may need adaptation on some audio-hw:
deviceid = [];
mode = [];
reqlatencyclass = 2;
freq = 44100;       % Must set this. 96khz, 48khz, 44.1khz.
nChannels = 2;

% Open audio device for low-latency output:
%pahandle = PsychPortAudio('Open', deviceid, [], reqlatencyclass, freq, 2, buffersize, suggestedLatencySecs);
pahandle = PsychPortAudio('Open', deviceid, mode, reqlatencyclass, freq, nChannels);
% Fill buffer with data:
PsychPortAudio('FillBuffer', pahandle, ss);

% Perform one warmup trial, to get the sound hardware fully up and running,
% performing whatever lazy initialization only happens at real first use.
% This "useless" warmup will allow for lower latency for start of playback
% during actual use of the audio driver in the real trials:
PsychPortAudio('Start', pahandle, 1, 0, 1);
PsychPortAudio('Stop', pahandle, 1);

%% Initialize Visual Screen
[window, screenRect]=Screen('OpenWindow',0, [0 0 0]); %, [200 200 800 800]);%open a window for stimulus display
[ ifi nvalid stddev ]= Screen('GetFlipInterval', window, 100, 0.00005, 20);


%% Define stimulus (.wav files)
pip = 'TOTALSparsedTonesStimuli_complete_run4.wav';
ttl = 'TOTALSparsedTonesStimuli_MEG_TTL_run4.wav';
% load the sound file
sound1 = audioread(pip);
sound2 = audioread(ttl);
sound = [sound1 sound2]';
PsychPortAudio('FillBuffer', pahandle, sound);
        
%% Start trials
%  Allow the subject to start when ready
DrawFormattedText(window, 'Press a key to begin','center','center',255*[1 1 1]); % black screen, white crosshair
[endON StimulusOnsetTime FlipTimestamp Missed Beampos] = Screen(window, 'Flip');
KbWait;

% place a crosshair on the screen
DrawFormattedText(window, '+','center','center',255*[1 1 1]); % black screen, white crosshair
Screen(window, 'Flip');

try 
    Priority(2);%raise priority for stimulus presentation
    % init some mex functions
    starttime = WaitSecs(.001);
    
        
        
        % play the sound
        PsychPortAudio('Start', pahandle, 1, 0, 1);
%         io64(ioObj,address,1);
%         WaitSecs(0.001);
%         io64(ioObj,address,0);
        % wait for the sound to finish
        WaitSecs(size(sound,2)/freq);
        
        % wait ISI before playing next stim
        WaitSecs(ISI);
catch ME
    Priority(0);%drop priority back to normal
    disp(ME)
    Screen('CloseAll');
    clear mex;
    return;
end

Priority(0);%drop priority back to normal
DrawFormattedText(window, 'Done','center','center',255*[1 1 1]); % black screen, white crosshair
Screen(window, 'Flip');
KbWait;
Screen('CloseAll');
clear mex;
