function write_event_files(subjName,run_number,ses_number,T)
% % Makes the para files from the run of the localizer.
% %%Written by EG McMahon
% 
if nargin < 1
    subjName=77;
    run_number=1;
    ses_number = 1; 
end

%% BIDS

%TSV
%TSV files expected in BIDS format
bidsoutpath = fullfile('data', ['subj',sprintf('%03d', subjName)], 'bids');
if ~exist(bidsoutpath); mkdir(bidsoutpath); end 
bids_sname = ['sub-',sprintf('%02d', subjName), '_ses-', sprintf('%02d', ses_number)]; 


conds = T.condition + 1;
T = removevars(T,{'added_TRs', 'movie_path', 'offset_time', 'condition'}); 
T = movevars(T, 'video_name', 'After', 'duration'); 
T = movevars(T, 'response', 'After', 'video_name'); 

trial_names = {'crowd', 'dyad'}; 
trial_type = {}; 
for i = 1:size(T,1)
    trial_type{end+1} = trial_names{conds(i)}; 
end 
trial_type = trial_type';
T = addvars(T, trial_type, 'Before', 'video_name'); 
T.Properties.VariableNames = {'onset' 'duration' 'trial_type' 'identifier' 'response'}; 
T.onset = single(T.onset); 
T.duration = single(T.duration); 

bids_filename = fullfile(bidsoutpath, [bids_sname, '_task-SIdyads_run-', sprintf('%02d', run_number),'_events']); 
writetable(T,[bids_filename,'.tsv'], 'FileType','text', 'Delimiter', '\t'); 

%JSON

%onset
j.onset.LongName = 'Stimulus onset time'; 
j.onset.Description = 'Time of the stimulus onset in seconds relative to the beginning of the experiment t=0.';

%duration
j.duration.LongName = 'Stimulus duration'; 
j.duration.Description = 'Duration of the stimulus presentation in seconds.';

%trial_type
j.trial_type.LongName = 'Stimulus condition type'; 
j.trial_type.Description = 'The condition of the stimulus being presented in a given block';
j.trial_type.Levels.dyads = 'Videos of two people performing various common actions. This is the condition that will be modeled in the main analysis.'; 
j.trial_type.Levels.crowd = 'Videos of crowds of people performing common actions. The participant should hit a button on each of these trials.'; 

%identifier
j.identifier.LongName = 'Movie file identifier'; 
j.identifier.Description = 'The name of the movie file that is presented on a given trial.'; 

%response
j.response.LongName = 'Participant response boolean'; 
j.response.Description = 'Whether the participant responded on a given trial participants should only respond on crowd trials. Dyad trials with a response should be excluded from the GLM.'; 

%Stimulus presentation
if ispc
    opsys = system_dependent('getwinsys');
elseif ismac
    opsys = system_dependent('getos');
end

j.StimulusPresentation.OperatingSystem = opsys; 
j.StimulusPresentation.SoftwareName = 'Psychtoolbox'; 
j.StimulusPresentation.SoftwareRRID = 'SCR_002881'; 
v = split(PsychtoolboxVersion,' '); 
j.StimulusPresentation.SoftwareVersion = v{1}; 
j.StimulusPresentation.MATLABVersion = version; 

encodedJSON = jsonencode(j,'PrettyPrint',true); %encode JSON

fid = fopen([bids_filename, '.json'],'w'); 
fprintf(fid, encodedJSON); 






