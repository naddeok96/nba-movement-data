# Imports
#--------------------------------------------------#
import keras
from keras.models import Model
from keras.layers import Conv2D, MaxPooling2D
from keras.layers import Flatten, Dense
from keras.layers import Input
from keras.utils import np_utils
from keras.datasets import cifar10
#--------------------------------------------------#

# Hyperparameters
#--------------------------------------------------#
epochs = 100
#--------------------------------------------------#

# Load Data
#--------------------------------------------------#

#--------------------------------------------------#

# Generate Experiences and Shuffle
#--------------------------------------------------#

#--------------------------------------------------#

# Game Properties Network
#--------------------------------------------------#
def gameNet(game_props):
    input_game = Input(shape = (32, 32, 3))

    volume_1 = Conv2D(64, (1,1), padding='same', activation='relu')(input_img)
    
    volume_2 = Conv2D(96, (1,1), padding='same', activation='relu')(input_img)
    volume_2 = Conv2D(128, (3,3), padding='same', activation='relu')(volume_2)
    
    volume_3 = Conv2D(16, (1,1), padding='same', activation='relu')(input_img)
    volume_3 = Conv2D(32, (5,5), padding='same', activation='relu')(volume_3)
    
    volume_4 = MaxPooling2D((3,3), strides=(1,1), padding='same')(input_img)
    volume_4 = Conv2D(32, (1,1), padding='same', activation='relu')(volume_4)
    
    # Concatenate all volumes of the Inception module
    inception_module = keras.layers.concatenate([volume_1, volume_2, volume_3,
                                                 volume_4], axis = 3)
    output = Flatten()(inception_module)
#--------------------------------------------------#

# Offense Player Network
#--------------------------------------------------#

#--------------------------------------------------#

# Defense Player Network
#--------------------------------------------------#

#--------------------------------------------------#

# Team Network
#--------------------------------------------------#

#--------------------------------------------------#

# Final Network
#--------------------------------------------------#

#--------------------------------------------------#

out    = Dense(10, activation='softmax')(output)


model = Model(inputs = input_img, outputs = out)
print(model.summary())

model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])
hist = model.fit(X_train, y_train, validation_data=(X_test, y_test), epochs=epochs, batch_size=512)


scores = model.evaluate(X_test, y_test, verbose=0)
print("Accuracy: %.2f%%" % (scores[1]*100))


