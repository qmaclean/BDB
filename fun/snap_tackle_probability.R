library(tidyverse)
library(zoo)
library(caret)

tracking<-read.csv("tracking2020_prepped.csv")

tracking<-tracking %>% filter(event %in% c('ball_snap'))

### add in football ball metrics for distance from ball 
football<-tracking %>%
  filter(team == "football") %>%
  select(gameId,playId,frameId,x)


tracking<-tracking %>%
  left_join(football,tracking,by=c("gameId","playId","frameId"))

tracking<-tracking %>%
  rename(x = x.x,
         ball_x = x.y)

tracking<-tracking %>%
  select(-ball_land_x,-ball_land_y)

#### tacklers #####
tracking_tacklers<-read.csv("BDB_22/data/tackler_tracking_2020.csv")

tacklers<-tracking_tacklers %>%
  select(gameId,playId,nflId,Tackler) %>%
  filter(Tackler == 1) %>%
  distinct()

assist_tacklers<-tracking_tacklers %>%
  select(gameId,playId,nflId,AssistTackler) %>%
  filter(AssistTackler == 1) %>%
  distinct()

missed_tacklers<-tracking_tacklers %>%
  select(gameId,playId,nflId,MissedTackler) %>%
  filter(MissedTackler == 1) %>%
  distinct()

tracking<-tracking %>%
  left_join(tacklers,tracking,by=c("gameId","playId","nflId"))

tracking<-tracking %>%
  left_join(assist_tacklers,tracking,by=c("gameId","playId","nflId"))

tracking<-tracking %>%
  left_join(missed_tacklers,tr,by=c("gameId","playId","nflId"))

tracking<-tracking %>%
  mutate(Tackler = ifelse(is.na(Tackler),0,1),
         AssistTackler = ifelse(is.na(AssistTackler),0,1),
         MissedTackler = ifelse(is.na(MissedTackler),0,1))

tracking$TackleOpp<-tracking$Tackler + tracking$AssistTackler + tracking$MissedTackler

tracking<-tracking %>%
  select(-Tackler,-AssistTackler,-MissedTackler)

tracking$TackleOpp<-ifelse(tracking$TackleOpp >= 1,"Y","N")


#### join on tackler to get tackle opportunity at end ####

tracking<-tracking %>%
  select(-X,-time,-kickBlockerId,-yardlineSide,-gameClock,-penaltyCodes,-penaltyJerseyNumbers,-penaltyYards,-preSnapHomeScore,-preSnapVisitorScore,
         -passResult,-playResult,-snapDetail,-kickType,-kickDirectionActual,-kickDirectionIntended,-returnDirectionIntended,-returnDirectionActual,
         -missedTackler,-assistTackler,-tackler,-kickoffReturnFormation,-kickContactType,-gameTimeEastern,-height,-weight,-birthDate,
         -collegeName,-Position,-Punt.Rusher,-ST.Safeties,-to_left,-o_radians)

rm(tracking_tacklers)
rm(tacklers)
rm(assist_tacklers)
rm(missed_tacklers)
rm(football)

