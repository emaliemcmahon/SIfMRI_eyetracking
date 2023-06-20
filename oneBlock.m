function blockData = oneBlock(w,xo,yo,with_Eyelink,edfFile,path2edf,...
    iBlock,nTrials,vidSubj,taskID,vidtopdir)

% Screen('DrawLines', w, allCoords, 3,[255 0 0], [xo yo]);
Screen('Flip', w);
Key1 = KbName(',<'); %yes
Key2 = KbName('.>'); %no

leftRight = BalanceTrials(nTrials,1,(1:2));
% 1 = Left
% 2 = Right

if with_Eyelink
    if EyelinkInit()~= 1
        return;
    end;
    
    el=EyelinkInitDefaults(w);%window is the window you have opened with screen function
    
    % open file to record data to
    Eyelink('Openfile', edfFile);
    
    % this line will perform the calibration
    EyelinkDoTrackerSetup(el);
    
    % set up configurations.
    Eyelink('command', 'calibration_type = HV5');
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
    
    
    eyeLinkCheck(w,xo,yo); %Additional Eyelink Validation that saves the
    %position at the beginning of the block data to help diagnose systematic
    %errors.
end

DrawFormattedText(w, 'Press any button to begin.','center','center',[255 255 255]);
Screen('Flip', w);
KbWait(-1, 0);

while KbCheck
end

vidTrialUsed = NaN(nTrials,1);
startOfTrial = NaN((nTrials + 1),1);
mvtStartFrame = NaN(nTrials,1);
endFrame = NaN(nTrials,1);
response = NaN(nTrials,1);
accuracy = NaN(nTrials,1);
RT = NaN(nTrials,1);
win = NaN(nTrials,1);
for iTrial = 1 : nTrials
    if with_Eyelink %inside the trial function
        % these messages will be recorded in the output file determining the begining of the trial
        Eyelink('Message', 'TRIAL_VAR_LABELS vidSubj Condition');%change VAR1 and VAR2 to your desired variables
        Eyelink('Message', ['!V TRIAL_VAR_DATA ', num2str(vidSubj,vidTrialUsed(iTrial))]);
        Eyelink('Message', ['TRIALID ', num2str(iTrial)]);
        Eyelink('Message', ['!V TARGET_POS TARG1 (',num2str(xo),', ',num2str(yo),') 1 1']);
        Eyelink('Message', 'Begining of the trial');
    end
    
    if leftRight(iTrial) == 1
        trialDirection = 'Left';
    elseif leftRight(iTrial) == 2
        trialDirection = 'Right';
    end
    
    allPosTrials = dir([vidtopdir,'/Videos/resizedVideoMatrices_' taskID '/' vidSubj '/'...
        trialDirection '/Co*']);
    
    vidTrialUsed(iTrial) = randi(length(allPosTrials));
    
    load([vidtopdir,'/Videos/resizedVideoMatrices_' taskID '/' vidSubj '/'...
        trialDirection '/' allPosTrials(vidTrialUsed(iTrial)).name]);
    
    
    currVidFile = resizedStruct.vid;
    mvtStartFrame(iTrial) = resizedStruct.adjustedStartFrame;
    clear resizedStruct
    
    startFrame = mvtStartFrame(iTrial) - 20;
    if mvtStartFrame(iTrial) + 35 <= size(currVidFile,4)
        endFrame(iTrial) = mvtStartFrame(iTrial) + 35;
    else
        endFrame(iTrial) = size(currVidFile,4);
    end
    
    while KbCheck
    end
    
    if with_Eyelink
        Eyelink('Message','Fixation off');
        Eyelink('Message','Stimulus start');
    end
    
    startOfTrial(iTrial) = GetSecs;
    for iFrame = startFrame : (endFrame(iTrial) + 3)
        if iFrame > endFrame(iTrial)
            showFrame = endFrame(iTrial);
        else
            showFrame = iFrame;
        end
        %         imagesc(currVidFile(250:end,:,:,showFrame));
        
        texturePointer = Screen('MakeTexture', w, currVidFile(250:end,:,:,showFrame));
        Screen('DrawTexture', w, texturePointer);
        Screen('Flip', w);
        
        [~, secs, keyCode, ~] = KbCheck(-1); %Determines what key is pressed during stimuli presentation
        if keyCode(Key1)
            response(iTrial) = 1; %For attacker going to the right
            RT(iTrial) = secs - startOfTrial(iTrial); %Determines rt
        elseif keyCode(Key2)
            response(iTrial) = 2; %For the attacker going to the left
            RT(iTrial) = secs - startOfTrial(iTrial); %Determines rt
        end
    end
    if with_Eyelink
        Eyelink('Message','Stimulus Off');
        Eyelink('Message','Feedback Start');
    end
    
    if ~isnan(response(iTrial))
        if leftRight(iTrial) == 1 && response(iTrial) == 1
            accuracy(iTrial) = 1;
        elseif leftRight(iTrial) == 2 && response(iTrial) == 2
            accuracy(iTrial) = 1;
        else
            accuracy(iTrial) = 0;
        end
    end
    
    if accuracy(iTrial) == 0 || isnan(accuracy(iTrial))
        win(iTrial) = 0;
    else
        if iTrial <= 5
            win(iTrial) = randi([0 1]);
        else
            if RT(iTrial) <= median(RT,'omitnan')
                win(iTrial) = 1;
            else
                win(iTrial) = 0;
            end
        end
    end
    
    feedback_start = GetSecs;
    feedback_end = 0;
    while feedback_end < 0.5
        feedback_end = GetSecs - feedback_start;
        if win(iTrial) == 1
            Screen('FillOval',w,[0 255 0],[xo-10 xo+15; yo-10 yo+10]);
            Screen('Flip',w)
        else
            Screen('FillOval',w,[255 0 0],[xo-10 xo+10; yo-10 yo+10]);
            Screen('Flip',w)
        end
    end
    
    if with_Eyelink
        Eyelink('Message','Feedback Off');
        Eyelink('Message','Rest Start');
    end
    
    Screen('Flip',w)
    rest_start = GetSecs;
    rest_end = 0;
    while rest_end < 0.5
        rest_end = GetSecs - rest_start;
    end
    
    if with_Eyelink
        Eyelink('Message',['TRIAL_RESULT ',num2str(response(iTrial))]);
        Eyelink('Message',['TRIAL_RESULT ',num2str(accuracy(iTrial))]);
        Eyelink('Message',['TRIAL_RESULT ',num2str(RT(iTrial))]);
        Eyelink('Message', 'End of the trial');
    end
end
startOfTrial(iTrial + 1) = GetSecs;

blockData.day = date;
blockData.block = iBlock;
blockData.leftRight = leftRight;
blockData.randSubj = vidSubj;
blockData.vidTrialUsed = vidTrialUsed;
blockData.startOfTrial = startOfTrial;
blockData.mvtStartFrame = mvtStartFrame;
blockData.endFrame = endFrame;
blockData.response = response;
blockData.RT = RT;
blockData.accuracy = accuracy;
blockData.win = win;

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
        movefile([edfFile],path2edf);
        move_error = 'No'; 
    catch
        move_error = 'Yes';
    end
    fprintf(['Move EDF Error? ',move_error,'\n'])
end
end
