library(tidyverse)
library(caret)
library(kableExtra)


tr<-read.csv("BDB_22/key_event_total_tracking.csv")
tracking_tacklers<-read.csv("BDB_22/data/tackler_tracking_2020.csv")
players<-read.csv("players.csv")
snap_pred<-read.csv("BDB_22/gunner_snap_tackle_prob.csv")

### ball distance ##
ball_distance<-read_csv("BDB_22/ball_distance_pred.csv")

return_prob<-read_csv("BDB_22/return_yards_pred.csv")

tracking<-read.csv("tracking2020_prepped.csv")


### adjust tacklers ###
tracking_tacklers<-tracking_tacklers %>%
  group_by(gameId,playId,nflId) %>%
  summarize(Tackler = mean(Tackler),
            AssistTackler = mean(AssistTackler),
            MissedTackler = mean(MissedTackler))

#frame events
frame_events<-tracking %>%
  filter(role == "Gunner") %>%
  select(gameId,playId,nflId,frameId,event)

#### gunners with highest average tackle prod ###

tr<-tr %>%
  mutate(lag_pred = lag(pred),
         pred_added = pred - lag(pred)) %>%
  rename(nflId  = nflId1) %>%
  left_join(snap_pred,by=c("gameId","playId","nflId")) %>%
  rename(pred = pred.x,
         snap_pred = pred.y,
         frameId = frameId.x,
         snapId = frameId.y) %>%
  left_join(frame_events,tr,by=c("gameId","playId","nflId","frameId"))


#### delta between pred at first key event and snap prediction ####

key_tr<-tr %>%
  filter(event %in% c('fair_catch','punt_land','punt_downed',
                      'punt_received','first_contact','out_of_bounds','tackle',
                      'punt_muffed')) %>%
  group_by(gameId,playId,nflId) %>%
  summarize(frameId = min(frameId)) %>%
  left_join(tr,by=c("gameId","playId","nflId","frameId")) %>%
  select(gameId,playId,nflId,frameId,event,snap_pred,pred,ball_land_dis_from_los,ball_land_dis_from_player) %>%
  mutate(pred_added = pred - snap_pred)


key_tr_sub<-key_tr %>%
  select(gameId,playId,nflId,frameId) %>%
  rename(key_event_frameId = frameId)

return_prob<-return_prob %>%
  select(gameId,playId,nflId,frameId,return_yds,return_yards_pred)

ball_distance<-ball_distance %>%
  select(gameId,playId,nflId,frameId,key_event_ball_land_dis_from_player,ball_distance_pred)

tr<-tr %>%
  left_join(key_tr_sub,tr,by=c("gameId","playId","nflId")) %>%
  mutate(in_range = ifelse(frameId >= snapId & key_event_frameId >= frameId,TRUE,FALSE))

tr<-tr %>%
  left_join(ball_distance,by=c("gameId","playId","nflId","frameId")) %>%
  left_join(return_prob,by=c("gameId","playId","nflId","frameId"))

tr<-tr %>%
  mutate(distance_under = ball_land_dis_from_player - ball_distance_pred,
         return_yds_under = return_yds - return_yards_pred)


### tpa & average tp ###
tpa<-tr %>%
  group_by(gameId,playId,nflId) %>%
  filter(in_range == TRUE) %>%
  summarize(
    mean_pred_added = mean(pred_added,na.rm = T),
    total_mean_added = sum(pred_added),
    pred_added_sd = sd(pred_added),
    mean_pred = mean(pred,na.rm = T),
    vises_snap_sep = mean(closest_receiving_vises_snap_separation,na.rm = T),
    receiving_snap_sep = mean(closest_receiving_snap_separation,na.rm = T),
    punting_snap_sep = mean(closest_punting_snap_separation,na.rm = T),
    dis = sum(sum_dis),
    var_x = mean(var_x),
    var_s = mean(var_s),
    var_s_theta = mean(var_s_theta),
    Vises = mean(Vises),
    s = mean(s),
    closest_receiving_vises_separation = mean(closest_receiving_vises_separation),
    distance_under = mean(distance_under,na.rm = T),
    return_yds_under = mean(return_yds_under,na.rm = T)
  )



max_speed<-tracking %>%
  filter(role == "Gunner") %>%
  group_by(gameId,playId,nflId,team_name) %>%
  summarize(max_speed = max(s,na.rm = T),
            max_accel = max(a,na.rm = T)) 






### summary gunner - stats #### 
summary_stats<-key_tr %>%
  left_join(tpa,by=c("gameId","playId","nflId")) %>%
  left_join(tracking_tacklers,by=c("gameId","playId","nflId")) %>%
  left_join(players,summary_stats,by=c("nflId")) %>%
  left_join(max_speed,by=c("gameId","playId","nflId"))

summary_stats<-summary_stats %>%
  mutate(fc = ifelse(event == "fair_catch",1,0),
         pr = ifelse(event == "punt_received",1,0),
         non_fc_RYUE = ifelse(event != "fair_catch",return_yds_under,NA),
         tackleOpp = ifelse(Tackler + AssistTackler + MissedTackler > 0,1,0))


####### NOW EVALUATE #######
top_players<-summary_stats %>%
  mutate(fc = ifelse(event == "fair_catch",1,0),
         pr = ifelse(event == "punt_received",1,0),
         non_fc_RYUE = ifelse(event != "fair_catch",return_yds_under,NA),
         tackleOpp = ifelse(Tackler + AssistTackler + MissedTackler > 0,1,0)) %>%
  group_by(displayName,Position) %>%
  summarize(punts = n(),
            `fair catch` = sum(fc),
            `punt received` = sum(pr),
            `avg. speed` = round(mean(s,na.rm = T),2),
            `speed variance` = round(mean(var_s,na.rm = T),2),
            #`direction variance` = round(mean(var_dir_x,na.rm = T),2),
            `avg. vise separation` = round(mean(closest_receiving_vises_separation,na.rm = T),2),
            `tpa` = round(mean(pred_added,na.rm = T),2),
            `tp mean` = round(mean(mean_pred,na.rm = T),2),
            `dist. from ball land` = round(mean(ball_land_dis_from_player,na.rm = T),2),
            `Tackle Opp.` = sum(tackleOpp),
            `DtBUE` = round(mean(distance_under,na.rm = T),2),
            `RYUE` = round(mean(return_yds_under,na.rm = T),2),
            `RYUE (Non Fair catch)` = round(mean(non_fc_RYUE,na.rm = T),2)) %>%
  filter(punts >= 40) %>%
  arrange(desc(`Tackle Opp.`))  %>%
  rename(name = displayName,
         pos = Position) 
#%>%
#  kable() %>%
#  kable_styling(font_size = 10)

write.csv(summary_stats,"summary_stats.csv")







### look at tackle percentage probability over expected? 
#### filter for expected tackles




