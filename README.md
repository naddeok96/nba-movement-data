# nba-movement-data~Neil Seward
Ever since the nba stopped public access of their movement data, I though it would be good to have a copy of @neilmj data repo incase he deletes his data repo.

Credit: [@neilmj](https://github.com/neilmj/BasketballData)

## Data Setup~Neil Seward
1.To unzip the 7z file run this command
```
cd data
sudo ./setup.sh
```

## Additional Data Conversions~Neil Seward
1. Additional scripts are provided. To complete these steps, add your project directory to the constant.py file in the movement package.
```py 
import os
# change this data_dir for personal path
if os.environ['HOME'] == '/home/neil':
    data_dir = '/home/neil/projects/nba-movement-data'
else:
    raise Exception("Unspecified data_dir, unknown environment")
```


2. Install the user package. You may need to run this in sudo.
```
python setup.py build
python setup.py install
```

3. Convert the JSON files.
```
python movement/json_to_csv.py
```

4. Convert the full-court to half-court. An explanation of moving the SportVU movement can be found [here](https://github.com/sealneaward/movement-quadrants).
```
python movement/convert_movement.py
```

5. The fixed shot times, along with the shot locations in half court space are in `data/shots/fixed_shots.csv`. They are formed from executing the script.
```
python fix_shot_times.py
```

# Using Data to Evaluate Player Actions Values with a Deep Q-Network ~ Kyle Naddeo
Information of the methods and background can be found in "Predicting Basketball Players Action Values with a DQN" pdf


1. Run the generate_features.py file to format the data in a way to be feed to the DQN
2. Run the Roboballer_DQN.py file to train an agent to learn the strategy of basketball
