library(rstanarm)
library(broom)
library(tidyverse)
library(caret)
library(caretEnsemble)
library(e1071)
library(h2o)
library(rsample)
library(ada)
library(gbm)
library(pROC)
library(ROSE)
library(yaml)
library(ggpubr)
library(xgboost)

tr<-read.csv("tracking2020_prepped.csv")
key_event<-read.csv("BDB_22/key_event_total_tracking.csv")

football<-tr %>%
  filter(team == "football") %>%
  select(gameId,playId,frameId,x)

tr<-tr %>% filter(role == "Gunner")

key_event<-key_event %>%
  rename(nflId = nflId1)

tr<-tr %>%
  left_join(football,tr,by=c("gameId","playId","frameId"))

tr<-tr %>%
  rename(x = x.x,
         ball_x = x.y)

tr<-tr %>%
  select(-ball_land_x,-ball_land_y)



key_tr<-tr %>%
  filter(event %in% c('fair_catch','punt_land','punt_downed',
                      'punt_received','first_contact','out_of_bounds','tackle',
                      'punt_muffed','touchback','touchdown')) %>%
  group_by(gameId,playId,nflId) %>%
  summarize(frameId = min(frameId)) %>%
  left_join(tr,by=c("gameId","playId","nflId","frameId")) %>%
  select(gameId,playId,nflId,frameId,x,y,ball_x,kickLength,kickReturnYardage,displayName,Vises,event) %>%
  left_join(key_event,by=c("gameId","playId","nflId","frameId")) %>%
  select(-X,-x.y,-y.y,-pred,-Vises.y,-role,-displayName) %>%
  rename(x = x.x,
         y = y.x,
         Vises = Vises.x)
         
  
    
    
gunner_position_dis<-ggplot(key_tr,aes(x=ball_land_dis_from_player),color="dark blue") +
  geom_density() +
  facet_wrap(~event) +
  xlab("ball land distance (x) from player") +
  labs(title = "Distribution of Gunner position ",
  subtitle="Split by position at first major punt receiving event") +
    theme(axis.text = element_text(size=8),
          title = element_text(size=8)) +
  theme_minimal()

save(gunner_position_dis,file="gpd.rdata")
ggsave(file="Gunner Position Distribution.png")



ball_dis_plot<-key_tr %>%
  filter(event %in% c('punt_received','punt_land'),
         ball_land_dis_from_player < 30,
         kickReturnYardage < 30) %>%
ggplot(aes(x=ball_land_dis_from_player,y=kickReturnYardage)) +
  geom_point(alpha=0.3,color="light blue") +
  geom_smooth() +
  stat_cor(method="pearson",label.x=3,label.y=30) +
  #ggtitle("Distance at Punt Received by Return Yardage") +
  labs(title="Gunner's distance for Returnable Punts",
       subtitle="Showing punts that were returned",
       caption="Filtered for less than 30 yards of ball distance & punt return yardage") +
  ylab("Punt Return Yardage") +
  xlab("Ball Distance (x) from Gunner at Punt Received") +
  theme_minimal()

#Gunner's appear to have marginal effect if they are within 15 yards of punt received

save(ball_dis_plot,file="ball_dis_plot.rdata")
ggsave(file="Gunner Position for Returnable Punts.png")


summary(key_tr$ball_land_dis_from_player)

### create a punt regression model to calculate ball close distance over expected ###
### if multiclass then cut <5 yards, 0-5,5-10,10-15,>15 #####

key_tr_sub<-key_tr %>%
  select(gameId,playId,nflId,frameId,ball_land_dis_from_player) %>%
  rename(key_event_ball_land_dis_from_player = ball_land_dis_from_player,
         key_event_frameId = frameId)

 key_event<-key_event %>%
   left_join(key_tr_sub,by=c("gameId","playId","nflId"))


 event_tr<-tr %>%
   select(gameId,playId,frameId,nflId,event)
 
 key_event<-key_event %>%
   left_join(event_tr,by=c("gameId","playId","nflId","frameId"))

 key_event<-key_event %>%
   select(-X,-role,-pred) 
 
  key_event <- key_event %>%
   filter(complete.cases(key_event_ball_land_dis_from_player))
  
  summary(key_event)
 
  
