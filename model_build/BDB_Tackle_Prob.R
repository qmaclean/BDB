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


tr<-read.csv("final_tracking_prepped_2020.csv")

tr<-tr %>%
  dplyr::select(-playDescription,-possessionTeam,-specialTeamsResult,-specialTeamsPlayType,
         -returnerId,-yardlineSide,-gameClock,-penaltyYards,
         -preSnapHomeScore,-preSnapVisitorScore,-returnDirectionIntended,-returnDirectionActual,
         -quarter,-down,-kickReturnYardage,-playResult,-snapDetail,-kickType,-kickDirectionIntended,
         -kickDirectionActual,-kickContactType,-X,-role1,-closest_punting_player_id,
         -closest_gunner_separation_snap_id,-closest_vises_separation_snap_id)

colnames(tr)<-make.names(colnames(tr))
### filter for returned? 
tr<-tr %>% filter(tr$Return == 1)

tr$TackleOpp<-tr$Tackler + tr$AssistTackler + tr$MissedTackler
tr$TackleOpp<-ifelse(tr$TackleOpp >= 1,"Y","N")

#tr$Tackler<-ifelse(tr$Tackler == 1,"Y","N")
#tr$Tackler<-as.factor(tr$Tackler)

tr<-na.omit(tr)
tr<-tr %>%
  filter_all(all_vars(!is.infinite(.)))

ggplot(tr,aes(x=factor(TackleOpp))) +
  geom_bar(stat="count")



### Tackler prediction model
vars<-tr[,c(1:42)]
pred<-tr %>% select(TackleOpp)

data_model<-cbind(vars,pred)


split <- initial_split(data_model)

training_set <- training(split) %>% select(-gameId, -playId, -nflId)
training_set_ids <- training(split) %>% select(gameId, playId, nflId)
testing_set <- testing(split) %>% select(-gameId, -playId, -nflId)
testing_set_ids <- testing(split) %>% select(gameId, playId, nflId)

#vars<-c('var_x','var_y','var_dir_x','var_dir_y','var_dir','var_s_theta',
#        'var_s','snap_dis_from_los','sum_dis','pre_play_dis',
#        'punt_dis_from_los','catch_dis_from_los','separation',
#        'snap_separation','punt_separation','catch_separation','closest_punting_player_separation')

fitControl <- trainControl(## 10-fold CV
  method = "repeatedcv",
  number = 10,
  repeats = 5,
  summaryFunction = twoClassSummary,
  classProbs = TRUE)

fitControl$sampling<-"down"


GBMfit_down<-train(TackleOpp ~ .,
           data=training_set,
           method="gbm",
           verbose = TRUE,
           metric = "ROC",
           trControl = fitControl)


varImp(GBMfit_down) %>% plot()


RFfit_down<-train(TackleOpp ~ .,
                   data=training_set,
                   method="ranger",
                   verbose = TRUE,
                  metric = "ROC",
                   trControl = fitControl)



## Neural Net
nnet_fit_down <- train(
  TackleOpp ~ .,
  data = training_set,
  verbose = TRUE,
  metric = "ROC",
  method = "nnet",
  trControl = fitControl
)

knn_fit_down <- train(
  TackleOpp ~ .,
  data = training_set,
  method = "knn",
  trControl = fitControl
)

rpart_fit_down <- train(
  TackleOpp ~ .,
  data = training_set,
  method = "rpart",
  trControl = fitControl
)

GLM_fit_down <- train(
  TackleOpp ~ .,
  data = training_set,
  method = "glm",
  trControl = fitControl
)

formula_light <- formula(TackleOpp ~ var_x + var_dir_x + var_s_theta + var_s + sum_dis + punt_dis_from_los + 
                           ball_land_dis_from_los + ball_land_dis_from_player  + closest_punting_player_separation + 
                           closest_punting_snap_separation + closest_receiving_vises_separation + closest_receiving_vises_snap_separation + 
                           closest_receiving_snap_separation  + Vises 
                            )

GBMfitlite_down<-train(form=formula_light,
                       data=training_set,
                       method="gbm",
                       verbose=TRUE,
                       trControl = fitControl)

varImp(GBMfitlite_down) %>% plot()
summary(GBMfitlite_down)


RFfitlite_down<-train(form=formula_light,
                      data=training_set,
                      method="ranger",
                      trControl = fitControl,
                      verbose=TRUE)

#GLMfitlite_down<-train(form=formula_light,
#                      data=training_set,
#                      method="glm",
#                      trControl = fitControl)

#summary(GLMfitlite_down)



