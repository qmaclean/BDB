#parse off tacklers


tracking<-read.csv("tracking2020_prepped.csv")


tracking<-tracking
#### add in tackler
tracking<-tracking %>%
  separate(`tackler`,c("tackler team","tackler number"), sep=" ")


tracking<-tracking %>%
  mutate(`tackler team` = replace_na(`tackler team`,"No Team"))


### assist tackler
tracking<-tracking %>%
  separate(`assistTackler`,c("assist tackler team","assist tackler number"), sep=" ")


tracking<-tracking %>%
  mutate(`assist tackler team` = replace_na(`assist tackler team`,"No Team"))


### missed tackler ####
tracking<-tracking %>%
  separate(`missedTackler`,c("missedTackler 1","missedTackler 2","missedTackler 3","missedTackler 4","missedTackler 5","missedTackler 6"),sep="; ")

tracking<-tracking %>%
  separate(`missedTackler 1`,c("missedTackler 1 team","missedTackler 1 number"),sep=" ") %>%
  separate(`missedTackler 2`,c("missedTackler 2 team","missedTackler 2 number"),sep=" ") %>%
  separate(`missedTackler 3`,c("missedTackler 3 team","missedTackler 3 number"),sep=" ") %>%
  separate(`missedTackler 4`,c("missedTackler 4 team","missedTackler 4 number"),sep=" ") %>%
  separate(`missedTackler 5`,c("missedTackler 5 team","missedTackler 5 number"),sep=" ") %>%
  separate(`missedTackler 6`,c("missedTackler 6 team","missedTackler 6 number"),sep=" ")

tracking<-tracking %>%
  mutate(`missedTackler 1 team` = replace_na(`missedTackler 1 team`,"No Team"),
         `missedTackler 2 team` = replace_na(`missedTackler 2 team`,"No Team"),
         `missedTackler 3 team` = replace_na(`missedTackler 3 team`,"No Team"),
         `missedTackler 4 team` = replace_na(`missedTackler 4 team`,"No Team"),
         `missedTackler 5 team` = replace_na(`missedTackler 5 team`,"No Team"),
         `missedTackler 6 team` = replace_na(`missedTackler 6 team`,"No Team"))

##### 
tracking<-tracking %>%
  mutate(
  Tackler = ifelse(team_name == `tackler team` & jerseyNumber == `tackler number`,1,0),
  AssistTackler = ifelse(team_name == `assist tackler team` & jerseyNumber == `assist tackler number`,1,0),
  MissedTackler = ifelse(team_name == `missedTackler 1 team` & jerseyNumber == `missedTackler 1 number`,1,
                  ifelse(team_name == `missedTackler 2 team` & jerseyNumber == `missedTackler 2 number`,1,
                  ifelse(team_name == `missedTackler 3 team` & jerseyNumber == `missedTackler 3 number`,1,       
                  ifelse(team_name == `missedTackler 4 team` & jerseyNumber == `missedTackler 4 number`,1,
                  ifelse(team_name == `missedTackler 5 team` & jerseyNumber == `missedTackler 5 number`,1,
                  ifelse(team_name == `missedTackler 6 team` & jerseyNumber == `missedTackler 6 number`,1,0)))))))

tackler_tracking<-tracking %>%
  select(gameId,playId,frameId,nflId,Tackler,AssistTackler,MissedTackler)

write.csv(tackler_tracking,"tackler_tracking_2020.csv")