########### Modelling ###########  
  
key_event<-na.omit(key_event)
 
 vars<-key_event[,c(1:24)]
 pred<-key_event %>% select(key_event_ball_land_dis_from_player)

 data_model<-cbind(vars,pred)
 
 
 split <- initial_split(data_model)
 
 training_set <- training(split) %>% select(-gameId, -playId, -nflId,-frameId)
 training_set_ids <- training(split) %>% select(gameId, playId, nflId,frameId)
 testing_set <- testing(split) %>% select(-gameId, -playId, -nflId,-frameId)
 testing_set_ids <- testing(split) %>% select(gameId, playId, nflId,frameId)

 fitControl <- trainControl(## 10-fold CV
   method = "repeatedcv",
   number = 10,
   repeats = 5,
   summaryFunction = defaultSummary,
   classProbs = FALSE,
   allowParallel = TRUE)
 
 ## lm model 
 lm<-train(key_event_ball_land_dis_from_player ~ .,
           data = training_set,
           method = "lm",
           trControl = fitControl,
           verbose = TRUE,
           na.action = na.exclude)
summary(lm) 

glm_boost<-train(key_event_ball_land_dis_from_player ~ .,
          data = training_set,
          method = "glmboost",
          trControl = fitControl,
          na.action = na.exclude)

grid = expand.grid(nrounds = c(10,20),lambda=c(0.1),alpha=c(1),eta = c(0.1))

xgbLinear<-train(key_event_ball_land_dis_from_player ~ .,
                 data = training_set,
                 method = "xgbLinear",
                 trControl = fitControl,
                 tuneGrid = grid,
                 gamma = 0.5)

#grid1<-expand.grid(size = seq(from = 1,to = 5,by =1),
#                   decay = seq(from = 0.1, to=1, by=0.1))

#nnet<-train(key_event_ball_land_dis_from_player ~ .,
#                 data = training_set,
#                 method = "nnet",
#                 trControl = fitControl,
#                 tuneGrid = grid1,
#                 allowParallel = TRUE,
#                 linout = TRUE,
#                 na.action = na.exclude)


rf<-train(key_event_ball_land_dis_from_player ~ .,
            data = training_set,
            method = "ranger",
            trControl = fitControl,
            na.action = na.exclude)


xgbTree<-train(key_event_ball_land_dis_from_player ~ .,
          data = training_set,
          method = "xgbTree",
          trControl = fitControl,
          na.action = na.exclude)

## try xgbTree, BART Machine

#### testing accuracy ###
#XGBLinear
testing_set$test_pred<-predict(xgbLinear,testing_set)
postResample(pred=testing_set$test_pred,obs=testing_set$key_event_ball_land_dis_from_player)
#LM
testing_set$test_pred_lm<-predict(lm,testing_set)
postResample(pred=testing_set$test_pred_lm,obs=testing_set$key_event_ball_land_dis_from_player)
#GLM Boost
testing_set$test_pred_glm_boost<-predict(glm_boost,testing_set)
postResample(pred=testing_set$test_pred_glm_boost,obs=testing_set$key_event_ball_land_dis_from_player)
#rf
testing_set$test_pred_rf<-predict(rf,testing_set)
postResample(pred=testing_set$test_pred_rf,obs=testing_set$key_event_ball_land_dis_from_player)
#xgbTree
testing_set$test_pred_xgbTree<-predict(xgbTree,testing_set)
postResample(pred=testing_set$test_pred_xgbTree,obs=testing_set$key_event_ball_land_dis_from_player)

### RF 
testing_set$test_pred<-predict(rf_ball,testing_set)
postResample(pred = testing_set$test_pred,obs = testing_set$key_event_ball_land_dis_from_player)

saveRDS(rf,"rf_ball_distance.rds")
####### USE RF ######
### look at best tuning option? 

data_model$ball_distance_pred<-predict(rf,data_model)

write.csv(data_model,"ball_distance_pred.csv")
                


