#
from shlex import join
import pandas as pd
import numpy as np
import os
from glob import glob
from pathlib import Path
import shutil
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
pd.set_option('mode.chained_assignment',  None)

subj = 'subj005'
Path(f'data/{subj}/asc').mkdir(exist_ok=True, parents=True)
out_data = []
for run in range(2):
    run_str = str(run+1).zfill(3)
    edf_pattern = f'data/{subj}/edfs/run{run_str}*.edf'
    print(edf_pattern)
    if glob(edf_pattern): 
        edf_file = glob(edf_pattern)[0]
        print(edf_file)
        events_file = f'data/{subj}/asc/run{run_str}_events.asc'
        samples_file = f'data/{subj}/asc/run{run_str}_samples.asc'
        left_right = 'left'
        stimulus_length = 3000

        if not os.path.exists(events_file):
            os.system(f'edf2asc -y -e {edf_file} {events_file}')

        if not os.path.exists(samples_file):
            os.system(f'edf2asc -y -s {edf_file} {samples_file}')

        df_samples = pd.read_table(samples_file, index_col=False,
                        names=["time", f"{left_right}_x", f"{left_right}_y", f"{left_right}_p"])
        df_samples.columns = ['time', 'x', 'y', 'p']
        df_samples.time = df_samples.time.astype('float')

        with open(events_file) as f:
            events=f.readlines()

        # keep only lines starting with "MSG"
        events=[ev for ev in events if ev.startswith("MSG")]
        experiment_start_index=np.where(["TRIALID" in ev for ev in events])[0][0]
        events=events[experiment_start_index:]

        df_ev=pd.DataFrame([ev.split() for ev in events])
        df_ev = df_ev[[1, 2, 3]]
        df_ev.columns = ['time', 'event', 'data']
        # df_ev.loc[df_ev.data == 'None']
        df_ev.loc[df_ev.data.isna(), 'data'] = df_ev.loc[df_ev.data.isna(), 'time'].copy()
        df_ev.drop(columns=['time'], inplace=True)
        df_ev_pivot = []
        for i, j in df_ev.groupby('event'):
            j.drop(columns='event', inplace=True)
            j.rename(columns={'data': i}, inplace=True)
            j.reset_index(drop=True, inplace=True)
            df_ev_pivot.append(j)
        df_ev_pivot = pd.concat(df_ev_pivot, axis=1)
        df_ev_pivot['TRIALID'] = df_ev_pivot['TRIALID'].astype('int')
        df_ev_pivot[['STIMULUS_START', 'STIMULUS_OFF']] = df_ev_pivot[['STIMULUS_START', 'STIMULUS_OFF']].astype('int')

        print('loading runfile')
        df_runfile = pd.read_csv(f'data/{subj}/runfiles/run{run_str}.csv')
        df_ev_pivot = df_ev_pivot.join(df_runfile)
        print('\n\nreorganized events')
        print(df_ev_pivot.head())

        for i, row in df_ev_pivot.iterrows():
            onset = row.STIMULUS_START
            offset = onset + 3000
            cur = df_samples[(df_samples.time > onset) & (df_samples.time <= offset)]
            cur['run'] = run 
            cur['trial'] = row.TRIALID
            cur['video_name'] = row.video_name
            cur['block'] = row.block
            cur['condition'] = row.condition
            out_data.append(cur)
df = pd.concat(out_data)
df.reset_index(drop=True, inplace=True)
inds = np.isclose(df.p, 0)
df.loc[inds, ['x', 'y']] = '-7777'
df[['x', 'y']] = df[['x', 'y']].astype('float')
df.time = df.time.astype('int')
df.loc[inds, ['x', 'y', 'p']] = np.nan

df.sort_values(by='time', inplace=True)
df['trial_time_index'] = df.groupby(['trial', 'run']).cumcount()

print(f'number of samples = {len(df)}')
print(df.dtypes)

print('\n\nfinal df') 
print(df.head(10))
df.to_csv(f'processed_data/{subj}.csv', index=False)
shutil.copy(f'processed_data/{subj}.csv', f'../SIfMRI_analysis/data/raw/eyetracking/{subj}.csv')
