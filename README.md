# SIdyads_presentation
 Presenting the dyad videos stimuli for the fMRI experiment

## `SIdyads.m`
Main presentation script used for the fMRI experiment. 50 3-second dyadic videos are shown in a run. The experiment is setup with a 1.5 second TR. There is one TR black screen between most videos. On a random 10 trials, there is an additional single TR break. The final trials has an additional 9 TRs to allow for recording of the full hemodynamic response. 

The partcipant's task is to hit a button when there is a more than 2 people present in a video. These videos are not analyzed and serve as an attention control.

The script calls `write_event_files.m` to save the data in BIDS format. 

## `assign_conditions.py`
This must be run prior to the experiment. It can be be called by `python3 assign_conditions.py SID` where SID is the participant number. It makes an output data directory with the name of the participant. It makes some empty directories that `SIdyads.m` writes into during the experiment. Most importantly, it writes `data/SID/runfiles/`. Each file is a CSV file of the videos to be presented on a particular run. 

The CSV files are grouped into runs of 6. Every six runs contains 2 test runs and 4 training runs. The two test runs are repeats of one another presenting the 50 videos used to test the encoding models. Each of the training runs are unique and each present 50 of the training videos for model fitting. The videos that are assigned to a particular training run are randomized across repeats of the full stimulus set. 

While `assign_conditions.py` randomly assigns the training video to a particular run. It does not shuffle the video presentation order. This is done in `SIdyads.m`.

## `test.csv` and `train.csv`
These CSV files contain the names of the videos in the training and test set. These files are used by `assign_conditions.py` to write the run files. 
