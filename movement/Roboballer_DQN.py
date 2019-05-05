
# Imports
#-----------------------------------------------------#
import os
import pandas as pd
from keras.layers import Dense, Dropout, concatenate
from keras.models import Model
#-----------------------------------------------------#

# Load Experiences
#------------------------------------------------------------#
os.chdir("E:/Roboballer/nba-movement-data/data/experiences")

data = pd.read_csv("0021500001_experiences.csv")
exp = data.drop(data.columns[0],axis=1)
#------------------------------------------------------------#

# Build Player Network
#---------------------------------------------------#
def player(x):
    layer1 = Dense(100, activation = 'relu')(x)
    layer2 = Dropout(0.2)(layer1)
    layer3 = Dense(50, activation = 'relu')(layer2)
    layer4 = Dropout(0.4)(layer3)
    output = Dense(6)(layer4)
    
    return output
#---------------------------------------------------#
    
# Build Team Networks
#----------------------------------------------------------------------#
def teamOff(x):
    input_layer = concatenate([player(x.loc[0,"O1_Dist":"O1_Attr"].tolist()), 
                               player(x.loc[0,"O2_Dist":"O2_Attr"].tolist()),
                               player(x.loc[0,"O3_Dist":"O3_Attr"].tolist()),
                               player(x.loc[0,"O4_Dist":"O4_Attr"].tolist()),
                               player(x.loc[0,"O5_Dist":"O5_Attr"].tolist())],
                               axis = 1)
    
    layer1 = Dense(100, activation = 'relu')(input_layer)
    layer2 = Dropout(0.2)(layer1)
    layer3 = Dense(50, activation = 'relu')(layer2)
    layer4 = Dropout(0.4)(layer3)
    output = Dense(5)(layer4)
    
    return output

def teamDef(x):
    input_layer = concatenate([player(x.loc[0,"D1_Dist":"D1_Vel_Y"].tolist()), 
                               player(x.loc[0,"D2_Dist":"D2_Vel_Y"].tolist()),
                               player(x.loc[0,"D3_Dist":"D3_Vel_Y"].tolist()),
                               player(x.loc[0,"D4_Dist":"D4_Vel_Y"].tolist()),
                               player(x.loc[0,"D5_Dist":"D5_Vel_Y"].tolist())])
    
    layer1 = Dense(100, activation = 'relu')(input_layer)
    layer2 = Dropout(0.2)(layer1)
    layer3 = Dense(50, activation = 'relu')(layer2)
    layer4 = Dropout(0.4)(layer3)
    output = Dense(5)(layer4)
    
    return output
#----------------------------------------------------------------------#
    
# Build DQN Model
#----------------------------------------------------------------------#
def DQN(x):
    game_props    = x.loc[0,"Game_Clock":"Ball_Loc_Y"].tolist()
    offense_props = x.loc[0,"O1_Dist":"O5_Attr"].to_frame().T
    defense_props = x.loc[0,"D1_Dist":"D5_Vel_Y"].to_frame().T
    action        = x.loc[0,"Action"].tolist()
    input_layer = concatenate(game_props,
                              teamOff(offense_props),
                              teamDef(defense_props),
                              action)
    
    layer1 = Dense(100, activation = 'relu')(input_layer)
    layer2 = Dropout(0.2)(layer1)
    layer3 = Dense(100, activation = 'relu')(layer2)
    layer4 = Dropout(0.2)(layer3)
    layer5 = Dense(50,activation = 'relu')(layer4)
    layer6 = Dropout(0.4)(layer5)
    output = Dense(7, activation = 'softmax' )(layer6)
    
    model = Model(inputs = input_layer, outputs = output)
    print(model.summary())
    return output
#----------------------------------------------------------------------#
    
# 
    
DQN(exp.loc[0,].to_frame().T)
