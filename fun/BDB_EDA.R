library(tidyverse)

tr$Return_fct<-ifelse(tr$Return == 1,"Y","N")

tr %>%
  group_by(Return_fct) %>%
  summarize(n = n())
# x-y variance of players for return or not; seems like higher variance more likely to return #
ggplot(tr,aes(x=var_x,y=var_y,color=Return_fct)) +
  geom_point()

tr %>%
  filter(role == "Gunner") %>%
ggplot(aes(x=snap_dis_from_los,y=sum_dis,color=Return_fct)) +
  geom_point()

#distance traveled looks to be correlated

tr %>%
  filter(role == "Gunner") %>%
  ggplot(aes(x=separation,y=punt_separation,color=Return_fct)) +
  geom_jitter() + 
  ggtitle("Gunner Avg. Separation vs. Avg. Separation at Punt")

#great jump at punt maybe not as relevant? 

tr %>%
  filter(role1 == "Gunner") %>%
  ggplot(aes(x=snap_separation,y=punt_separation,color=Return_fct)) +
  geom_jitter()

#early separation not as correlated

tr %>%
  filter(role1 == "Gunner") %>%
  ggplot(aes(x=closest_punting_player_separation,y=second_closest_punting_player_separation,color=Return_fct)) +
  geom_jitter() +
  stat_ellipse()


tr %>%
  filter(role1 == "Gunner") %>%
  ggplot(aes(x=closest_receiving_vises_separation,y=second_closest_punting_player_separation,color=Return_fct)) +
  geom_jitter() +
  stat_ellipse()

# not as relevant

# gunner stats #


