library(tidyverse)
library(ngscleanR)
library(gganimate)
library(cowplot)
library(parallel)
library(parallelly)

parallelly::availableCores()
future::plan("multisession")


pff<-read.csv("PFFScoutingData.csv")
games<-read.csv("games.csv")
players<-read.csv("players.csv")
plays<-read.csv("plays.csv")
tracking<-read.csv("tracking2020.csv")

head(tracking)

as.character.numeric_version()

plays$returnerId<-as.integer(as.character.numeric_version((plays$returnerId)))

unique(tracking$event)


tracking<-tracking %>%
  left_join(plays,tracking,by=c("gameId"="gameId","playId"="playId")) %>%
  filter(specialTeamsPlayType == "Punt") %>%
  left_join(pff,by=c("gameId"="gameId","playId"="playId")) %>%
  left_join(games,by=c("gameId"="gameId")) %>%
  left_join(players,by=c("nflId")) %>%
  filter(specialTeamsResult %in% c("Fair Catch","Downed","Muffed","Return"))  # filter out blocks or fakes


##label key positions: Gunners, Vises, Punt Rushers, Special Team Safeties, 
###  join in positions to add positions of P, LS, 

tracking<-tracking %>%
  separate(gunners,c("gunner 1","gunner 2","gunner 3","gunner 4"),sep = "; ")

### gunners 
tracking<-tracking %>%
  separate(`gunner 1`,c("gunner 1 team","gunner 1 number"),sep=" ") %>%
  separate(`gunner 2`,c("gunner 2 team","gunner 2 number"),sep=" ") %>%
  separate(`gunner 3`,c("gunner 3 team","gunner 3 number"),sep=" ") %>%
  separate(`gunner 4`,c("gunner 4 team","gunner 4 number"),sep=" ")

tracking<-tracking %>%
  mutate(`gunner 1 team` = replace_na(`gunner 1 team`,"No Team"),
         `gunner 2 team` = replace_na(`gunner 2 team`,"No Team"),
         `gunner 3 team` = replace_na(`gunner 3 team`,"No Team"),
         `gunner 4 team` = replace_na(`gunner 4 team`,"No Team"))


### Vises
tracking<-tracking %>%
  separate(`vises`,c("vises 1","vises 2","vises 3","vises 4","vises 5"),sep="; ")

tracking<-tracking %>%
  separate(`vises 1`,c("vises 1 team","vises 1 number"),sep=" ") %>%
  separate(`vises 2`,c("vises 2 team","vises 2 number"),sep=" ") %>%
  separate(`vises 3`,c("vises 3 team","vises 3 number"),sep=" ") %>%
  separate(`vises 4`,c("vises 4 team","vises 4 number"),sep=" ") %>%
  separate(`vises 5`,c("vises 5 team","vises 5 number"),sep=" ")

tracking<-tracking %>%
  mutate(`vises 1 team` = replace_na(`vises 1 team`,"No Team"),
         `vises 2 team` = replace_na(`vises 2 team`,"No Team"),
         `vises 3 team` = replace_na(`vises 3 team`,"No Team"),
         `vises 4 team` = replace_na(`vises 4 team`,"No Team"),
         `vises 5 team` = replace_na(`vises 5 team`,"No Team"))

#### Punt Rushers ###
tracking<-tracking %>%
  separate(`puntRushers`,c("punt rushers 1","punt rushers 2","punt rushers 3","punt rushers 4","punt rushers 5","punt rushers 6","punt rushers 7","punt rushers 8","punt rushers 9","punt rushers 10"),sep="; ")