tackler_model_list <- list(GBM_down = GBMfit_down,
                           RF_down = RFfit_down,
                           RF_lite = RFfitlite_down,
                           NNET_down = nnet_fit_down,
                           KNN_down = knn_fit_down,
                           RPART_down = rpart_fit_down,
                           GLM_down = GLM_fit_down,
                           GBM_lite = GBMfitlite_down)

#tackler_model_list<-list(GBM_down = GBMfitlite_down,
#                         GLM_down = GLMfitlite_down)
                           




  
tackler_resamples <- resamples(tackler_model_list)
summary(tackler_resamples)
bwplot(tackler_resamples)






### rose sampling ####
fitControl$sampling<-"rose"

GBMfit_rose<-train(TackleOpp ~ .,
                   data=training_set,
                   method="gbm",
                   verbose = FALSE,
                   metric = "ROC",
                   trControl = fitControl)

RFfit_rose<-train(TackleOpp ~ .,
                   data=training_set,
                   method="ranger",
                   verbose = FALSE,
                   metric = "ROC",
                   trControl = fitControl)

tackler_model_list <- list(GBM_down = GBMfit_down,
                           RF_down = RFfit_down,
                           RF_lite = RFfitlite_down,
                           NNET_down = nnet_fit_down,
                           KNN_down = knn_fit_down,
                           RPART_down = rpart_fit_down,
                           GLM_down = GLM_fit_down,
                           GBM_lite = GBMfitlite_down,
                           GBM_rose = GBMfit_rose,
                           RF_rose = RFfit_rose)

tackler_resamples <- resamples(tackler_model_list)
summary(tackler_resamples)
bwplot(tackler_resamples)


###### gbm with tuned grid ###
#### GBM down was doing 50 trees, 3 interaction depth, 0.1 shrinkage, and n.minobsinnode = 20)
GBMfit_tune<-train(TackleOpp ~ .,
                   data=training_set,
                   method="gbm",
                   trControl = fitControl,
                   verbose=TRUE,
                   tuneGrid = data.frame(interaction.depth = 4,
                                         n.trees = 100,
                                         shrinkage = .1,
                                         n.minobsinnode = 20),
                   metric = "ROC")

GBMfitlite_tune<-train(form=formula_light,
                       data=training_set,
                       method="gbm",
                       trControl = fitControl,
                       verbose=TRUE,
                       tuneGrid = data.frame(interaction.depth = 4,
                                             n.trees = 100,
                                             shrinkage = .1,
                                             n.minobsinnode = 20),
                       metric = "ROC")


tackler_model_list <- list(GBM_down = GBMfit_down,
                           RF_down = RFfit_down,
                           RF_lite = RFfitlite_down,
                           NNET_down = nnet_fit_down,
                           KNN_down = knn_fit_down,
                           RPART_down = rpart_fit_down,
                           GLM_down = GLM_fit_down,
                           GBM_lite = GBMfitlite_down,
                           GBM_rose = GBMfit_rose,
                           RF_rose = RFfit_rose,
                           GBM_tune = GBMfit_tune,
                           GBM_lite_tune = GBMfitlite_tune)

tackler_resamples <- resamples(tackler_model_list)
summary(tackler_resamples)
bwplot(tackler_resamples)


## GBM lite
testing_set$GBM_lite_pred<-predict(GBMfitlite_down,testing_set,type="raw")
confusionMatrix(testing_set$GBM_lite_pred,as.factor(testing_set$TackleOpp))

## RF lite
testing_set$RF_lite_pred<-predict(RFfitlite_down,testing_set,type="raw")
confusionMatrix(testing_set$RF_lite_pred,as.factor(testing_set$TackleOpp))

## RF down
testing_set$RF_down_pred<-predict(RFfit_down,testing_set,type="raw")
confusionMatrix(testing_set$RF_down_pred,as.factor(testing_set$TackleOpp))


#### save GBM Lite model ####
saveRDS(GBMfitlite_down,"GBM_lite.rds")

GBM<-readRDS("BDB_22/models/GBM_lite.rds")

library(caret)
summary(GBM$resample)


#### make predictions ###
data_model$tackle_pred<-predict(GBMfitlite_down,data_model,type="raw")
data_model$tackle_prob<-predict(GBMfitlite_down,data_model,type="prob")
data_model$tackle_prob_Y<-data_model$tackle_prob$Y
data_model$tackle_prob_N<-data_model$tackle_prob$N

data_model<-data_model %>%
  select(-tackle_prob)

write_csv(data_model,"tackle_prob_predictions.csv")

#### use GBM Lite #### model 


### add to test set predictions
### save model and dataset predictions

##do vif on model ###
### use model on a sample play





