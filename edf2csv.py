#
import pandas as pd
import numpy as np
import os
from glob import glob
from pathlib import Path
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
pd.set_option('mode.chained_assignment',  None)

subj = 'subj077'
Path(f'data/{subj}/asc').mkdir(exist_ok=True, parents=True)
out_data = []
for run in range(3):
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
        print(df_samples.head())

        with open(events_file) as f:
            events=f.readlines()

        # keep only lines starting with "MSG"
        events=[ev for ev in events if ev.startswith("MSG")]

        experiment_start_index=np.where(["video" in ev for ev in events])[0][0]
        events=events[experiment_start_index+1:]

        df_ev=pd.DataFrame([ev.split() for ev in events])
        df_ev = df_ev[[1, 2, 3]]
        df_ev.columns = ['time', 'event', 'data']
        # df_ev.loc[df_ev.data == 'None']
        print(df_ev.loc[df_ev.data.isna()])

#         df_conditions = df_ev[df_ev[3] == 'TRIAL_VAR_DATA']
#         df_conditions = df_conditions[[1, 4]]
#         df_conditions.reset_index(drop=True, inplace=True)
#         df_conditions.reset_index(drop=False, inplace=True)
#         df_conditions.columns = ["trial", "time", "path"]
#         df_conditions[["path", "video"]] = df_conditions["path"].str.rsplit(pat="\\", n=1, expand=True)
#         df_conditions[["path", "condition"]] = df_conditions["path"].str.rsplit(pat="\\", n=1, expand=True)
#         df_conditions[["condition", "trash"]] = df_conditions["condition"].str.split(pat="_", n=1, expand=True)
#         df_conditions['condition_bool'] = False
#         df_conditions.loc[df_conditions['condition'] == 'dyad', 'condition_bool'] = True
#         df_conditions.drop(columns=['path', 'trash', 'time'], inplace=True)

#         df_ev = df_ev[(df_ev[2] == 'Stimulus') & (df_ev[3] == 'start')]
#         df_ev.reset_index(drop=True, inplace=True)
#         df_ev = df_ev[[1]]
#         df_ev.reset_index(drop=False, inplace=True)
#         df_ev.columns = ['trial', 'time']

#         df_events = df_conditions.merge(df_ev, on='trial')
#         df_events = df_events[df_events.condition_bool]
#         df_events.drop(columns=['condition', 'condition_bool'], inplace=True)
#         df_events.reset_index(drop=True, inplace=True)
#         df_events.time = df_events.time.astype('float')

#         for i, row in df_events.iterrows():
#             onset = row.time
#             offset = row.time + stimulus_length
#             cur = df_samples[(df_samples.time >= onset) & (df_samples.time < offset)]
#             trial = row.trial
#             video = row.video.replace('\x01', '')
#             cur['trial'] = trial
#             cur['video'] = video
#             cur['run'] = run
#             out_data.append(cur)
# df = pd.concat(out_data)
# df.reset_index(drop=True, inplace=True)
# inds = np.isclose(df.p, 0)
# df.loc[inds, ['x', 'y']] = '-7777'
# df.x = df.x.astype('float')
# df.y = df.y.astype('float')
# df.time = df.time.astype('int')
# df.loc[inds, ['x', 'y', 'p']] = np.nan
# missing_vals = df.loc[inds]


# df.sort_values(by='time', inplace=True)
# df['trial_time_index'] = df.groupby(['video', 'run']).cumcount()

# print(missing_vals.head(100))
# print('\n\nfinal df')   
# print(df.head())
# print(f'number of samples = {len(df)}')
# print(df.dtypes)
# df.to_csv(f'processed_data/{subj}.csv', index=False)
