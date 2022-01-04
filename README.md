
Evaluating Gunner's Performance
================


# Introduction

The punt return can be one of the most dangerous and entertaining play in all of football and contains one of the most difficult jobs in the game of football: the role of the Gunner.

Dave Spadaro (Eagles Insider) had the best [description of the Gunner](https://www.philadelphiaeagles.com/news/spadaro-the-gunner-dirty-nasty-job-the-eagles-do-very-well):

“They’re the guys who line up wide on punts, often face double-team blocking, get the snot knocked out of them after the ball is snapped, and then, once they break free from the blocks, have to sprint 50, 60 yards and get to the punt return man in time to halt any progress.”

The goal of my analysis is to [build on the initial research done by Michael Lopez](https://operations.nfl.com/gameday/analytics/stats-articles/visualizing-the-special-teams-gunner/) to add specific metrics to evaluate Gunners in the NFL based on available tracking data.

We will be using 2020 tracking and scouting information to create four metrics to evaluate Gunner effectiveness during punts. The metrics are:
1. **Tackle Opportunity Probability Added (TOPA)**: The difference in expected probability of getting a tackle opportunity added from snap to punt received
2. **Gunner’s Distance to Ball at Punt Reception Under Expected (BDUE)**: The difference in Gunner’s x-position to ball versus what was expected
3. **Return Yards Under Expected (RYUE)**: The difference in actual return yards versus what was expected based on the Gunner’s location metrics at punt reception
4. **Return Yards Under Expected (Non-Fair Catch Punts)**: The difference in actual return yards versus what was expected based on the Gunner’s location metrics at punt reception for non-fair catch punts
These four metrics will help to measure which gunners help to limit the opposing team’s starting position.

# Tackle Opportunity Probability Added (TOPA)

The animated play below shows a 3-yard punt return where two Gunners, Nsimba Webster (#14) and David Long (#25) close in on the punt returner to limit his overall yardage and do their best to tackle the returner. In this example, Webster is credited with the tackle. This visual helps to portray a common punt scenario so we will use this play to illustrate gunner effectiveness throughout the rest of this paper. First, we want to define tackle opportunity as the gunner’s involvement of a tackle either being the primary tackler, assisted tackler, or even having a missed tackle. Including assisted tacklers and missed tacklers helps to get a larger sample size of Gunners who were involved in tackling plays.

<img src="https://github.com/qmaclean/BDB_22/blob/master/viz_images/initial_animation.gif" width="75%" />

If we break down the tackle opportunity by frame in the play above, Webster had ~30% probability of a tackle at snap, ~28% at punt reception. We can see a wide variation in probability between that timeframe. The probability dropped to a low at 18%, a high at 30% (at the snap) and had ~25.3% average probability through the duration of the play. 

The reason for Webster's drop in probability to 18% was that he had beat his opposing vise (#29) at the snap, #18 on the receiving team recognizes this and changes his position to seal the block for the returner. The increase in probability is due to the fact that by gaining the attention of the second defender, he actually created a log jam at the returner thus limiting his potential return yardage and increasing his probability of a tackle opportunity (Again, Webster was credited with the tackle).

This scenario helps to paint a good picture of how a Gunner's position can create traffic for the return team resulting in a tackle opportunity or reduction in return yardage. 

<img src="https://github.com/qmaclean/BDB_22/blob/master/viz_images/tackle_opp_probability.gif" width="50%" />

In the scenario above, we showed results of the **Tackle Opportunity Probability Model**, which can be used to evaluate Gunner's ability to put themselves in a better position for a tackle opportunity from snap to punt reception. 

For creating our model, we used NFL tracking data and filtered for the following: 
1. Punt Plays 
2. Using PFF data, filtering for those who were assigned as Gunner's 
3. Filtering for catchable punts (filters out touchbacks) 

Filtering out touchbacks helps to model for plays where a Gunner could have had a high probability of a tackle even in cases of a fair catch (i.e. forcing a fair catch).

In building the model, the following variables were included for consideration: \
-Gunner's field position and direction variance \
-Gunner's speed variance \
-Distance from Line of Scrimmage (LOS) \
-Distance from ball \
-Total distance travelled \
-Avg. separation from closest players \
-Position types on the field (# of Gunners, # of Vises) \

The resulting classification model is a [Gradient Boosted Machine (GBM)](http://uc-r.github.io/gbm_regression) using down sampling, 10 cross fold validations, and 5 repeats to properly train and improve the performance of the model. Gradient Boosted Machines is a machine learning technique that uses multiple learning algorithms with the goal of "boosting" or reducing bias and variance. It essentially converts weak learning models into a "boosted" or stronger one. The custom sampling techniques added helps to iterate through our decision trees to create the most accurate model possible. 

In our evaluating our model, we got a mean ROC score of 80.2%, mean sensitivity score of 66.1%, and a mean specificity score of 80.6%. Essentially, our model is better at calculating non tackle opportunities than calculating tackle opportunities. 

Another way to interpret our model is through visualizing the feature importance (Gini impurity), which helps to describe the decision tree nodes in order of relative importance. Basically, this helps to show what factors contribute the most to our prediction output. We can see that a player's distance to the ball, their position variance per second, and overall speed variance are the biggest factors that contribute to player's tackle opportunity probability. It's interesting to see that the number of total Vises on the receiving team doesn't have much importance in a Gunner's Tackle Opportunity Probability.

<img src="https://github.com/qmaclean/BDB_22/blob/master/viz_images/feature_importance.png" width="75%" />

What this boils down to is the commitment to the angle of pursuit at the snap. We can see this by visualizing all of Webster's punt routes for received punts (Green lines are tackles; Blue lines are missed tackles and Grey lines are non-tackles). In the first few seconds of the snap, you see a rather clean angle being formed and that's due to the gunner's commitment to the angle. 

<img src="https://github.com/qmaclean/BDB_22/blob/master/viz_images/routes_run.gif" width="50%" />

Pulling it all together, we see that Webster had the most Tackle Opportunities of Gunners in 2020 for returnable punts but a lower TOPA (Tackle Opportunity Probability Added). A big part of his ability to create more Tackle Opportunities is his relatively high avg speed and higher separation from other vises. Contrary to Webster in strategy is Justin Bethel, who had the one of the highest avg. TOPA due to his high avg speed, high avg max speed, and low speed variance (usually straight shot in route). Bethel was the only gunner to eclipse 20 mph in his average max speed per punt. Lastly, we see Matthew Slater listed high here and that's important to note considering he's been to 9 Pro Bowls as a Gunner (most all-time).

<img src="https://github.com/qmaclean/BDB_22/blob/master/viz_images/tackle_prob_summary.png" width="100%" />

# Expected Gunner Distance to Ball and Expected Return Yards
TOPA is a helpful metric to evaluate what Gunner's put themselves in the best position for a tackle opportunity on a punt play. However, as we see know not every punt play is returned by the returner. To help to evaluate players in all punts, we are creating two more models to evaluate which Gunner's get close to the returner at punt reception and which Gunners are the best at limiting return yardage. 

The distribution chart below illustrates that there is vast difference amongst a gunner's ability to get to the ball for a given punt play, which indicates that some gunners are better at getting to the returner and thus limiting return yardage. 

<img src="https://github.com/qmaclean/BDB_22/blob/master/viz_images/Gunner%20Position%20Distribution.png" width="75%" />

This leads to the creation of the **Expected Distance to Ball** and **Expected Return Yards** models, which were both trained using a Random Forest regression model and optimized using a 10-fold repeated cross validation (5x). This helps to resample the dataset to prevent any training bias. The purpose of the first model is to predict what a gunner's distance to ball will be. The prediction at punt reception will be used to compare to where the gunner's actual distance is versus expectation. The purpose of the second model, is to understand how a player's proximity, speed, and other variables (same used to predict tackle opportunity probability) can influence return yardage. The prediction at punt reception can used as the official metric to evaluate how a gunner can limit return yardage. 

To evaluate the accuracy and effectiveness of the models, R-squared, Root Mean Square Error (RMSE), and Mean Absolute Error (MAE) were chosen as the main model evaluation metrics. R-squared represents how close the predictions are to the actual values from a proportional or percentage value, which for these two models we got >98%. RMSE is a measurement of error rate for all observations and MAE is the mean error. We can see below that both these models have less than a 2% error rate (RMSE) and an average observed difference of less than 1 yard (MAE). 

Ball Distance Metrics: \
-R-squared: 0.990\
-RMSE: 0.950 \
-MAE: 0.520 

Return Yards Metrics: \
-R-squared: 0.983 \
-RMSE: 1.61 \
-MAE: 0.687 

There are two applications of these models. The first is shown below as a way to augment film study by showing per punt how the gunner was able to get to the returner. To visualize the prediction, three lines were added to the sample play to show these models prediction per second. The first line (in red) shows the expected return yardage from the punt returner. The second two lines (in grey) show the predicted distance each gunner will be the punt returner by the point of reception. We can see how the predictions change as the play develops. 

<img src="https://github.com/qmaclean/BDB_22/blob/master/viz_images/ryue_bdue.gif" width="75%" />

### Gunner's Return Yard Under Expected and Ball Distance Under Expected ###
The second application of the model is to evaluate what occurred at punt reception versus expectation. The average delta will be created as a metric for evaluation of Gunners. This leads to the creation of the **Return Yards Under Expected (RYUE)** and **Ball Distance Under Expected (BDUE)**. The Gunners who were able to limit the most return yardage and get closer to the ball than expected would ultimately be best at their position. Similar to TOPA, we see Matthew Slater and Justin Bethel rank towards the top. What is interesting about Webster, is he ranks high in his ability to get to the ball (BDUE) but doesn't put himself in the best position to limit return yardage, which was a similar theme for his lower TOPA compared to other Gunners. J.T. Gray also ranks high BDUE (~7 yards closer to the ball than expected on average), and RYUE.

<img src="https://github.com/qmaclean/BDB_22/blob/master/viz_images/ryue_bdue_img.png" width="100%" />

### Application of Models & Future Opportunities
These models were specifically designed with the intent to evaluate Gunner's effectiveness in punt plays but could easily be extended to evaluate other players on the punt play (Vises, others in pursuit). Other players on the punt team can use the learnings of the model to fine tune their speed, direction and angle as a way to commit to the angle of pursuit. Another application of the models is to help to augment film review using the tackle opportunity probability visualization, distance to ball, and expected return yards all by frame. These visualizations could easily be replicated for other punt plays as a way for players to understand their attack to a returner. Lastly, knowing that Gunner's with the best commitment to angle of pursuit are able to limit return yardage, it may make sense for returning teams to have a vise (or other player), 10-15 yards from the line of scrimmage as a way to create more room to block for the return and cut off the angle for the Gunner (This was shown in our sample play). 

 



[Source Code](https://github.com/qmaclean/BDB_22) 

[Personal Twitter](https://twitter.com/QuinnsWisdom)

[Kaggle](https://www.kaggle.com/qmaclean/evaluating-gunner-s-performance)

[Sharable Website](https://htmlpreview.github.io/?https://github.com/qmaclean/BDB_22/blob/master/NFL_Big_Data_Bowl_2022_Notebook.html)