tracking<-tracking %>%
  separate(`punt rushers 1`,c("punt rushers 1 team","punt rushers 1 number"),sep=" ") %>%
  separate(`punt rushers 2`,c("punt rushers 2 team","punt rushers 2 number"),sep=" ") %>%
  separate(`punt rushers 3`,c("punt rushers 3 team","punt rushers 3 number"),sep=" ") %>%
  separate(`punt rushers 4`,c("punt rushers 4 team","punt rushers 4 number"),sep=" ") %>%
  separate(`punt rushers 5`,c("punt rushers 5 team","punt rushers 5 number"),sep=" ") %>%
  separate(`punt rushers 6`,c("punt rushers 6 team","punt rushers 6 number"),sep=" ") %>%
  separate(`punt rushers 7`,c("punt rushers 7 team","punt rushers 7 number"),sep=" ") %>%
  separate(`punt rushers 8`,c("punt rushers 8 team","punt rushers 8 number"),sep=" ") %>%
  separate(`punt rushers 9`,c("punt rushers 9 team","punt rushers 9 number"),sep=" ") %>%
  separate(`punt rushers 10`,c("punt rushers 10 team","punt rushers 10 number"),sep=" ")

tracking<-tracking %>%
  mutate(`punt rushers 1 team` = replace_na(`punt rushers 1 team`,"No Team"),
         `punt rushers 2 team` = replace_na(`punt rushers 2 team`,"No Team"),
         `punt rushers 3 team` = replace_na(`punt rushers 3 team`,"No Team"),
         `punt rushers 4 team` = replace_na(`punt rushers 4 team`,"No Team"),
         `punt rushers 5 team` = replace_na(`punt rushers 5 team`,"No Team"),
         `punt rushers 6 team` = replace_na(`punt rushers 6 team`,"No Team"),
         `punt rushers 7 team` = replace_na(`punt rushers 7 team`,"No Team"),
         `punt rushers 8 team` = replace_na(`punt rushers 8 team`,"No Team"),
         `punt rushers 9 team` = replace_na(`punt rushers 9 team`,"No Team"),
         `punt rushers 10 team` = replace_na(`punt rushers 10 team`,"No Team"))

#### Special Team Safeties ####
tracking<-tracking %>%
  separate(`specialTeamsSafeties`,c("safeties 1","safeties 2","safeties 3","safeties 4","safeties 5","safeties 6"),sep="; ")

tracking<-tracking %>%
  separate(`safeties 1`,c("safeties 1 team","safeties 1 number"),sep=" ") %>%
  separate(`safeties 2`,c("safeties 2 team","safeties 2 number"),sep=" ") %>%
  separate(`safeties 3`,c("safeties 3 team","safeties 3 number"),sep=" ") %>%
  separate(`safeties 4`,c("safeties 4 team","safeties 4 number"),sep=" ") %>%
  separate(`safeties 5`,c("safeties 5 team","safeties 5 number"),sep=" ") %>%
  separate(`safeties 6`,c("safeties 6 team","safeties 6 number"),sep=" ")

tracking<-tracking %>%
  mutate(`safeties 1 team` = replace_na(`safeties 1 team`,"No Team"),
         `safeties 2 team` = replace_na(`safeties 2 team`,"No Team"),
         `safeties 3 team` = replace_na(`safeties 3 team`,"No Team"),
         `safeties 4 team` = replace_na(`safeties 4 team`,"No Team"),
         `safeties 5 team` = replace_na(`safeties 5 team`,"No Team"),
         `safeties 6 team` = replace_na(`safeties 6 team`,"No Team"))


tracking<-tracking %>%
  mutate(
    receiving_team = case_when(
    possessionTeam  == homeTeamAbbr & team == "away" ~ 1,
    possessionTeam == visitorTeamAbbr & team == "home" ~ 1,
    TRUE ~ 0
    ),
    punting_team =  case_when(
      possessionTeam == visitorTeamAbbr & team == "away" ~ 1,
      possessionTeam == homeTeamAbbr & team == "home" ~ 1,
      TRUE ~ 0
    ),
    team_name = if_else(team == "home",homeTeamAbbr,visitorTeamAbbr,missing = NULL))



