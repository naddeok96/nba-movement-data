
# Imports
#------------------#
library(dplyr)
library(tidyr)
library(tictoc)
library(dlookr)
library(magrittr)
library(prodlim)
library(BBmisc)
#------------------#

# Read in Data
#------------------------------------------------------------------#
setwd("E:/Roboballer/nba-movement-data/data/converted")
data = read.csv(file="0021500001_converted.csv") # Position Data
setwd("E:/Roboballer/nba-movement-data/data/events")
events = read.csv(file = "0021500001.csv") # Events Data
setwd("E:/Roboballer/nba-movement-data/data/names")
attr_data = read.csv("0021500001_names.csv")
#-----------------------------------------------------------------#

# Remove all Non-Gameplay
#-------------------------------------------------------------------------------#
data = data[!is.na(data$shot_clock),] # Remove NA Shot Clocks
data = data[with(data,order(data$quarter,-data$game_clock)),] # Reorder Data

num_obs = count(data,team_id)%>% # Count Number of Instances
    filter(team_id == -1)%>%
    as.data.frame()

data$GP_Indicator = rep(0,nrow(data)) # Make an Indicator Col

j = 0
for (i in seq(num_obs[,2] -1)) { # Make Indicator 1 if Shot Clock is Not On  
    j = 11*(i-1) + 1
    
    if (data[j,"shot_clock"] == data[j + 11,"shot_clock"]){
        data$GP_Indicator[seq(j,j+10)] = 1
    }
}

data = data[!(data$GP_Indicator == 1),] #Delete Indicated
#-------------------------------------------------------------------------------#

# Count Plays
#------------------------------------------------------------------------------#
num_obs = count(data,team_id)%>%
    filter(team_id == -1)%>%
    as.data.frame()

data$Play_Number = rep(0,nrow(data)) # Make a new column

Play = 1
shift = 0
last_index = 0
i = 1
j = 0
j = 11*(i - 1) + 1 + shift
while(j < nrow(data)){ 
    
    if(data[j,"player_id"] != -1){
        shift = shift + 1
        while(data[11*(i - 1) + 1 + shift,"player_id"] != -1){
            shift = shift + 1 
        }
        j = 11*(i - 1) + 1 + shift
    }
    
    if(data[j,"player_id"] != -1){
        stop("There is a incomplete instance in the Count Plays section")
    }
    
    if (j > last_index){
        down = 0
        
        if (j + 11 < nrow(data)){
            while(data[j + (down*11),"shot_clock"] > data[j + (down*11) + 11,"shot_clock"]){
                down = down + 1
            }
        }
        
        data$Play_Number[seq(j, j + (down*11) + 10)] = Play
        
        last_index = j + (down*11)
        
        Play = Play + 1
    }
    
    i = i + 1
    j = 11*(i - 1) + 1 + shift
}

data = data[!(data$Play_Number == 0),] #Delete Indicated
num_plays = count(data,Play_Number)
#------------------------------------------------------------------------------#

# Merge In Event Types and Remove Non-Reward Plays
#-----------------------------------------------------------------------------------------#
data$event_type = rep(NA,nrow(data)) # Add New Column For Event Type

for (i in seq(nrow(data))){
    if (identical(events[events$EVENTNUM == data$event_id[i], "EVENTMSGTYPE"], integer(0))){
        
        data$event_type[i] = NA
        
    } else {
        
        data$event_type[i] = events[events$EVENTNUM == data$event_id[i], "EVENTMSGTYPE"]
        
    }
}

data$Event_Indicator = rep(0,nrow(data)) # Make an Indicator Col

for (i in seq(nrow(num_plays))) { 
    
    play_of_interest = data[data$Play_Number == i, ]
    last_instance_of_play = nrow(play_of_interest)
    
    if(is.na(play_of_interest[last_instance_of_play,"event_type"]) || 
       (!(play_of_interest[last_instance_of_play,"event_type"] %in% c(1,2,4,5)))){
        
        data[data$Play_Number == i, "Event_Indicator"] = 1
    }
}

data = data[!(data$Event_Indicator == 1),]%>% #Delete Indicated
    select(-c("GP_Indicator", "Event_Indicator"))
#-----------------------------------------------------------------------------------------#

# Find Team with Possession
#------------------------------------------------------------------------------#
plays = unique(data$Play_Number)

