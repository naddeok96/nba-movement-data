import os.path
home_folder = os.path.expanduser('~')
# change this data_dir for personal path
if home_folder == 'E:/':
    data_dir = 'E:/Roboballer/nba-movement-data'
else:
    raise Exception("Unspecified data_dir, unknown environment")
