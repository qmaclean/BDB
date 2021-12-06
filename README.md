# BDB

Big Data Bowl 2022 Submission: https://htmlpreview.github.io/?https://github.com/qmaclean/BDB_22/blob/master/NFL_Big_Data_Bowl_2022_Notebook.html


Evaluating Gunner's Performance
================
Quinn MacLean

# Introduction

The punt return can be one of the most dangerous and entertaining play in all of football and contains one of the most difficult jobs in the game of football: the role of the Gunner.

Dave Spadaro (Eagles Insider) had the best [description of the Gunner](https://www.philadelphiaeagles.com/news/spadaro-the-gunner-dirty-nasty-job-the-eagles-do-very-well):

“They’re the guys who line up wide on punts, often face double-team blocking, get the snot knocked out of them after the ball is snapped, and then, once they break free from the blocks, have to sprint 50, 60 yards and get to the punt return man in time to halt any progress.”

The goal of my analysis is to [build on the initial research done by Michael Lopez](https://operations.nfl.com/gameday/analytics/stats-articles/visualizing-the-special-teams-gunner/) to add specific metrics to evaluate Gunners in the NFL based on available tracking data.

We will be using 2020 tracking and scouting information to create four metrics to evaluate Gunner effectiveness during punts. The metrics are:
1. **Tackle Opportunity Probability Added (TOPA)**: The difference in expected probability of getting a tackle opportunity added from snap to punt received
2. **Gunner’s Distance to Ball at Punt Reception Under Expected (BDUE)**: The difference in Gunner’s x-position to ball versus what was expected
3. **Return Yards Under Expected (RYUE)**: The difference in actual return yards versus what was expected based on the Gunner’s location metrics at punt reception
4. **Return Yards Under Exepcted (Non-Fair Catch Punts)**: The difference in actual return yards versus what was expected based on the Gunner’s location metrics at punt reception for non-fair catch punts
These four metrics will help to measure which gunners help to limit the opposing team’s starting position.

# Tackle Opportunity Probability Added (TOPA)

The animated play below shows a 3-yard punt return where two Gunners, Nsimba Webster (#14) and David Long (#25) close in on the punt returner to limit his overall yardage and do their best to tackle the returner. In this example, Webster is credited with the tackle. This visual helps to portray a common punt scenario so we will use this play to illustrate gunner effectiveness throughout the rest of this paper. First, we want to define tackle opportunity as the gunner’s involvement of a tackle either being the primary tackler, assisted tackler, or even having a missed tackle. Including assisted tacklers and missed tacklers helps to get a larger sample size of Gunners who were involved in tackling plays.

<img src="https://github.com/qmaclean/BDB_22/blob/master/viz_images/initial_animation.gif" width="100%" />

