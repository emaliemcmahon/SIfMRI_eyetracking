#
import os
import time
import argparse
import numpy as np
from pathlib import Path
import csv
import pandas as pd
from glob import glob


def load_video_names(file):
    df = pd.read_csv(file)
    df['condition'] = 1
    return df


def mk_output_paths(SID, toppath):
    print('\nSubject directory not yet created. I will make it for you...')
    Path(toppath).mkdir(parents=True, exist_ok=True)
    Path(os.path.join('data', f'subj{str(SID).zfill(3)}', 
'runfiles')).mkdir(parents=True, exist_ok=True)


def shuffle_trials(trials, n_blocks):
    trials_shuffle = trials.copy()
    seed = int((time.time() % 1) * 10000)
    np.random.seed(seed)
    np.random.shuffle(trials_shuffle)
    return trials_shuffle.reshape((n_blocks, -1))


def save_data(df, filename):
    df.to_csv(filename, index=False, header=True)


def add_filler_trials(n=5):
    crowd_videos = np.array(glob(os.path.join(os.getcwd(), 'videos', 
'crowd_videos_3000ms', '*.mp4')))
    movie_path = np.random.choice(crowd_videos, size=n, replace=False)
    video_name = [vid.split('/')[-1] for vid in movie_path]
    return pd.DataFrame({'video_name': video_name, 'condition': [0 for i in range(n)]})


def mk_block(videos, n):
    crowd_df = add_filler_trials(int(len(videos)*.1))
    block_df = pd.concat([videos, crowd_df])
    shuffled_block = block_df.sample(frac = 1)
    shuffled_block['block'] = n
    return shuffled_block


def get_past_runs(SID=77, n_runs=6, n_repeats=4, set='test'):
    toppath = os.path.join('data', f'subj{str(SID).zfill(3)}')
    mk_output_paths(SID, toppath)
    print('\nWriting run files...')
    videos = load_video_names('test.csv')
    for i in range(n_runs):
        run_df = []
        print(f'run {i+1}')
        for j in range(n_repeats):
            print(f'block {j+1}')
            run_df.append(mk_block(videos, j+1))
            print(len(run_df))
        print('\n')
        run_df = pd.concat(run_df)
        outname = os.path.join(toppath, 'runfiles', f'run{str(i+1).zfill(3)}.csv')
        save_data(run_df, outname)
    print('\nRuns assigned. Closing...')


def getArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sid', type=int, default=77)
    parser.add_argument('--n_runs', type=int, default=3)
    parser.add_argument('--n_repeats', type=int, default=4)
    parser.add_argument('--set', type=str, default='test')
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = getArgs()
    get_past_runs(args.sid, args.n_runs, args.n_repeats)
