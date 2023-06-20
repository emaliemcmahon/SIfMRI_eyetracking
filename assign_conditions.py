#
import os
import time
import argparse
import numpy as np
from pathlib import Path
import csv
import pandas as pd

def load_video_names(file):
    with open(file, newline='') as csvfile:
        data = list(csv.reader(csvfile))
    return np.array(data)


def mk_output_paths(SID, toppath):
    print('\nSubject directory not yet created. I will make it for you...')
    Path(toppath).mkdir(parents=True, exist_ok=True)
    Path(os.path.join('data', f'subj{str(SID).zfill(3)}', 'runfiles')).mkdir(parents=True, exist_ok=True)
    Path(os.path.join('data', f'subj{str(SID).zfill(3)}','matfiles')).mkdir(parents=True, exist_ok=True)
    Path(os.path.join('data', f'subj{str(SID).zfill(3)}','timingfiles')).mkdir(parents=True, exist_ok=True)
    Path(os.path.join('data', f'subj{str(SID).zfill(3)}','edfs')).mkdir(parents=True, exist_ok=True)


def shuffle_trials(trials, n_blocks):
    trials_shuffle = trials.copy()
    np.random.seed(int(time.time()))
    np.random.shuffle(trials_shuffle)
    return trials_shuffle.reshape((n_blocks, -1))


def save_data(array, filename):
    df = pd.DataFrame(array)
    df.to_csv(filename, index=False, header=False)

def get_past_runs(SID=77, n_repeats=6, n_blocks=5):
    toppath = os.path.join('data', f'subj{str(SID).zfill(3)}')
    mk_output_paths(SID, toppath)
    print('\nWriting run files...')
    videos = load_video_names('video_names.txt')
    count = 1
    for i in range(n_repeats):
        videos_shuffle = shuffle_trials(videos, n_blocks)
        for j in range(n_blocks):
            outname = os.path.join(toppath, 'runfiles', f'run{str(count).zfill(3)}.csv')
            save_data(videos_shuffle[j, :], outname)
            count += 1
    print('\nRuns assigned. Closing...')


def getArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sid', type=int, default=77)
    parser.add_argument('--n_repeats', type=int, default=6)
    parser.add_argument('--n_blocks', type=int, default=5)
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = getArgs()
    get_past_runs(args.sid, args.n_repeats, args.n_blocks)
