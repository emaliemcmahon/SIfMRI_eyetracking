function run_number = SIdyads(subjName, run_number, ses_number, trigger, P4, pulse_num, response_num)
% Presents the social interaction localizer task
% Inputs:
% subjName as an integer used when saving and loading the sequences
% runNum is an integer used when saving and loading the sequences
% design is either 1 or 2 and selects the order of video presentation.
% trigger is a binaray value whether the code should wait for a trigger
% from the scanner
% Written by Emalie McMahon Feb 26, 2020


if nargin < 1
    subjName = 77;
    run_number = [];
    ses_number = 2;
    trigger = 0;
end

% make output directories
curr = pwd;
topout = fullfile(curr, 'data', ['subj',sprintf('%03d', subjName)]);
matout = fullfile(topout, 'matfiles');
timingout = fullfile(topout, 'timingfiles');
runfiles = fullfile(topout,'runfiles');

if ~exist(topout, 'dir')
    s=sprintf('Run files do not exist of subject %g. Make run files before continuing.', subjName);
    fprintf('\n%s\n\n ',WrapString(s));
else

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

    s=sprintf('Subject number is %g. Session number is %g. Run number is %g. ', subjName, ses_number, run_number);
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
    n_response = 5;
    n_real = size(video_list, 1);
    n_extra_TRs = 0;
    n_extra_TR_trials = 0;
    ending_wait_time = .5;
    start_wait_time = TR;

    expected_duration = ((n_response + n_real) * (stimulus_length + iti_length)) + (n_extra_TRs * n_extra_TR_trials * TR) + ending_wait_time + start_wait_time;
    fprintf('Expected duration: %g', expected_duration);
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
        video_name = split(T.video_name{itrial},'.');
        video_name = [video_name{1},'.mov'];
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
        AssertOpenGL;
        PsychDebugWindowConfiguration;

    %Suppress frogs
    Screen('Preference','VisualDebugLevel', 0);

    screen = max(Screen('Screens'));
    [win, rect] = Screen('OpenWindow', screen, 0);
    [x0,y0] = RectCenter(rect);
    Screen('Blendfunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    dispSize = [x0-500 y0-500 x0+500 y0+500];

    priorityLevel=MaxPriority(win);
    Priority(priorityLevel);

    %% Task instructions and start with the trigger
    instructions='Watch the people in each video. If there are more than 2 people, hit the button.';
    DrawFormattedText2(instructions,'win',win,'sx','center','sy','center','xalign','center','yalign', 'center','baseColor',[255, 255, 255]);
    Screen('Flip', win);

    %% WAIT FOR TRIGGER TO START
    still_loading = 1;
    wait_to_start = GetSecs();
    if trigger
        IOPort('Flush', P4); %flush event buffer
        while 1
            [pulse,temptime,readerror] = IOPort('Read',P4,0,1);
            disp(pulse);
            if ~isempty(pulse) && (pulse == pulse_num)
                break;
            end

            if still_loading
                movie(1) = Screen('OpenMovie', win, T.movie_path{1}, async, preloadsecs);
                if movie(1) > 0; still_loading = 0; end
            end

        end
        IOPort('Flush', P4);
        clear pulse
    else
        while (GetSecs-wait_to_start<0.5)
            if still_loading
                movie(1) = Screen('OpenMovie', win, T.movie_path{1}, async, preloadsecs);
                if movie(1) > 0; still_loading = 0; end
            end
        end
    end


    %% Experiment loop
    % experiment start time
    try
        start = GetSecs();
        ready_to_play_next = 0;
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
            while 1
                if frame_counter == 90 || GetSecs > (trial_end-(1/60))
                    break;
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
                    if trigger
                        %check accuracy
                        [pulse,pulse_t] = IOPort('Read',P4,0,1);
                        if ~isempty(pulse) && (pulse == response_num)
                            response = 1;
                            T.response(itrial) = 1;
                        end
                        IOPort('Flush', P4); clear pulse;
                    elseif ~trigger
                        if KbCheck
                            response = 1;
                            T.response(itrial) = 1;
                        end
                    end
                end
                frame_counter = frame_counter + 1;
            end

            %Get end time and close movie
            real_trial_end = Screen('Flip', win);
            T.offset_time(itrial) = real_trial_end - start;
            T.duration(itrial) = real_trial_end - trial_start;
            Screen('CloseMovie', movie(itrial));

            ready_to_play_next = 0;
            while (GetSecs<iti_end)
                if still_loading && itrial ~= n_trials
                    movie(itrial+1) = Screen('OpenMovie', win, T.movie_path{itrial+1}, async, preloadsecs);
                    if movie(itrial+1) > 0; still_loading = 0; end
                end

                if ~response
                    if trigger
                        %check accuracy
                        [pulse,pulse_t] = IOPort('Read',P4,0,1);
                        if ~isempty(pulse) && (pulse == 244)
                            response = 1;
                            T.response(itrial) = 1;
                        end
                        IOPort('Flush', P4); clear pulse;
                    elseif ~trigger
                        if KbCheck
                            response = 1;
                            T.response(itrial) = 1;
                        end
                    end
                end
            end
            GetSecs - trial_start
        end
        actual_duration = GetSecs() - start;
        save(fullfile(matout,['run', sprintf('%03d', run_number) '_',curr_date,'.mat']))
        filename = fullfile(timingout,['run', sprintf('%03d', run_number), '_',curr_date,'.csv']);
        writetable(T, filename);
        write_event_files(subjName,run_number, ses_number, T);
        ShowCursor;
        Screen('CloseAll')

        %% Print participant performance
        false_alarms = sum(T.response(T.condition == 1) == 1);
        hits = sum(T.response(T.condition == 0) == 1);
        total_accuracy = mean(T.condition ~= T.response);
        s=sprintf('%g hits out of %g crowd videos. %g false alarms out of %g dyad videos. Overall accuracy is %0.2f.', hits, n_response, false_alarms, n_real, total_accuracy);
        fprintf('\n\n\n%s\n',WrapString(s));

        s=sprintf('Expected length was %g s. Actual length was %g s.', expected_duration, actual_duration);
        fprintf('\n%s\n\n ',WrapString(s));
    catch e
        fprintf('\nError: %s\n',e.message);
        actual_duration = GetSecs() - start;
        save(fullfile(matout,['run', sprintf('%03d', run_number) '_',curr_date,'.mat']))
        filename = fullfile(timingout,['run', sprintf('%03d', run_number), '_',curr_date,'.csv']);
        writetable(T, filename);
        write_event_files(subjName,run_number, ses_number, T);
        ShowCursor;
        Screen('CloseAll')

        %% Print participant performance
        false_alarms = sum(T.response(T.condition == 1) == 1);
        hits = sum(T.response(T.condition == 0) == 1);
        total_accuracy = mean(T.condition ~= T.response);
        s=sprintf('%g hits out of %g crowd videos. %g false alarms out of %g dyad videos. Overall accuracy is %0.2f.', hits, n_response, false_alarms, n_real, total_accuracy);
        fprintf('\n\n\n%s\n',WrapString(s));

        s=sprintf('Expected length was %g s. Actual length was %g s.', expected_duration, actual_duration);
        fprintf('\n%s\n\n ',WrapString(s));
    end
end
end