##### IF ELSE LOGIC FOR returning Special teams position ###
tracking<-tracking %>%
  mutate(role = case_when(
    nflId == kickerId ~ "Punter",
    nflId == returnerId ~ "Returner",
    Position == "LS" ~ "Long Snapper",
    team_name == `gunner 1 team` & jerseyNumber == `gunner 1 number` ~ "Gunner",
    team_name == `gunner 2 team` & jerseyNumber == `gunner 2 number` ~ "Gunner",
    team_name == `gunner 3 team` & jerseyNumber == `gunner 3 number` ~ "Gunner",
    team_name == `gunner 4 team` & jerseyNumber == `gunner 4 number` ~ "Gunner",
    team_name == `vises 1 team` & jerseyNumber == `vises 1 number` ~ "Vises",
    team_name == `vises 2 team` & jerseyNumber == `vises 2 number` ~ "Vises",
    team_name == `vises 3 team` & jerseyNumber == `vises 3 number` ~ "Vises",
    team_name == `vises 4 team` & jerseyNumber == `vises 4 number` ~ "Vises",
    team_name == `punt rushers 1 team` & jerseyNumber == `punt rushers 1 number` ~ "Punt Rusher",
    team_name == `punt rushers 2 team` & jerseyNumber == `punt rushers 2 number` ~ "Punt Rusher",
    team_name == `punt rushers 3 team` & jerseyNumber == `punt rushers 3 number` ~ "Punt Rusher",
    team_name == `punt rushers 4 team` & jerseyNumber == `punt rushers 4 number` ~ "Punt Rusher",
    team_name == `punt rushers 5 team` & jerseyNumber == `punt rushers 5 number` ~ "Punt Rusher",
    team_name == `punt rushers 6 team` & jerseyNumber == `punt rushers 6 number` ~ "Punt Rusher",
    team_name == `punt rushers 7 team` & jerseyNumber == `punt rushers 7 number` ~ "Punt Rusher",
    team_name == `punt rushers 8 team` & jerseyNumber == `punt rushers 8 number` ~ "Punt Rusher",
    team_name == `punt rushers 9 team` & jerseyNumber == `punt rushers 9 number` ~ "Punt Rusher",
    team_name == `punt rushers 10 team` & jerseyNumber == `punt rushers 10 number` ~ "Punt Rusher",
    team_name == `safeties 1 team` & jerseyNumber == `safeties 1 number` ~ "ST Safeties",
    team_name == `safeties 2 team` & jerseyNumber == `safeties 2 number` ~ "ST Safeties",
    team_name == `safeties 3 team` & jerseyNumber == `safeties 3 number` ~ "ST Safeties",
    team_name == `safeties 4 team` & jerseyNumber == `safeties 4 number` ~ "ST Safeties",
    team_name == `safeties 5 team` & jerseyNumber == `safeties 5 number` ~ "ST Safeties",
    team_name == `safeties 6 team` & jerseyNumber == `safeties 6 number` ~ "ST Safeties",
    receiving_team == 1 ~ "ST Receiving Team",
    punting_team == 1 ~ "ST Punting Team",
    TRUE ~ as.character(team)
  ))


tracking<-tracking %>%
  dplyr::select(-`gunner 1 team`,-`gunner 1 number`,-`gunner 2 team`,-`gunner 2 number`,
                -`gunner 3 team`,-`gunner 3 number`,-`gunner 4 team`,-`gunner 4 number`,
                -`punt rushers 1 team`,-`punt rushers 1 number`,-`punt rushers 2 team`,-`punt rushers 2 number`,
                -`punt rushers 3 team`,-`punt rushers 3 number`,-`punt rushers 4 team`,-`punt rushers 4 number`,
                -`punt rushers 5 team`,-`punt rushers 5 number`,-`punt rushers 6 team`,-`punt rushers 6 number`,
                -`punt rushers 7 team`,-`punt rushers 7 number`,-`punt rushers 8 team`,-`punt rushers 8 number`,
                -`punt rushers 9 team`,-`punt rushers 9 number`,-`punt rushers 10 team`,-`punt rushers 10 number`,
                -`safeties 1 team`,-`safeties 1 number`,-`safeties 2 team`,-`safeties 2 number`,
                -`safeties 3 team`,-`safeties 3 number`,-`safeties 4 team`,-`safeties 4 number`,
                -`safeties 5 team`,-`safeties 5 number`,-`safeties 6 team`,-`safeties 6 number`,
                -`vises 1 team`,-`vises 1 number`,-`vises 2 team`,-`vises 2 number`,-`vises 3 team`,-`vises 3 number`,
                -`vises 4 team`,-`vises 4 number`,-`vises 5 team`,-`vises 5 number`)