team1 = unique(data$team_id)[2]
team2 = unique(data$team_id)[3]

data$Team_w_Possession = rep(0,nrow(data))

for (i in seq(length(plays) - 1)){
    team1_tally = 0
    team2_tally = 0
    
    poi = data[data$Play_Number == plays[i],]%>%
        drop_na()
    
    num_obs = count(poi,team_id)%>%
        filter(team_id == -1)%>%
        as.data.frame()
    
    if(nrow(poi)%%11 == 0 && nrow(poi)/11 == num_obs[,2]){
        
        for (j in seq(num_obs[,2])){
            j_converted = 11*(j-1) + 1
            ioi = poi[seq(j_converted,j_converted + 10),]
            
            distance = rep(0,10) 
            ball_loc = as.numeric(ioi[1,c("x_loc","y_loc")])
            for (k in seq(10)){
                player_loc = as.numeric(ioi[1 + k, c("x_loc","y_loc")])
                
                distance[k] = as.numeric(dist(rbind(ball_loc,player_loc)))
            }
            
            if (ioi[which.min(distance) + 1,"team_id"] == team1){
                
                team1_tally = team1_tally + 1
                
            }else if (ioi[which.min(distance) + 1,"team_id"] == team2){
                
                team2_tally = team2_tally + 1
                
            }else {
                stop("There are more than two teams")
            }
        }
        
        if(team1_tally > team2_tally){
            
            data$Team_w_Possession[data$Play_Number == plays[i]] = team1
        }else{
            
            data$Team_w_Possession[data$Play_Number == plays[i]] = team2
        }
    }else{
        
        data$Team_w_Possession[data$Play_Number == plays[i]] = NA
    }
}

data = filter(data,Team_w_Possession %in% c(team1,team2))
data = data[!is.na(data$event_type),]
#------------------------------------------------------------------------------#

# Filter Out Short Plays
#------------------------------------------------------------------------------#
High_Play_Counts = count(data,Play_Number)%>%
    filter(n > 100)%>%
    select(Play_Number)%>%
    sapply(as.numeric)%>%
    as.matrix()

data = filter(data,Play_Number %in% High_Play_Counts)
#------------------------------------------------------------------------------#

# Find Player with Possession
#------------------------------------------------------------------------------#
plays = unique(data$Play_Number)
data$Distance_to_ball = rep(0,nrow(data))
data$X_Vel  = rep(0,nrow(data))
data$Y_Vel  = rep(0,nrow(data))
data$Velocity_of_TwP  = rep(0,nrow(data))
data$Player_w_Possesion = rep(0,nrow(data))
data$Action = rep(0,nrow(data))

