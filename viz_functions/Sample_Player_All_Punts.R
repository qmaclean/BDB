library(tidyverse)
library(gganimate)
library(ggplot2)
library(cowplot)


data_model<-read.csv("BDB_22/ball_distance_pred.csv")
tracking_tacklers<-read.csv("BDB_22/data/tackler_tracking_2020.csv")
#players<-read.csv("players.csv")

tracking_tacklers<-tracking_tacklers %>%
  group_by(gameId,playId,nflId) %>%
  summarize(Tackler = sum(Tackler),
            AssistTackler = sum(AssistTackler),
            MissedTackler = sum(MissedTackler))

#data_model<-data_model %>%
#  left_join(players,by=c("nflId"))

pos_min<-data_model %>%
  group_by(gameId,playId,nflId) %>%
  summarize(min_x = min(x))

### webster 48784
data_model<-data_model %>%
  left_join(tracking_tacklers,by=c("gameId","playId","nflId")) 

#web<-data_model %>%
#  filter(nflId %in% c("48784","33234","38707"))

web<-data_model %>%  filter(nflId == "48784")

web<-web %>%
  left_join(pos_min,by=c("gameId","playId","nflId"))

#web<-web %>%
#  mutate(x = x - min_x)

web<-web %>%
  group_by(playId) %>%
  mutate(id = 1:n(),
         tackleOpp = ifelse(Tackler > 0,"Tackle",
                            ifelse(AssistTackler > 0,"AssistTackler",
                                   ifelse(MissedTackler > 0, "MissedTackler","No Tackle Opp"))))


web<-web %>%
  filter(id < 75)
####### FIELD #####

## General field boundaries
xmin <- 0
xmax <- 160/3
hash.right <- 38.35
hash.left <- 12
hash.width <- 3.3



## Specific boundaries for a given play
ymin <- max(round(min(web$x - web$min_x, na.rm = TRUE) - 10, -1), 0)
ymax <- min(round(max(web$x - web$min_x, na.rm = TRUE) + 10, -1), 120)
df_hash <- expand.grid(x = c(0, 23.36667, 29.96667, xmax), y = (10:110))
df_hash <- df_hash %>% filter(!(floor(y %% 5) == 0))
df_hash <- df_hash %>% filter(y < ymax, y > ymin)

animate_play <- ggplot() +
  scale_size_manual(values = c(6, 4, 6), guide = FALSE) + 
  scale_shape_manual(values = c(21, 16, 21), guide = FALSE) +
  scale_fill_manual(values = c("#e31837", "#654321", "#002244"), guide = FALSE) + 
  scale_colour_manual(values = c("black", "#654321", "#c60c30"), guide = FALSE) + 
  annotate("text", x = df_hash$x[df_hash$x < 55/2], 
           y = df_hash$y[df_hash$x < 55/2], label = "_", hjust = 0, vjust = -0.2) + 
  annotate("text", x = df_hash$x[df_hash$x > 55/2], 
           y = df_hash$y[df_hash$x > 55/2], label = "_", hjust = 1, vjust = -0.2) + 
  annotate("segment", x = xmin, 
           y = seq(max(10, ymin), min(ymax, 110), by = 5), 
           xend =  xmax, 
           yend = seq(max(10, ymin), min(ymax, 110), by = 5)) + 
  annotate("text", x = rep(hash.left, 11), y = seq(10, 110, by = 10), 
           label = c("G   ", seq(10, 50, by = 10), rev(seq(10, 40, by = 10)), "   G"), 
           angle = 270, size = 4) + 
  annotate("text", x = rep((xmax - hash.left), 11), y = seq(10, 110, by = 10), 
           label = c("   G", seq(10, 50, by = 10), rev(seq(10, 40, by = 10)), "G   "), 
           angle = 90, size = 4) + 
  annotate("segment", x = c(xmin, xmin, xmax, xmax), 
           y = c(ymin, ymax, ymax, ymin), 
           xend = c(xmin, xmax, xmax, xmin), 
           yend = c(ymax, ymax, ymin, ymin), colour = "black") + 
  geom_point(data = web %>% dplyr::filter(tackleOpp == "Tackle"), aes(x = (xmax-y) + 2.5, y = x - min_x + 10), alpha = 0.7,color="light green") + 
  geom_point(data = web %>% dplyr::filter(tackleOpp == "No Tackle Opp"), aes(x = (xmax-y) + 2.5, y = x - min_x + 10), alpha = 0.4,color="light grey") +
  geom_point(data = web %>% dplyr::filter(tackleOpp == "MissedTackler"), aes(x = (xmax-y) + 2.5, y = x - min_x + 10), alpha = 0.7,color="light blue") +
  ylim(ymin, ymax) + 
  coord_fixed() +  
  theme_nothing() + 
  transition_time(id)  +
  labs(title = "Nsima Webster's Punt Angles (Non Touchback Punts)") +
  shadow_mark() +
  ease_aes('linear') + 
  NULL

play.length.ex <- length(unique(web$id))
animate(animate_play, fps = 10, nframe = play.length.ex)




 







