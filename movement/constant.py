import os
# change this data_dir for personal path
if os.environ['HOME'] == 'E:/':
    data_dir = 'E:/Roboballer/nba-movement-data'
else:
    raise Exception("Unspecified data_dir, unknown environment")