for (i in seq(length(plays) - 1)){ # For Every Play
    poi = data[data$Play_Number == plays[i],]%>% # Choose a play of interest (poi)
        drop_na()%>%
        filter(team_id %in% c(unique(Team_w_Possession), -1)) 
    
    poi_def = data[data$Play_Number == plays[i],]%>% # Choose a play of interest (poi)
        drop_na()%>%
        filter(team_id != unique(Team_w_Possession))
    
    num_obs = count(poi,team_id)%>% # Find number of observations in that play
        filter(team_id == -1)%>%
        as.data.frame()
    
    possession_data = as.data.frame(cbind(rep(0,num_obs[,2]), # Make a blank data set
                                          rep(0,num_obs[,2]),
                                          rep(0,num_obs[,2]),
                                          rep(0,num_obs[,2]),
                                          rep(0,num_obs[,2]),
                                          rep(0,num_obs[,2])))
    colnames(possession_data) = c("Shot_Clock","Closest_Player","Closest_Player_Dist","Velocity_of_Player","Velocity_of_Ball","Action")
    
    for (j in seq(num_obs[,2])){ # For every instances in the play
        j_converted = 6*(j-1) + 1
        
        
        if(j != 1){ # Find Velocity of Players
            ioi0_def = ioi_def
            ioi_def = poi_def[seq(j_converted,j_converted + 5),]
            
            x_vel_def = (ioi_def[,"x_loc"] - ioi0_def[,"x_loc"])/abs((ioi_def[,"shot_clock"] - ioi0_def[,"shot_clock"]))
            y_vel_def = (ioi_def[,"y_loc"] - ioi0_def[,"y_loc"])/abs((ioi_def[,"shot_clock"] - ioi0_def[,"shot_clock"]))
            
            ioi_def$X_Vel = x_vel_def
            ioi_def$Y_Vel = y_vel_def
            ioi_def$Velocity_of_TwP = sqrt((x_vel_def^2)+(y_vel_def^2))
            
            
            ioi0 = ioi
            ioi = poi[seq(j_converted,j_converted + 5),]
            
            x_vel = (ioi[,"x_loc"] - ioi0[,"x_loc"])/abs((ioi[,"shot_clock"] - ioi0[,"shot_clock"]))
            y_vel = (ioi[,"y_loc"] - ioi0[,"y_loc"])/abs((ioi[,"shot_clock"] - ioi0[,"shot_clock"]))
            
            ioi$X_Vel = x_vel
            ioi$Y_Vel = y_vel
            ioi$Velocity_of_TwP = sqrt((x_vel^2)+(y_vel^2))
            
        }else{
            
            ioi = poi[seq(j_converted,j_converted + 5),]
            ioi_def = poi_def[seq(j_converted,j_converted + 5),]
        }
        
        ioi$Distance_to_ball[1] = -1 
        ball_loc = as.numeric(ioi[1,c("x_loc","y_loc")])
        
        for (k in seq(5)){ # Find distances of each player
            player_loc_def = as.numeric(ioi_def[1 + k, c("x_loc","y_loc")])
            
            ioi_def$Distance_to_ball[1 + k] = as.numeric(dist(rbind(ball_loc,player_loc_def)))
            
            
            player_loc = as.numeric(ioi[1 + k, c("x_loc","y_loc")])
            
            ioi$Distance_to_ball[1 + k] = as.numeric(dist(rbind(ball_loc,player_loc)))
        }
        
        possession_data[j,] = cbind(unique(ioi$shot_clock), # Shot Clock
                                    which.min(ioi$Distance_to_ball[seq(2,nrow(ioi))]), # closest Player
                                    min(ioi$Distance_to_ball[seq(2,nrow(ioi))]), # Distance to Ball
                                    ioi$Velocity_of_TwP[which.min(ioi$Distance_to_ball[seq(2,nrow(ioi))]) + 1], # Velocity of Player
                                    ioi$Velocity_of_TwP[1],# Velocity of Ball
                                    0) # Action
        
        
        poi[seq(j_converted,j_converted + 5),]  = ioi
        poi_def[seq(j_converted,j_converted + 5),]  = ioi_def
        
    }
    
    for (m in seq(nrow(possession_data) - 2)){ # Look at every transition
        m = m + 1
        
        if (possession_data$Closest_Player[m] != possession_data$Closest_Player[m + 1]){
            up = 0
            down = 0
            
            while ((mean(possession_data$Velocity_of_Ball[seq(m - up, m - up - 2 )]) > 100 || possession_data$Velocity_of_Ball[m - up] > 100) && (m - up - 2 > 2)  ){
                
                up = up + 1 
            }
            while ((mean(possession_data$Velocity_of_Ball[seq(m + down, m + down + 2 )]) > 100 || possession_data$Velocity_of_Ball[m + down] > 100) && (m + down + 2 < nrow(possession_data))){
                
                down = down + 1
            }
            
            coi = possession_data[seq(m - up, m + down),]
            
            if (as(names(which.max(table(poi[poi$shot_clock == coi$Shot_Clock[nrow(coi)],"event_type"]))),mode(poi[poi$shot_clock == coi$Shot_Clock[nrow(coi)],"event_type"])) %in% c(1,2)){
                
                possession_data[seq(m - up - 1, m + down),"Action"] = 6
                possession_data[seq(m - up, m + down),"Closest_Player"] = 0
                
            }else{
                possession_data[seq(m - up - 1, m + down),"Action"] = which(ioi[order(ioi$Distance_to_ball),]$player_id == ioi$player_id[coi$Closest_Player[nrow(coi)] + 1])
                possession_data[seq(m - up, m + down),"Closest_Player"] = 0
            }
            
            
        }
        
    }
    
    for (n in seq(unique(poi$shot_clock))){
        shotclock = unique(poi$shot_clock)[n]
        
        poi[poi$shot_clock == shotclock,"Player_w_Possesion"] = possession_data[possession_data$Shot_Clock == shotclock,"Closest_Player"]
        poi[poi$shot_clock == shotclock,"Action"] = possession_data[possession_data$Shot_Clock == shotclock,"Action"]
    }
    
    poi_def = filter(poi_def,player_id != -1)
    poi_def = poi_def[order(-poi_def$shot_clock, poi_def$Distance_to_ball),]
    
    poi = poi[order(-poi$shot_clock, poi$Distance_to_ball),]
    
    num_obs = count(poi,team_id)%>% # Find number of observations in that play
        filter(team_id == -1)%>%
        as.data.frame()
    
    
    combined_poi = data[data$Play_Number == plays[i],]%>% # Choose a play of interest (poi)
        drop_na()
    
    for (p in seq(num_obs[,2])){ # For every instances in the play
        j_poi = 6*(p-1) + 1
        j_def = 5*(p-1) + 1
        j_com = 11*(p-1) + 1
        
        combined_poi[seq(j_com,j_com + 10),] = rbind(poi[seq(j_poi,j_poi + 5),],poi_def[seq(j_def,j_def + 4),])
        
    }
    
    data[data$Play_Number == plays[i],] = combined_poi
}
#-----------------------------------------------------------------------------------------------------------------#

