
# Import Data
#---------------------------------------------------------------------#
setwd("E:/Roboballer/nba-movement-data/data/converted")
data = read.csv(file="0021500001_converted.csv") # Position Data
setwd("E:/Roboballer/nba-movement-data/data/events")
events = read.csv(file = "0021500001.csv") # Events Data
#---------------------------------------------------------------------#

# Find Names
#------------------------------------------------------------------------------------------------------------#
data_ids = as.data.frame(unique(data$player_id)[seq(2,length(unique(data$player_id)))])
data_ids = rename(data_ids,"Player_Id" = colnames(data_ids)[1])

data_ids$Player_Name = rep(NA,nrow(data_ids))

for (i in seq(nrow(data_ids))){
    data_ids$Player_Name[i] = toString(events[events$PLAYER1_ID == data_ids$Player_Id[i],]$PLAYER1_NAME[1])
    
}
#------------------------------------------------------------------------------------------------------------#


# Save Data
#---------------------------------------------------------------------#
setwd("E:/Roboballer/nba-movement-data/data/names")
write.csv(data_ids,file = "0021500001_names_Test.csv")
#---------------------------------------------------------------------#





