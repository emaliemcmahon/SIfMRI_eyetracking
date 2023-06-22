function run_number = SIdyads(subjName, run_number, with_Eyelink)
% Presents the social interaction localizer task
% Inputs:
% subjName as an integer used when saving and loading the sequences
% runNum is an integer used when saving and loading the sequences
% design is either 1 or 2 and selects the order of video presentation.
% trigger is a binaray value whether the code should wait for a trigger
% from the scanner
% Written by Emalie McMahon June 22, 2023


if nargin < 1
    subjName = 77;
    run_number = [];
    with_Eyelink = 1;
end

% make output directories
curr = pwd;
topout = fullfile(curr, 'data', ['subj',sprintf('%03d', subjName)]);
matout = fullfile(topout, 'matfiles');
timingout = fullfile(topout, 'timingfiles');
runfiles = fullfile(topout,'runfiles');
edfout = fullfile(topout, 'edfs');

if ~exist(topout, 'dir')
    s=sprintf('Run files do not exist of subject %g. Make run files before continuing.', subjName);
    error(s);
end


if isempty(run_number)
    % If the run_number is not assigned, find the last run and
    % increment by 1.
    files = dir(fullfile(timingout, '*.csv'));
    if ~isempty(files)
        runs = [];
        for i=1:length(files)
            f = strsplit(files(i).name, '_');
            f = strsplit(f{1},'n');
            runs(i) = str2num(f{end});
        end
        run_number = max(runs) + 1;
    else
        run_number = 1;
    end
end

s=sprintf('Subject number is %g. Run number is %g. ', subjName, run_number);
fprintf('\n%s\n\n ',WrapString(s));


%% load video list
ftoread = dir(fullfile(runfiles,['run',sprintf('%03d', run_number),'*.csv']));
fid = fopen(fullfile(ftoread.folder,ftoread.name));
video_list = textscan(fid, '%s');
fclose(fid);
video_list = video_list{1};

%% Experiment variables
curr_date = datestr(datetime('now'), 'yyyymmddTHHMMSS');
async = 4;
preloadsecs = 3;
rate = 1;
sound = 0;
blocking = 1;
stimulus_length = 3;
TR = .5;
iti_length = TR;
n_response = 25;
n_real = size(video_list, 1);
n_extra_TRs = 0;
n_extra_TR_trials = 0;
ending_wait_time = 1;
start_wait_time = TR;

expected_duration = ((n_response + n_real) * (stimulus_length + iti_length)) + (n_extra_TRs * n_extra_TR_trials * TR) + ending_wait_time + start_wait_time;
fprintf('Expected duration: %g min \n\n', expected_duration / 60);
sca;


%% Make stimulus presentation table
%get filler videos
vid_inds = randperm(50);
temp = dir(fullfile('videos','crowd_videos_3000ms','*.mp4'));
response_videos = cell(5,1);
for i = 1:n_response
    response_videos{i} = temp(vid_inds(i)).name;
end

video_list = [video_list, num2cell(ones(n_real, 1)), num2cell(zeros(n_real, 1)), num2cell(zeros(n_real, 1)), num2cell(zeros(n_real, 1)), num2cell(zeros(n_real, 1));...
    response_videos, num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1)), num2cell(zeros(n_response, 1))];
video_table = cell2table(video_list);
video_table.Properties.VariableNames = {'video_name' 'condition' 'onset_time' 'offset_time' 'duration' 'response'};
T = video_table(randperm(size(video_table,1)), :);

add_TRs = [ones(n_extra_TR_trials,1)*n_extra_TRs; zeros(size(T,1)-n_extra_TR_trials-1,1)];
add_TRs = add_TRs(randperm(length(add_TRs)));
add_TRs(end+1) = ending_wait_time/TR;
T.added_TRs = add_TRs;
n_trials = size(T, 1);

%Get the name of the first movie
for itrial = 1:n_trials
    video_name = T.video_name{itrial};
    if T.condition(itrial) == 1
        T.movie_path{itrial} = fullfile(curr, 'videos','dyad_videos_3000ms',video_name);
    elseif T.condition(itrial) == 0
        T.movie_path{itrial} = fullfile(curr, 'videos','crowd_videos_3000ms',video_name);
    end
end

movie = zeros(n_trials, 1);

%% open window
commandwindow;
%     HideCursor;
Screen('Preference','SkipSyncTests',1);

% Uncomment for debugging with transparent screen
% AssertOpenGL;
% PsychDebugWindowConfiguration;

%Suppress frogs
Screen('Preference','VisualDebugLevel', 0);