# Add in Attributes
#------------------------------------------------------------------------------------------------------------------#
data$Player_Off_Attr = rep(0,nrow(data)) # Make a new column
players = unique(data$player_id)[seq(2,length(unique(data$player_id)))]

for (i in seq(length(players))){
    data[data$player_id == players[i],"Player_Off_Attr"] = attr_data[attr_data$Player_Id == players[i],"Attribute"]
}
#------------------------------------------------------------------------------------------------------------------#

# Create Blank Final Data Frame
#------------------------------------------------------------------------------------------------------------------#
num_obs = count(data,team_id)%>%
    filter(team_id == -1)%>%
    as.data.frame()

final = data.frame(matrix(ncol = 63, nrow = num_obs[,2]))

name_game_properties = c("Play_Number","Event_Type","Game_Clock","Shot_Clock","Ball_Loc_X","Ball_Loc_Y","Action","Reward")

for (i in seq(5)){
    if(i == 1){
        name_offense = c(sprintf("O%s_Dist",i),sprintf("O%s_Loc_X",i),
                         sprintf("O%s_Loc_Y",i),sprintf("O%s_Vel_X",i),
                         sprintf("O%s_Vel_Y",i),sprintf("O%s_Attr",i))
        name_defense = c(sprintf("D%s_Dist",i),sprintf("D%s_Loc_X",i),
                         sprintf("D%s_Loc_Y",i),sprintf("D%s_Vel_X",i),
                         sprintf("D%s_Vel_Y",i))
        
    }else{
        name_offense = c(name_offense,c(sprintf("O%s_Dist",i),sprintf("O%s_Loc_X",i),
                                        sprintf("O%s_Loc_Y",i),sprintf("O%s_Vel_X",i),
                                        sprintf("O%s_Vel_Y",i),sprintf("O%s_Attr",i)))
        
        name_defense = c(name_defense,c(sprintf("D%s_Dist",i),sprintf("D%s_Loc_X",i),
                                        sprintf("D%s_Loc_Y",i),sprintf("D%s_Vel_X",i),
                                        sprintf("D%s_Vel_Y",i)))
    }
}


colnames(final) = c(name_game_properties,name_offense,name_defense)
#------------------------------------------------------------------------------------------------------------------#

# Populate Final Data Frame
#------------------------------------------------------------------------------------------------------------------#
num_obs = count(data,team_id)%>%
    filter(team_id == -1)%>%
    as.data.frame()

for (i in seq(num_obs[,2])){
    j = 11*(i-1) + 1
    
    game_properties = c(data$Play_Number[j],data$event_type[j], data$game_clock[j],data$shot_clock[j],data$x_loc[j],data$y_loc[j],data$Action[j],0)
    
    for (k in seq(10)){
        if(k == 1){
            
            player_properties = c(data$Distance_to_ball[j+k],data$x_loc[j+k],data$y_loc[j+k],data$X_Vel[j+k],data$Y_Vel[j+k],data$Player_Off_Attr[j+k])
        }else if (k <= 5){
            
            player_properties = c(player_properties,c(data$Distance_to_ball[j+k],data$x_loc[j+k],data$y_loc[j+k],data$X_Vel[j+k],data$Y_Vel[j+k],data$Player_Off_Attr[j+k]))
        }else{
            
            player_properties = c(player_properties,c(data$Distance_to_ball[j+k],data$x_loc[j+k],data$y_loc[j+k],data$X_Vel[j+k],data$Y_Vel[j+k]))
        }
        
    }
    
    final[i,] = c(game_properties,player_properties)
}


