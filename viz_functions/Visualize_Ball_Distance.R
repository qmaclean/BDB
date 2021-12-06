library(tidyverse)
library(gganimate)

## ball_distance_prod
data_model<-read_csv("BDB_22/ball_distance_pred.csv")

### return prod
dm<-read_csv("BDB_22/return_yards_pred.csv")


sample<-read_csv("BDB_22/sample_tackle_prob.csv")

#webster pred
gr1<-data_model %>% select(gameId,playId,nflId,frameId,ball_distance_pred) %>%
  filter(nflId == "48784") %>%
  rename(ball_distance_pred_gr1 = ball_distance_pred)

gr2<-data_model %>% select(gameId,playId,nflId,frameId,ball_distance_pred) %>%
  filter(nflId == "47862") %>%
  rename(ball_distance_pred_gr2 = ball_distance_pred)

return_prob<-dm %>% select(gameId,playId,nflId,frameId,return_yards_pred) %>%
  filter(nflId == "48784")


returner<-sample %>%
  select(gameId,playId,nflId,frameId,x,y) %>%
  filter(nflId == "48988") %>%
  rename(returner_x = x,
         returner_y = y)


example_play<-sample %>%
  left_join(gr1,sample,by=c("gameId","playId","frameId")) %>%
  left_join(gr2,sample,by=c("gameId","playId","frameId")) %>%
  left_join(returner,by=c("gameId","playId","frameId")) %>%
  left_join(return_prob,by=c("gameId","playId","frameId"))

example_play<-example_play %>%
  mutate(pred_pos_gr1 = returner_x + ball_distance_pred_gr1,
         pred_pos_gr2 = returner_x + ball_distance_pred_gr2,
         pred_return_yards = returner_x - return_yards_pred)

# from https://www.kaggle.com/adamsonty/nfl-big-data-bowl-a-basic-field-control-model



### horizontal animation ###

#sample<-read.csv("sample_tackle_prob.csv")
#tracking2018<-read.csv("tracking2018.csv")
#example_play<-tracking %>% filter(gameId=="2021010300",playId=="4075")
#rm(tracking2018)

#example_play<-example_play %>% left_join(plays,example_play,by=c("gameId"="gameId","playId"="playId"))
#example_play<-example_play %>% left_join(games,tracking,by=c("gameId"="gameId"))






plot_field <- function(field_color="#006400", line_color = "#212529", number_color = "#ffffff") {
  field_height <- 160/3
  field_width <- 120
  
  field <- ggplot() +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 13, hjust = 0.5),
      plot.subtitle = element_text(hjust = 1),
      legend.position = "bottom",
      legend.title.align = 1,
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.title = element_blank(),
      axis.ticks = element_blank(),
      axis.text = element_blank(),
      axis.line = element_blank(),
      panel.background = element_rect(fill = field_color, color = "white"),
      panel.border = element_blank(),
      aspect.ratio = field_height/field_width
    ) +
    # major lines
    annotate(
      "segment",
      x = c(0, 0, 0,field_width, seq(10, 110, by=5)),
      xend = c(field_width,field_width, 0, field_width, seq(10, 110, by=5)),
      y = c(0, field_height, 0, 0, rep(0, 21)),
      yend = c(0, field_height, field_height, field_height, rep(field_height, 21)),
      colour = line_color
    ) +
    # hashmarks
    annotate(
      "segment",
      x = rep(seq(10, 110, by=1), 4),
      xend = rep(seq(10, 110, by=1), 4),
      y = c(rep(0, 101), rep(field_height-1, 101), rep(160/6 + 18.5/6, 101), rep(160/6 - 18.5/6, 101)),
      yend = c(rep(1, 101), rep(field_height, 101), rep(160/6 + 18.5/6 + 1, 101), rep(160/6 - 18.5/6 - 1, 101)),
      colour = line_color
    ) +
    # yard numbers
    annotate(
      "text",
      x = seq(20, 100, by = 10),
      y = rep(12, 9),
      label = c(seq(10, 50, by = 10), rev(seq(10, 40, by = 10))),
      size = 10,
      colour = number_color,
    ) +
    # yard numbers upside down
    annotate(
      "text",
      x = seq(20, 100, by = 10),
      y = rep(field_height-12, 9),
      label = c(seq(10, 50, by = 10), rev(seq(10, 40, by = 10))),
      angle = 180,
      size = 10,
      colour = number_color, 
    )
  
  return(field)
}

