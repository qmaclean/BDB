library(ggplot2)
library(gganimate)
library(tidyverse)


sample<-read.csv("BDB_22/sample_tackle_prob.csv")
players<-read.csv("players.csv")

punt_sample<-sample %>%
  filter(punting_team == 1,
         role == "Gunner")

punt_sample<-punt_sample %>%
  left_join(players,punt_sample,by=("nflId"))

punt_sample<-punt_sample %>%
  arrange(frameId)

sample_gunner_tackle_animate<-ggplot(punt_sample,aes(x=frameId,y=pred,group=nflId,color=nflId)) +
  geom_line() +
  geom_point(size=2) +
  geom_text(
    mapping = aes(x = frameId, y = pred, label = displayName.y),
    nudge_x = 3,hjust=1,size=5,show.legend = FALSE
  )  +
  transition_reveal(frameId) +
  geom_vline(xintercept = 11,linetype="dashed",color="grey",size = 0.5) + 
  geom_text(aes(x=11,label="snap",y=0.5),color="dark grey",text=element_text(size=8)) +              # snap
  geom_vline(xintercept = 33,linetype="dashed",color="grey",size = 0.5) +   # punt
  geom_text(aes(x=33,label="punt",y=0.5),color="dark grey",text=element_text(size=8)) + 
  geom_vline(xintercept = 70,linetype="dashed",color="grey",size = 0.5) +   # punt received
  geom_text(aes(x=70,label="punt received",y=0.4),color="black",text=element_text(size=8)) + 
  geom_vline(xintercept = 84,linetype="dashed",color="grey",size = 0.5) +   # first contact
  geom_text(aes(x=84,label="first contact",y=0.5),color="dark grey",text=element_text(size=8)) +
  geom_vline(xintercept = 106,linetype="dashed",color="grey",size = 0.5) +
  geom_text(aes(x=106,label="tackle",y=0.5),color="dark grey",text=element_text(size=8)) +
  ease_aes('linear') +
  theme(legend.position = "none") +
  xlab("") +
  ylab("") +
  ggtitle("Tackle Opportunity Probability for Gunners")

sample_gunner_tackle_animate

save(sample_gunner_tackle_animate,file="sample_gunner_tackle_animate.rdata")



