library(tidyverse)

## read in agg calcs 

tr<-read.csv("BDB_22/data/tracking2020_agg.csv")

tracking_tacklers2020<-read.csv("BDB_22/data/tackler_tracking_2020.csv")
plays<-read.csv("plays.csv")
pff<-read.csv("PFFScoutingData.csv")

tacklers<-tracking_tacklers2020 %>%
  select(gameId,playId,nflId,Tackler) %>%
  filter(Tackler == 1) %>%
  distinct()

assist_tacklers<-tracking_tacklers2020 %>%
  select(gameId,playId,nflId,AssistTackler) %>%
  filter(AssistTackler == 1) %>%
  distinct()

missed_tacklers<-tracking_tacklers2020 %>%
  select(gameId,playId,nflId,MissedTackler) %>%
  filter(MissedTackler == 1) %>%
  distinct()




### add in special teams result ###
tr<-tr %>%
  left_join(plays,tr,by=c("gameId","playId")) %>%
  filter(specialTeamsResult %in% c('Fair Catch','Muffed','Return')) %>%
  left_join(pff,tr,by=c("gameId","playId"))

##### further filtering ###
tr<-tr %>%
  select(-gunners,-puntRushers,-specialTeamsSafeties,-vises,-kickoffReturnFormation,-kickBlockerId,-passResult)

tr<-tr %>%
  filter((specialTeamsResult == "Muffed" &
         kickReturnYardage > 0 &
         complete.cases(returnerId)) | specialTeamsResult %in% c('Fair Catch','Return')) 


#### Add depedent variables ####
tr<-tr %>% 
  mutate(Return = case_when(
    specialTeamsResult == "Fair Catch" ~ 0,
    specialTeamsResult == "Return" ~ 1,
    specialTeamsResult == "Muffed" ~ 1,
    TRUE ~ 0))


tr<-tr %>%
  left_join(tacklers,tr,by=c("gameId","playId","nflId"))

tr<-tr %>%
  left_join(assist_tacklers,tr,by=c("gameId","playId","nflId"))

tr<-tr %>%
  left_join(missed_tacklers,tr,by=c("gameId","playId","nflId"))


####  clean ###
tr<-tr %>%
  select(-missedTackler,-assistTackler,-tackler,-penaltyCodes,-penaltyJerseyNumbers,-kickerId)

tr<-tr %>%
  mutate(Tackler = ifelse(is.na(Tackler),0,1),
         AssistTackler = ifelse(is.na(AssistTackler),0,1),
         MissedTackler = ifelse(is.na(MissedTackler),0,1))

write.csv(tr,"final_tracking_prepped_2020.csv")


rm(assist_tacklers)
rm(missed_tacklers)
rm(pff)
rm(plays)
rm(tacklers)
rm(tracking_tacklers2020)
rm(tracking)



