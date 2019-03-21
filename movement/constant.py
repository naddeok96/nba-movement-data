import os
# change this data_dir for personal path
if os.environ['HOME'] == 'C:/Users/Kyle Naddeo/Desktop/':
    data_dir = 'C:/Users/Kyle Naddeo/Desktop/roboballer/nba-movement-data'
else:
    raise Exception("Unspecified data_dir, unknown environment")
