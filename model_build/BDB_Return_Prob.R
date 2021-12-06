library(rstanarm)
library(broom)
library(tidyverse)
library(caret)
library(caretEnsemble)
library(e1071)
library(h2o)
library(rsample)
library(ada)



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


key_tr_sub<-key_tr %>%
  select(gameId,playId,nflId,frameId,kickReturnYardage) %>%
  rename(return_yds = kickReturnYardage,
         key_event_frameId = frameId)

key_event<-key_event %>%
  left_join(key_tr_sub,by=c("gameId","playId","nflId"))


event_tr<-tr %>%
  select(gameId,playId,frameId,nflId,event)

key_event<-key_event %>%
  left_join(event_tr,by=c("gameId","playId","nflId","frameId"))

key_event<-key_event %>%
  select(-X,-role,-pred) 

key_event<-key_event %>%
  mutate(return_yds = ifelse(is.na(return_yds),0,return_yds))


ggplot(key_event,aes(x=return_yds)) +
  geom_density()


##### train using poisson distribution


#### make a model for delta in position at punt received

key_event<-na.omit(key_event)



vars<-key_event[,c(1:24)]
pred<-key_event %>% select(return_yds)

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



lm<-train(return_yds ~ .,
          data = training_set,
          method = "lm",
          family="poisson",
          trControl = fitControl,
          verbose = TRUE,
          na.action = na.exclude)
summary(lm)



glm_boost<-train(return_yds ~ .,
                 data = training_set,
                 method = "glmboost",
                 trControl = fitControl)

rf<-train(return_yds ~ .,
          data = training_set,
          method = "ranger",
          trControl = fitControl)



#LM
testing_set$test_pred<-predict(lm,testing_set)
postResample(pred=testing_set$test_pred,obs=testing_set$return_yds)
#GLM_boost
testing_set$test_pred_glm_boost<-predict(glm_boost,testing_set)
postResample(pred=testing_set$test_pred_glm_boost,obs=testing_set$return_yds)
#RF
testing_set$test_pred_rf<-predict(rf,testing_set)
postResample(pred=testing_set$test_pred_rf,obs=testing_set$return_yds)

saveRDS(rf,"rf_return_yards.rds")

data_model$return_yards_pred<-predict(rf,data_model)

write.csv(data_model,"return_yards_pred.csv")