final = final[final$O1_Vel_X != 0,]
#------------------------------------------------------------------------------------------------------------------#

# Assign States
#------------------------------------------------------------------------------------------------------------------#
states = final%>%
    select(-c(Play_Number,Event_Type,Action,Reward))

num_bins = 25

bin = function(x){
    if(length(unique(x)) > num_bins){
        
        y = as.numeric(binning(x,nbins = num_bins, type = "equal", labels = seq(num_bins)))
        nas = which(is.na(y))
        if(length(nas) != 0 ){
            for (i in seq(length(nas))){
                y[nas[i]] = y[nas[i]-1]
            }
        }
    }else{
        
        y = as.numeric(binning(x,nbins = length(unique(x)), type = "equal", labels = seq(length(unique(x)))))
        nas = which(is.na(y))
        if(length(nas) != 0 ){
            for (i in seq(length(nas))){
                y[nas[i]] = y[nas[i]-1]
            }
        }
    }
    return(y)
}

states = suppressWarnings(apply(states,2,bin))%>%
    as.data.frame()

assignState = function(x){
    x$State = rep(0,nrow(x))
    y = unique(x[duplicated(x),])
    y$State = seq(nrow(y))
    
    for(i in seq(nrow(y))){
        x[which(!is.na(row.match(x[,1:ncol(x)-1],y[i,1:ncol(y)-1]))),"State"] = y$State[i]
    }
    
    x[x$State == 0,"State"] = seq(nrow(y) + 1, nrow(x[x$State == 0,]) + nrow(y))
    return(x)
}

states = assignState(states)%>%
    select(State)

final$State = states
#------------------------------------------------------------------------------------------------------------------#

# Assign Rewards
#------------------------------------------------------------------------------------------------------------------#
plays = unique(final$Play_Number)
et = data.frame(matrix(ncol = 2, nrow = nrow(unique(final$State))))
et$State = unique(final$State)[ordered(unique(final$State)$State),]
et$etrace = rep(0,nrow(et))
et %<>% select(State,etrace)
final$Indicator = rep(0,nrow(final))

for (i in seq(length(plays))){ # For every play
    
    poi = final[final$Play_Number == plays[i],]
    
    if(poi$Event_Type[nrow(poi)] %in% c(1,2,4,5)){
        
        
        reward = switch(as.character(poi$Event_Type[nrow(poi)]),
                        "1" = 10,
                        "2" = 5,
                        "4" = 5,
                        "5" = -5)
        
        for(j in seq(nrow(poi))){
            et[et$State == poi$State[j,1],"etrace"] = et[et$State == poi$State[j,1],"etrace"] + 1
            
            et$etrace = 0.9*et$etrac
        }
        
        for(j in seq(nrow(et))){
            poi[poi$State[,1] == et$State[j],"Reward"] = reward * et$etrace[j]
        }
        
        final[final$Play_Number == plays[i],"Reward"] = poi$Reward
    }else{
        
        final[final$Play_Number == plays[i],"Indicator"] = 1
    }
}
#------------------------------------------------------------------------------------------------------------------#

# Remove Non-Possessions, Play Numbers, Event Types and State
#------------------------------------------------------------------------------------------------------------------#
for (i in seq(nrow(final))){
    if(i != 1){
        if(final$Action[i-1] != 0){
            final$Indicator[i] = 1
        }
    }
}
experiences = final[final$Indicator == 0, ]%>%
    select(-c(Play_Number,Event_Type,State,Indicator))
#------------------------------------------------------------------------------------------------------------------#

# Normalize
#------------------------------------------------------------------------------------------#
experiences[,!names(experiences) %in% c("Action", "Reward")] %<>% normalize()
#------------------------------------------------------------------------------------------#

# Save the Data
#---------------------------------------------------------#
setwd("E:/Roboballer/nba-movement-data/data/experiences")
write.csv(experiences, file = "0021500001_experiences.csv")
#---------------------------------------------------------#
