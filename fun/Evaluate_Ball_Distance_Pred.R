library(tidyverse)


### data model read
data_model<-read_csv("BDB_22/ball_distance_pred.csv")


tr<-read.csv("tracking2020_prepped.csv")

event_tr<-tr %>%
  select(gameId,playId,frameId,nflId,event) %>%
  mutate(nflId = as.numeric(nflId))


data_model<-data_model %>%
  left_join(tr,data_model,by=c("gameId","playId","frameId","nflId"))


#### punt_tr #####
data_model$ball_distance_pred

data_model<-data_model %>%
  left_join(players,by=c("nflId"))

data_model$displayName.y


data_model %>%
  filter(punt == 1) %>%
  group_by(nflId,displayName.y) %>%
  summarize(Punts = n(),
            ball_distance_pred = round(mean(ball_distance_pred,na.rm=T),2),
            ball_distance_actual = round(mean(key_event_ball_land_dis_from_player,na.rm = T),2)) %>%
  mutate(distance_over_expected = ball_distance_actual - ball_distance_pred) %>%
  filter(Punts >= 40) %>%
  rename(name = displayName.y) %>%
  dplyr::select(-nflId) %>%
  arrange(distance_over_expected) %>%
  kable() %>%
  kable_styling()


loadRD