screen = max(Screen('Screens'));
[win, rect] = Screen('OpenWindow', screen, 0);
[x0,y0] = RectCenter(rect);
Screen('Blendfunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
dispSize = [x0-500 y0-500 x0+500 y0+500];

priorityLevel=MaxPriority(win);
Priority(priorityLevel);

%% Init eyelink

if with_Eyelink
    if EyelinkInit()~= 1
        return;
    end
    
    [~,vs] = Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    
    edfFile=['run', sprintf('%03d', run_number)]; %fullfile(edfout,['run', sprintf('%03d', run_number)]);
    el=EyelinkInitDefaults(win);%window is the window you have opened with screen function
    
    % open file to record data to
    Eyelink('Openfile', edfFile);
    
    % this line will perform the calibration
    Eyelink('command', 'calibration_type = HV9');
    EyelinkDoTrackerSetup(el);
    
    % set up configurations.
    Eyelink('command', 'recording_parse_type = GAZE');
    Eyelink('command', 'saccade_acceleration_threshold = 8000');
    Eyelink('command', 'saccade_velocity_threshold = 30');
    Eyelink('command', 'saccade_motion_threshold = 0.15');
    Eyelink('command', 'saccade_pursuit_fixup = 60');
    
    %	set EDF file contents
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,GAZERES,HREF,AREA');
    Eyelink('command', 'file_event_data  = GAZE,GAZERES,AREA,VELOCITY,HREF');
    
    %	set link data (used for gaze cursor)
    Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,HREF,AREA');
    Eyelink('command', 'link_event_data  = GAZE,GAZERES,AREA,VELOCITY,HREF');
    Eyelink('StartRecording');
    % record a few samples before we actually start displaying
    WaitSecs(0.1);
    
%     eyeLinkCheck(win,x0,y0); %Additional Eyelink Validation that saves the
    %position at the beginning of the block data to help diagnose systematic
    %errors.
end

%% Task instructions and start with the trigger
instructions='Watch the people in each video. If there are more than 2 people, press any button. Press any button to begin.';
DrawFormattedText2(instructions,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
Screen('Flip', win);

%% WAIT FOR TRIGGER TO START
still_loading = 1;
while 1
    if KbCheck
        break;
    end
    
    if still_loading
        movie(1) = Screen('OpenMovie', win, T.movie_path{1}, async, preloadsecs);
        if movie(1) > 0; still_loading = 0; end
    end
end


%% Experiment loop
% experiment start time
% try
    start = GetSecs();
    Screen('Flip', win);
    
    % wait 2 TRs to start
    while (GetSecs-start<start_wait_time)
        if still_loading
            movie(1) = Screen('OpenMovie', win, T.movie_path{1}, async, preloadsecs);
            if movie(1) > 0; still_loading = 0; end
        end
    end
    
    for itrial = 1:n_trials
        still_loading = 1;
        response = 0;
        frame_counter = 1;
        trial_start = GetSecs;
        Screen('SetMovieTimeIndex', movie(itrial), 0);
        Screen('PlayMovie', movie(itrial), rate, 1, sound);
        trial_end = trial_start + stimulus_length;
        iti_end = trial_end + iti_length + T.added_TRs(itrial)*1.5;
        T.onset_time(itrial) = trial_start - start;
        
        if with_Eyelink %inside the trial function
            % these messages will be recorded in the output file determining the begining of the trial
            Eyelink('Message', 'TRIAL_VAR_LABELS video condition');%change VAR1 and VAR2 to your desired variables
            Eyelink('Message', ['!V TRIAL_VAR_DATA ', T.movie_path{itrial}, T.condition(itrial)]);
            Eyelink('Message', ['TRIALID ', num2str(itrial)]);
            Eyelink('Message', 'Begining of the trial');
        end
        
        while 1
            if frame_counter == 90 || GetSecs > (trial_end-(1/60))
                break;
            end
            
            if with_Eyelink
                Eyelink('Message','Rest off');
                Eyelink('Message','Stimulus start');
            end
            
            tex = Screen('GetMovieImage', win, movie(itrial), blocking);
            Screen('DrawTexture', win, tex, [], dispSize);
            Screen('Flip', win);
            Screen('Close', tex);
            
            if still_loading && itrial ~= n_trials
                movie(itrial+1) = Screen('OpenMovie', win, T.movie_path{itrial+1}, async, preloadsecs);
                if movie(itrial+1) > 0; still_loading = 0; end
            end
            
            if ~response
                if KbCheck
                    response = 1;
                    T.response(itrial) = 1;
                end
            end
            frame_counter = frame_counter + 1;
        end
        
        %Get end time and close movie
        real_trial_end = Screen('Flip', win);
        T.offset_time(itrial) = real_trial_end - start;
        T.duration(itrial) = real_trial_end - trial_start;
        Screen('CloseMovie', movie(itrial));
        
        if with_Eyelink
            Eyelink('Message','Stimulus Off');
            Eyelink('Message','Rest Start');
        end
        
        while (GetSecs<iti_end)
            if still_loading && itrial ~= n_trials
                movie(itrial+1) = Screen('OpenMovie', win, T.movie_path{itrial+1}, async, preloadsecs);
                if movie(itrial+1) > 0; still_loading = 0; end
            end
            
            if ~response
                if KbCheck
                    response = 1;
                    T.response(itrial) = 1;
                end
            end
        end
        
        if with_Eyelink
            Eyelink('Message',['TRIAL_RESULT ',num2str(T.condition(itrial))]);
            Eyelink('Message',['TRIAL_RESULT ',num2str(T.response(itrial))]);
            Eyelink('Message',['TRIAL_RESULT ',num2str(T.condition(itrial) == T.response(itrial))]);
            Eyelink('Message', 'End of the trial');
        end
        
        if (mod(itrial, 55) == 0) && (itrial ~= n_trials)
            DrawFormattedText2('Take a brief break./n Press any button when ready to continue.','win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
            Screen('Flip', win);
            fprintf('Break in experiment'); 
            while 1
                if KbCheck
                    break;
                end
            end
        end
    end
    
    %% Save data
    actual_duration = GetSecs() - start;
    save(fullfile(matout,['run', sprintf('%03d', run_number) '_',curr_date,'.mat']))
    filename = fullfile(timingout,['run', sprintf('%03d', run_number), '_',curr_date,'.csv']);
    writetable(T, filename);
    write_event_files(subjName,run_number, T);
    ShowCursor;
    Screen('CloseAll')
    
    %% save eyelink and close
    if with_Eyelink
        Eyelink('Message', 'End of the Block');
        Eyelink('Stoprecording')
        Eyelink('CloseFile');
        try
            fprintf('Receiving data file ''%s''\n', edfFile );
            status=Eyelink('ReceiveFile',edfFile);
            if status > 0
                fprintf('ReceiveFile status %d\n', status);
            end
            if exist(edfFile, 'file')
                fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
            end
        catch
            fprintf('Problem receiving data file ''%s''\n', edfFile );
        end
        Eyelink('ShutDown');
        
        try
            movefile([edfFile,'.edf'], fullfile(edfout, [edfFile, '_', curr_date, '.edf']));
            move_error = 'No';
        catch
            move_error = 'Yes';
        end
        fprintf(['Move EDF Error? ',move_error,'\n'])
    end
    
    %% Print participant performance
    false_alarms = sum(T.response(T.condition == 1) == 1);
    hits = sum(T.response(T.condition == 0) == 1);
    total_accuracy = mean(T.condition ~= T.response);
    s=sprintf('%g hits out of %g crowd videos. %g false alarms out of %g dyad videos. Overall accuracy is %0.2f.', hits, n_response, false_alarms, n_real, total_accuracy);
    fprintf('\n\n\n%s\n',WrapString(s));
    
    s=sprintf('Expected length was %g min. Actual length was %g min. Difference was %g min', (expected_duration/60), (actual_duration/60), ((actual_duration - expected_duration)/60));
    fprintf('\n%s\n\n ',WrapString(s));
% catch e
%     fprintf('\nError: %s\n',e.message);
%     actual_duration = GetSecs() - start;
%     save(fullfile(matout,['run', sprintf('%03d', run_number) '_',curr_date,'.mat']))
%     filename = fullfile(timingout,['run', sprintf('%03d', run_number), '_',curr_date,'.csv']);
%     writetable(T, filename);
%     write_event_files(subjName,run_number, T);
%     ShowCursor;
%     Screen('CloseAll')
%     
%     %% Print participant performance
%     false_alarms = sum(T.response(T.condition == 1) == 1);
%     hits = sum(T.response(T.condition == 0) == 1);
%     total_accuracy = mean(T.condition ~= T.response);
%     s=sprintf('%g hits out of %g crowd videos. %g false alarms out of %g dyad videos. Overall accuracy is %0.2f.', hits, n_response, false_alarms, n_real, total_accuracy);
%     fprintf('\n\n\n%s\n',WrapString(s));
%     
%     s=sprintf('Expected length was %g s. Actual length was %g s.', expected_duration, actual_duration);
%     fprintf('\n%s\n\n ',WrapString(s));
% end