example_play$gr1<-"Nsima Webster (#14)"
example_play$gr2<-"David Long (#25)"
example_play$pred_return<-"Exp. Return Yards"
example_play$team_name<-as.character(example_play$team_name)
example_play$homeTeamAbbr<-as.character(example_play$homeTeamAbbr)
example_play$visitorTeamAbbr<-as.character(example_play$visitorTeamAbbr)
line_of_scrimmage = example_play$absoluteYardlineNumber
to_go_line = line_of_scrimmage - example_play$yardsToGo
df_colors = data.frame(home_1 = 'yellow',
                       home_2 = 'dark blue',
                       away_1 = 'blue',
                       away_2 = 'light grey')

example_play$frameId<-as.numeric(example_play$frameId)

play_frames<-plot_field() + 
  # line of scrimmage
  annotate(
    "segment",
    x = line_of_scrimmage, xend = line_of_scrimmage, y = 0, yend = 160/3,
    colour = "#0d41e1", size = 1.5
  ) +  # first down marker
  annotate(
    "segment",
    x = to_go_line, xend = to_go_line, y = 0, yend = 160/3,
    colour = "#f9c80e", size = 1.5
  )  +  # away team velocities
  geom_segment(
    data = example_play %>% dplyr::filter(team_name == visitorTeamAbbr),
    mapping = aes(x = x, y = y, xend = x + dir_x, yend = y + dir_y),
    color = df_colors$away_1, size = 5, arrow = arrow(length = unit(1, "cm"),ends="last")
  )  + # home team velocities
  geom_segment(
    data = example_play %>% dplyr::filter(team_name == example_play$homeTeamAbbr),
    mapping = aes(x = x, y = y, xend = x + dir_x, yend = y + dir_y),
    colour = df_colors$home_2, size = 2, arrow = arrow(length = unit(0.03, "npc"))
  ) +  # away team locs and jersey numbers
  geom_point(
    data = example_play %>% dplyr::filter(team_name == example_play$visitorTeamAbbr),
    mapping = aes(x = x, y = y),
    fill = "#f8f9fa", colour = df_colors$away_2,
    shape = 21, alpha = 0.7, size = 8, stroke = 1.5
  )  + ## gunner 1 pred
  geom_segment(
    data = example_play,
    mapping = aes(x = example_play$pred_pos_gr1, xend = example_play$pred_pos_gr1,y=0,yend = 160/3),
    color = "light grey",size = 1,lty =2
  ) + 
  geom_label(data=example_play, aes(x=example_play$pred_pos_gr1, y=50,  label = example_play$gr1),
             nudge_x = -2) +
  #gunner 2 pred
  geom_segment(
    data = example_play,
    mapping = aes(x = example_play$pred_pos_gr2, xend = example_play$pred_pos_gr2,y=0,yend = 160/3),
    color = "dark grey",size = 1,lty =2
  ) +
  geom_label(data=example_play, aes(x=example_play$pred_pos_gr2, y=0,  label = example_play$gr2),fill="dark grey",
             nudge_x = -2) +
   ## Returner Yards
  geom_segment(
    data = example_play,
    mapping = aes(x = example_play$pred_return_yards, xend = example_play$pred_return_yards,y=0,yend = 160/3),
    color = "red",size = 1,lty =2
  ) + 
  geom_label(data=example_play, aes(x=example_play$pred_return_yards, y=40,  label = example_play$pred_return),fill = "light grey",
             nudge_x = -3) +
  geom_text(
    data = example_play %>% dplyr::filter(team_name == example_play$visitorTeamAbbr),
    mapping = aes(x = x, y = y, label = jerseyNumber),
    colour = df_colors$away_1, size = 4.5
  ) +
  # home team locs and jersey numbers
  geom_point(
    data = example_play %>% dplyr::filter(team_name == example_play$homeTeamAbbr),
    mapping = aes(x = x, y = y),
    fill = df_colors$home_1, colour = df_colors$home_2,
    shape = 21, alpha = 0.7, size = 8, stroke = 1.5
  )  + geom_text(
    data = example_play %>% dplyr::filter(team_name == example_play$homeTeamAbbr),
    mapping = aes(x = x, y = y, label = jerseyNumber),
    colour = df_colors$home_2, size = 4.5 
  )  + # ball
  geom_point(
    data = example_play %>% dplyr::filter(team == "football"),
    mapping = aes(x = x, y = y),
    fill = "#935e38", colour = "#d9d9d9",
    shape = 21, alpha = 0.7, size = 6, stroke = 1
  ) +
  labs(title = example_play$playDescription[1]) +
  transition_time(frameId) +
  ease_aes('linear') +
  NULL


play_length <- length(unique(sample$frameId))



play_anim <- animate(
  play_frames,
  fps = 10, 
  nframes = play_length,
  width = 800,
  height = 400,
  end_pause = 0
)


play_anim

#save(play_anim,file="play_anim.rdata")


