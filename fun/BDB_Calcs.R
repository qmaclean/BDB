

tracking<-read.csv("tracking2020_prepped.csv")

parallelly::availableCores()
future::plan("multisession")



sample<-tracking %>% filter(gameId=="2021010300",playId=="4075")


bdb_get_vars_punt <- function(df_tracking){
  df_tracking_list <- df_tracking %>%
    group_split(week) # split data by week to save memory
  
  print('Starting Loop')
  
  df_tracking_vars <- {}
  for(i in 1:length(df_tracking_list)){
    start_time <- Sys.time()
    
    df_tracking_vars[[i]] <- df_tracking_list[[i]] %>%
      select(playId, gameId, frameId, nflId, x, y, role,
             punting_team,receiving_team, team_name, team, snap, punt, catch, in_play,dir_x, dir_y, s_theta, dir, o, s, dis, s_x,s_y, a,a_x,a_y,
             los_x, los_y,pre_play,in_play,post_play,ball_land_x,ball_land_y,Gunner,Vises,`Punt Rusher`,`ST Safeties`) %>%
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
                    ball_land_x = ball_land_x,
                    ball_land_y = ball_land_y,
                    var_x = var(x1), # variance of x coord
                    var_y = var(y1), # variance of y coord
                    var_dir_x = var(dir_x), # variance in velocity in x-direction
                    var_dir_y = var(dir_y), # variance in velocity in y-direction
                    avg_dir_x = mean(dir_x, na.rm = TRUE), # avg of velocity in x-dir
                    avg_dir_y = mean(dir_y, na.rm = TRUE), # avg of velocity in y-dir
                    var_s_theta = var(s_theta1), # variance in directional velo
                    avg_s_theta = mean(s_theta1, na.rm = TRUE), # avg directional velo
                    var_dir = var(dir), # variance of player direction
                    avg_dir = mean(dir, na.rm = TRUE), # avg player direction
                    var_s = var(s), # variance in speed
                    avg_s = mean(s, na.rm = TRUE), # avg speed
                    sum_dis = sum(dis),
                    pre_play_dis = sum(dis[pre_play == 1]),
                    snap_dis_from_los = snap_x - los_x, 
                    punt_dis_from_los = punt_x - los_x,
                    ball_land_dis_from_los = ball_land_x - los_x,
                    ball_land_dis_from_player = ball_land_x - x1,
                    separation = sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2),
                    avg_sep = mean(separation[in_play == 1], na.rm = TRUE),
                    snap_separation = ifelse(snap == 1,separation,NA),
                    punt_separation = ifelse(punt == 1,separation,NA),
                    same_team = ifelse(punting_team1 == punting_team2,1,0),
                    same_player = ifelse(nflId1 == nflId2,1,0)) %>% # distance travelled
      ungroup() %>%
      group_by(gameId,playId,nflId1, frameId) %>%
      mutate(closest_punting_player_id = nflId2[separation == min(separation[same_player == 0 & punting_team2 == 1],na.rm = T)][1],
             second_closest_punting_player_id = nflId2[separation == min(separation[same_player == 0 & punting_team2 == 1 & nflId2 != closest_punting_player_id],na.rm = T)][1],
             closest_punting_player_separation = min(separation[same_player == 0 & punting_team2 == 1 & nflId2 == closest_punting_player_id], na.rm = T),
             second_closest_punting_player_separation = min(separation[same_player == 0 & punting_team2 == 1], na.rm = T),
             closest_punting_player_dir_diff = s_theta1 - s_theta2[nflId2 == closest_punting_player_id],
             closest_punting_snap_separation = min(snap_separation[same_player == 0 & punting_team2 == 1],na.rm = T),
             closest_punting_punt_separation = min(punt_separation[same_player == 0 & punting_team2 == 1],na.rm = T),
             closest_gunner_separation_snap_id = nflId2[separation == min(snap_separation[same_player == 0 & punting_team2 == 1 & role2 == "Gunner"],na.rm = T)][1],
             closest_receiving_player_id = nflId2[separation == min(separation[same_player == 0 & receiving_team2 == 1],na.rm=T)][1],
             closest_receiving_player_separation = min(separation[same_player == 0 & receiving_team2 == 1],na.rm=T),
             closest_receiving_vises_separation = min(separation[same_player == 0 & receiving_team2 == 1 & role2 == "Vises"],na.rm=T),
             closest_receiving_vises_snap_separation = min(snap_separation[same_player == 0 & receiving_team2 == 1 & role2 == "Vises"],na.rm=T),
             closest_receiving_vises_punt_separation = min(punt_separation[same_player == 0 & receiving_team2 == 1 & role2 == "Vises"],na.rm=T),
             closest_receiving_player_dir_diff = s_theta1 - s_theta2[nflId2 == closest_receiving_player_id],
             closest_receiving_snap_separation = min(snap_separation[same_player == 0 & receiving_team2 == 1],na.rm = T),
             closest_receiving_punt_separation = min(punt_separation[same_player == 0 & receiving_team2 == 1],na.rm = T),
             closest_vises_separation_snap_id = nflId2[separation == min(snap_separation[same_player == 0 & receiving_team2 == 1 & role2 == "Vises"],na.rm = T)][1]) %>%
      filter(punting_team1 == 1 & !is.na(closest_receiving_player_separation) & same_player == 0) %>%
      group_by(gameId,playId,nflId1) %>%
      summarise(
        var_x = mean(var_x),
        var_y = mean(var_y),
        var_dir_x = mean(var_dir_x),
        var_dir_y = mean(var_dir_y),
        var_dir = mean(var_dir),
        var_s_theta = mean(var_s_theta),
        var_s = mean(var_s),
        snap_dis_from_los = mean(snap_dis_from_los,na.rm = T),
        sum_dis = mean(sum_dis),
        pre_play_dis = mean(pre_play_dis),
        snap_dis_from_los = mean(snap_dis_from_los,na.rm=T),
        punt_dis_from_los = mean(punt_dis_from_los,na.rm=T),
        ball_land_dis_from_los = mean(ball_land_dis_from_los,na.rm=T),
        ball_land_dis_from_player = mean(ball_land_dis_from_player,na.rm = T),
        separation = mean(separation),
        snap_separation = mean(snap_separation,na.rm = T),
        punt_separation = mean(punt_separation,na.rm = T),
        closest_punting_player_separation = mean(closest_punting_player_separation[is.finite(closest_punting_player_separation)]),
        second_closest_punting_player_separation = mean(second_closest_punting_player_separation[is.finite(second_closest_punting_player_separation)]),
        closest_punting_player_dir_diff = mean(closest_punting_player_dir_diff[is.finite(closest_punting_player_dir_diff)]),
        closest_punting_snap_separation = mean(closest_punting_snap_separation[is.finite(closest_punting_snap_separation)]),
        closest_punting_punt_separation = mean(closest_punting_punt_separation[is.finite(closest_punting_punt_separation)]),
        closest_receiving_player_separation = mean(closest_receiving_player_separation[is.finite(closest_receiving_player_separation)]),
        closest_receiving_vises_separation = mean(closest_receiving_vises_separation[is.finite(closest_receiving_vises_separation)]),
        closest_receiving_vises_snap_separation = mean(closest_receiving_vises_snap_separation[is.finite(closest_receiving_vises_snap_separation)]),
        closest_receiving_vises_punt_separation = mean(closest_receiving_vises_punt_separation[is.finite(closest_receiving_vises_punt_separation)]),
        closest_receiving_player_dir_diff = mean(closest_receiving_player_dir_diff[is.finite(closest_receiving_player_dir_diff)]),
        closest_receiving_snap_separation = mean(closest_receiving_snap_separation[is.finite(closest_receiving_snap_separation)]),
        closest_receiving_punt_separation = mean(closest_receiving_punt_separation[is.finite(closest_receiving_punt_separation)]),
        closest_punting_player_id = closest_punting_player_id[1],
        role1 = role1[1],
        Gunner = Gunner[1],
        Vises = Vises[1],
        `Punt Rusher` = `Punt Rusher`[1],
        `ST Safeties` = `ST Safeties`[1],
        closest_gunner_separation_snap_id = mean(closest_gunner_separation_snap_id,na.rm = T),
        closest_vises_separation_snap_id = mean(closest_vises_separation_snap_id,na.rm = T),
        ) %>%
      ungroup() %>%
      dplyr::rename(nflId = nflId1)

            
            ### take care of infinite numbers 
    
    end_time <- Sys.time()
    print(paste('Took', round(end_time - start_time, 2), 'minutes for week', i))
  }
  
  df_tracking_vars <- do.call('rbind', df_tracking_vars)
  
  return(df_tracking_vars)
}

tr<-bdb_get_vars_punt(tracking)




write_csv(tr,"tracking2020_agg.csv")




 