## Using Ben Baldwin's reorientation to same side

#https://github.com/guga31bb/ngscleanR/blob/master/R/cleaning_functions.R


personnel<-tracking %>%
  group_by(gameId,playId,role) %>%
  summarize(n = n_distinct(nflId)) %>%
  pivot_wider(names_from = role,values_from = n) %>%
  select(-football,-`Long Snapper`,-Punter,-Returner,-`ST Punting Team`,-`ST Receiving Team`) %>%
  mutate(Gunner = replace_na(Gunner,0),
         Vises = replace_na(Vises,0),
         `Punt Rusher` = replace_na(`Punt Rusher`,0),
         `ST Safeties` = replace_na(`ST Safeties`,0))
            
tracking<-tracking %>%
  left_join(personnel,tracking,by=c("gameId","playId"))

tracking<-tracking %>%
  mutate(
    to_left = ifelse(playDirection == "left",1,0),
    x=ifelse(to_left == 1,120-x,x),
    y=ifelse(to_left == 1,160/3 - y,y))


los<-tracking %>%
  filter(event == "ball_snap",
         team == "football") %>%
  group_by(gameId,playId) %>%
    summarize(los_x = mean(x,na.rm = T),
              los_y = mean(y,na.rm = T))

tracking<-tracking %>%
  left_join(los,tracking,by=c("gameId","playId"))

contact<-tracking %>%
  filter(event %in% c("first_contact","tackle","punt_downed","punt_land","catch","punt_muffed","punt_received"),
         team == "football") %>%
  group_by(gameId,playId) %>%
  summarize(ball_land_x = min(x,na.rm = T),
            ball_land_y = min(y,na.rm = T))

tracking<-tracking %>%
  left_join(contact,tracking,by=c("gameId","playId"))
  


# standardize orientation
tracking<-tracking %>%
  mutate(
    #rotate 180 degrees for angles
    o = ifelse(playDirection == "left",o+180,o),
#    # degrees from 0 to 360
    o = ifelse(o > 360, o - 360, o),
#    #convert to radians
    o_radians = pi * (o / 180),
    # get orientation and direction in x and y direction
    o_x = ifelse(is.na(o),NA_real_,sin(o_radians)),
    o_y = ifelse(is.na(o),NA_real_,cos(o_radians))
  )

# standardize direction
tracking<-tracking %>%
  mutate(
    #rotate 180 degrees
    dir = ifelse(playDirection == "left",dir + 180,dir),
    # check if degrees between 0 & 360
    dir = ifelse(dir > 360, dir - 360, dir),
    #radians convert
    dir_radians = pi * (dir / 180),
    # get orientation and direction in x and y direction
    dir_x = ifelse(is.na(dir),NA_real_,sin(dir_radians)),    #same v_x
    dir_y = ifelse(is.na(dir),NA_real_,cos(dir_radians)),    # same as v_y
    s_x = dir_x * s,
    s_y = dir_y * s,
    s_theta = atan(s_x/s_y) * s,
    s_theta = ifelse(is.nan(s_theta),0,s_theta),
    
    a_x = dir_x * a,
    a_y = dir_y * a
  )



### 
tracking<-tracking %>%
  mutate(displayName = ifelse(is.na(displayName.x),displayName.y,displayName.x),
        snap = ifelse(frameId == frameId[event == "ball_snap"][1],1,0),
         punt = ifelse(frameId == frameId[event == "punt"][1],1,0),
        catch = ifelse(frameId == frameId[event == "catch"][1],1,0),
          pre_play = ifelse(frameId < frameId[snap == 1][1], 1, 0),
         post_play = ifelse(frameId > frameId[catch == 1][1], 1, 0),
         in_play = ifelse(pre_play == 0 & post_play == 0, 1, 0),
         number_frames_in_play = sum(in_play),
         ) %>%
  select(-displayName.x,-displayName.y)






#saveRDS(tracking,"tracking2018_revised.rds")

write.csv(tracking,"tracking2020_prepped.csv")


























