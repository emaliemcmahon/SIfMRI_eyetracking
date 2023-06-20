tic
try
    clear all
    vidtopdir = '/Users/Shared/Projects/Goalie/';
    rate = 1; %Makes sure that the rate on the computer is 60Hz when set to 1.
    %Does not check when rate is set t0 0. 
    
    commandwindow
    subjID = [];
    with_Eyelink = [];
    subjID = input('Please input the subject ID: ', 's');
    with_Eyelink = input('With Eyelink? (1 = yes,0 = no): ');
    
    if isempty(subjID)
        subjID = 'test';
    end
    
    if isempty(with_Eyelink)
        with_Eyelink = 0;
    end
    
    if ~exist(['data/behavioral/' subjID],'dir')
        mkdir(['data/behavioral/' subjID]);
    end
    
    if with_Eyelink
        path2edf = ['data/edfs/',subjID,'/'];
        if ~exist(path2edf,'dir')
            mkdir(path2edf);
        end
    end
    
    WhichScreen = max(Screen('Screens'));
    KbName('UnifyKeyNames');
    Screen('Preference', 'SkipSyncTests', 1);
    [w, rect] = Screen('OpenWindow',WhichScreen,[0 0 0]);
    Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    if rate
        hz = 1/Screen('GetFlipInterval',w);
        e = 0.5;
        if abs(hz-60)>= e
            error('Check Refresh Rate')
        end
    end
    
    xo = rect(3)/2;
    yo = rect(4)/2;
    
    coop_subj = [2 7 5]; %The position in video directory order on easy to hard
    comp_subj = [5 10 7];
    
    nBlocks = 6;
    [compCoop, subjDiff] = BalanceTrials(nBlocks,1,1:2,1:3);

    nTrials = 30;
    taskID = {'Comp' 'Coop'};
    for iBlock = 1:nBlocks
        vidDir = dir([vidtopdir,'Videos/resizedVideoMatrices_',taskID{compCoop(iBlock)},'/20*']);
        
        if compCoop(iBlock) == 1
            vidSubj = vidDir(comp_subj(subjDiff(iBlock))).name;
        elseif compCoop(iBlock) == 2
            vidSubj = vidDir(coop_subj(subjDiff(iBlock))).name;
        end
        
        if ~with_Eyelink
            edfFile = 'none';
            path2edf = 'none';
        elseif with_Eyelink
            edfFile = ['block',num2str(iBlock,'%02d')];
        end
        
        blockData = oneBlock(w,xo,yo,with_Eyelink,edfFile,path2edf,...
            iBlock,nTrials,vidSubj,taskID{compCoop(iBlock)},vidtopdir);
        save(['data/behavioral/' subjID '/' subjID '_block' num2str(iBlock,'%02d'),'_',datestr(now,'yyyymmdd')],'blockData','-v7')
    end
    sca
    
catch
    lasterror
    sca
end
toc