bdb_get_vars_punt_snap <- function(df_tracking){
  df_tracking_list <- df_tracking %>%
    group_split(week) # split data by week to save memory
  
  print('Starting Loop')
  
  df_tracking_vars <- {}
  for(i in 1:length(df_tracking_list)){
    start_time <- Sys.time()
    
    df_tracking_vars[[i]] <- df_tracking_list[[i]] %>%
      select(playId, gameId, frameId, nflId, x, y, role,
             punting_team,receiving_team, team_name, team, snap, punt,dir_x, dir_y, s_theta, dir, o, s, dis, s_x,s_y, a,a_x,a_y,
             los_x, los_y,pre_play,in_play,post_play,Gunner,Vises,ball_x) %>%
      # join with play data
      inner_join(df_tracking_list[[i]] %>%
                   select(playId, gameId, frameId, nflId, x, y, punting_team, receiving_team, team_name,team,
                          role, s_theta), by = c('playId', 'gameId', 'frameId')) %>% # join with tracking data to see interactions between players
      rename_at(vars(contains('.x')), function(x) gsub('\\.x', '1', x)) %>% # rename vars in df_tracking 1 to player 1
      rename_at(vars(contains('.y')), function(x) gsub('\\.y', '2', x)) %>% # rename vars in df_tracking 2 to player 2
      filter(team1 != 'football' & team2 != 'football') %>% # filter out football
      group_by(gameId, playId, nflId1, nflId2) %>%
      dplyr::mutate(snap_x = ifelse(snap == 1,x1,NA), # x coord of player 1 at snap
                    snap_y = ifelse(snap == 1,y1,NA),# y coord of player 1 at snap
                    punt_x = ifelse(punt == 1,x1,NA),  # x coord of player 1 at punt kick
                    punt_y = ifelse(punt == 1,y1,NA),  # y coord of player 1 at punt kick
                    ball_land_x = ball_x,
                    x1 = x1,
                    y1 = y1,
                    #var_x = var(x1),
                    dir_x = dir_x, 
                    s_theta = s_theta1, 
                    s = s, 
                    dis = dis,
                    punt_dis_from_los = punt_x - los_x,
                    ball_land_dis_from_los = ball_x - los_x,
                    ball_land_dis_from_player = ball_x - x1,
                    separation = sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2),
                    avg_sep = mean(separation[in_play == 1], na.rm = TRUE),
                    snap_separation = ifelse(snap == 1,separation,NA),
                    punt_separation = ifelse(punt == 1,separation,NA),
                    same_team = ifelse(punting_team1 == punting_team2,1,0),
                    same_player = ifelse(nflId1 == nflId2,1,0)) %>% 
      ungroup() %>%
      group_by(gameId,playId,nflId1, frameId) %>%
      mutate(closest_punting_player_id = nflId2[separation == min(separation[same_player == 0 & punting_team2 == 1],na.rm = T)][1],
             closest_punting_player_separation = min(separation[same_player == 0 & punting_team2 == 1 & nflId2 == closest_punting_player_id], na.rm = T),
             closest_punting_snap_separation = min(snap_separation[same_player == 0 & punting_team2 == 1],na.rm = T),
             closest_receiving_player_id = nflId2[separation == min(separation[same_player == 0 & receiving_team2 == 1],na.rm=T)][1],
             closest_receiving_player_separation = min(separation[same_player == 0 & receiving_team2 == 1],na.rm=T),
             closest_receiving_vises_separation = min(separation[same_player == 0 & receiving_team2 == 1 & role2 == "Vises"],na.rm=T),
             closest_receiving_vises_snap_separation = min(snap_separation[same_player == 0 & receiving_team2 == 1 & role2 == "Vises"],na.rm=T),
             closest_receiving_snap_separation = min(snap_separation[same_player == 0 & receiving_team2 == 1],na.rm = T),
             closest_vises_separation_snap_id = nflId2[separation == min(snap_separation[same_player == 0 & receiving_team2 == 1 & role2 == "Vises"],na.rm = T)][1],
             role1 = role1[1],
             Vises = Vises[1]) %>%
      filter(punting_team1 == 1 & !is.na(closest_receiving_player_separation) & same_player == 0) %>%
      group_by(gameId,playId,nflId1,frameId) %>%
      arrange(gameId,playId,nflId1,frameId) %>%
      summarize(
        x = mean(x1),
        y = mean(y1),
        dir_x = mean(dir_x),
        s_theta = mean(s_theta1),
        s = mean(s),
        dis = mean(dis),
        punt_dis_from_los = mean(punt_dis_from_los),
        ball_land_dis_from_los = mean(ball_land_dis_from_los),
        ball_land_dis_from_player = mean(ball_land_dis_from_player),
        closest_punting_player_separation = mean(closest_punting_player_separation[is.finite(closest_punting_player_separation)]),
        closest_punting_snap_separation = mean(closest_punting_snap_separation[is.finite(closest_punting_snap_separation)]),
        closest_receiving_vises_separation = mean(closest_receiving_vises_separation[is.finite(closest_receiving_vises_separation)]),
        closest_receiving_vises_snap_separation = mean(closest_receiving_vises_snap_separation[is.finite(closest_receiving_vises_snap_separation)]),
        closest_receiving_snap_separation = mean(closest_receiving_snap_separation[is.finite(closest_receiving_snap_separation)]),
        Vises = Vises[1],
        role = role1[1]
      ) %>%  #### figure out rolling mean & variance
      mutate(
        var_x = rollapply(x,5,var,align="left",fill=NA),
        var_dir_x = rollapply(dir_x,5,var,align="left",fill=NA),
        var_s_theta = rollapply(s_theta,5,var,align="left",fill=NA),
        var_s = rollapply(s,5,var,align="left",fill=NA),
        sum_dis = rollapply(dis,5,sum,align="left",fill=NA)
        ### sum of 5
      ) %>%
      distinct() %>%
      fill(names(.), .direction = "down") 
    #dplyr::rename(nflId = nflId1) %>%
    #distinct()
    
    
    #  formula(TackleOpp ~ var_x + var_dir_x + var_s_theta + var_s + sum_dis + punt_dis_from_los + 
    #    ball_land_dis_from_los + ball_land_dis_from_player  + closest_punting_player_separation + 
    #      closest_punting_snap_separation + closest_receiving_vises_separation + closest_receiving_vises_snap_separation + 
    #      closest_receiving_snap_separation  + Vises 
    
    
    
    ### take care of infinite numbers 
    
    end_time <- Sys.time()
    print(paste('Took', round(end_time - start_time, 2), 'minutes for week', i))
  }
  
  df_tracking_vars <- do.call('rbind', df_tracking_vars)
  
  return(df_tracking_vars)
}

tr<-bdb_get_vars_punt_snap(tracking)

tr<-tr %>%
  filter(role == "Gunner")

punt_snap_sep<-tr %>%
  filter(!is.na(closest_punting_snap_separation),
         !is.na(closest_receiving_snap_separation),
         !is.na(closest_receiving_vises_snap_separation)) %>%
  group_by(gameId,playId,nflId1) %>%
  summarize(closest_punting_snap_separation = mean(closest_punting_snap_separation),
            closest_receiving_snap_separation = mean(closest_receiving_snap_separation),
            closest_receiving_vises_snap_separation = mean(closest_receiving_vises_snap_separation))

tr<-tr %>%
  select(-closest_punting_snap_separation,-closest_receiving_snap_separation,-closest_receiving_vises_snap_separation)

tr<-tr %>%
  left_join(punt_snap_sep,tr,by=c("gameId","playId","nflId1"))

rm(punt_snap_sep)

## read model 
tackleOpp_model<-readRDS("GBM_lite.rds")

tr$pred<-predict(tackleOpp_model$finalModel,tr,type="response",n.trees=tackleOpp_model$bestTune$n.trees)

pred<-tr %>%
  select(gameId,playId,nflId1,frameId,pred)

pred<-pred %>%
  rename(nflId = nflId1)

#sample<-sample %>%
 # left_join(pred,sample,by=c("gameId","playId","nflId","frameId"))

write.csv(pred,"gunner_snap_tackle_prob.csv")



