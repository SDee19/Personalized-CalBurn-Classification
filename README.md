![Walking-Calories-Calculator](https://github.com/user-attachments/assets/0c4b8e06-361b-4c80-af07-f8747181d0de)

# Personalized-Cal-Burn-Classification

Personalized calorie expenditure categorization represents a significant application of data science, focusing on assigning an individual's calorie burn into predefined levels based on a range of factors, either in real-time or across various workouts. Increasingly used by fitness enthusiasts and professionals, it aims to enhance workout understanding and support fitness goals by delivering customized calorie burn levels tailored to individual profiles, workout characteristics, and physiological data. This technology has grown increasingly important across multiple fitness domains, including weight management, athletic performance, rehabilitation, and general wellness, by utilizing large datasets to produce actionable, adaptive categorizations aligned with dynamic workout conditions and personal requirements.

The goal centers on developing a classification model that provides a detailed understanding of the factors influencing calorie expenditure, ultimately supporting its optimization for a wide array of users through the web product "𝗕𝘂𝗿𝗻𝗜𝘁𝗨𝗽".

# Description of the Question

"𝗪𝗵𝗮𝘁 𝗰𝗼𝗺𝗯𝗶𝗻𝗮𝘁𝗶𝗼𝗻 𝗼𝗳 𝗳𝗮𝗰𝘁𝗼𝗿𝘀 𝗺𝗼𝘀𝘁 𝘀𝗶𝗴𝗻𝗶𝗳𝗶𝗰𝗮𝗻𝘁𝗹𝘆 𝗽𝗿𝗲𝗱𝗶𝗰𝘁𝘀 𝘁𝗵𝗲 𝗰𝗮𝘁𝗲𝗴𝗼𝗿𝘆 𝗼𝗳 𝗰𝗮𝗹𝗼𝗿𝗶𝗲𝘀 𝗯𝘂𝗿𝗻𝗲𝗱 𝗱𝘂𝗿𝗶𝗻𝗴 𝗮 𝘄𝗼𝗿𝗸𝗼𝘂𝘁 𝗽𝗲𝗿𝗶𝗼𝗱 𝗳𝗼𝗿 𝗱𝗶𝗳𝗳𝗲𝗿𝗲𝗻𝘁 𝗱𝗲𝗺𝗼𝗴𝗿𝗮𝗽𝗵𝗶𝗰 𝗴𝗿𝗼𝘂𝗽𝘀?"

One of the key challenges in fitness tracking is understanding the factors that influence workout efficiency, particularly calorie burn level, which is a critical metric for individuals aiming to achieve weight loss, improve cardiovascular health, or maintain overall fitness. Traditional methods of estimating calorie burn rely on generalized formulas that consider only a few variables, such as age, weight, and workout duration. However, these methods often fail to account for the complex interplay of factors such as workout intensity, heart rate, body composition, and lifestyle habits, which can significantly impact the accuracy of calorie burn level assignments. To address this challenge, modern fitness apps and devices require a data-driven approach to analyze user data and provide personalized insights.

# Description of the Dataset

The "𝗪𝗼𝗿𝗸𝗼𝘂𝘁 & 𝗙𝗶𝘁𝗻𝗲𝘀𝘀 𝗧𝗿𝗮𝗰𝗸𝗲𝗿" dataset retrieved from Kaggle website comprises a dataset of 10,000 records, each representing a workout session. These records contain 20 distinct variables, encompassing a range of fitness metrics such as workout type, duration, caloric expenditure, cardiovascular activity, and movement data.

<img width="1114" height="779" alt="Screenshot 2026-03-29 191355" src="https://github.com/user-attachments/assets/ed94fc6b-99f3-4555-864f-dc51a96b2a60" />

# Conclusions and Discussion

1. 𝗘𝘅𝗽𝗹𝗼𝗿𝗮𝘁𝗼𝗿𝘆 𝗗𝗮𝘁𝗮 𝗔𝗻𝗮𝗹𝘆𝘀𝗶𝘀 (𝗘𝗗𝗔)
   
   The predictive modeling of "𝗖𝗮𝗹𝗼𝗿𝗶𝗲𝘀 𝗕𝘂𝗿𝗻𝗲𝗱" presented both analytical and methodological challenges, driven primarily by the nature of the target variable and the complexity of physiological interactions within the dataset. The target variable’s distribution, resembling a uniform shape with minimal skewness, rendered traditional regression approaches less effective. Standard transformations ("𝗹𝗼𝗴", "𝘀𝗾𝘂𝗮𝗿𝗲 𝗿𝗼𝗼𝘁") did little to normalize the distribution, leading to violations of homoscedasticity and residual normality assumptions crucial to parametric models.

2. 𝗔𝗱𝘃𝗮𝗻𝗰𝗲𝗱 𝗔𝗻𝗮𝗹𝘆𝘀𝗶𝘀

   To address these limitations, the analysis evolved toward a tier-based classification framework, allowing the modeling process to reflect meaningful stratifications in calorie expenditure ("𝗟𝗼𝘄", "𝗠𝗲𝗱𝗶𝘂𝗺-𝗟𝗼𝘄", "𝗠𝗲𝗱𝗶𝘂𝗺-𝗛𝗶𝗴𝗵", and "𝗛𝗶𝗴𝗵"). Advanced ensemble models, particularly "𝗫𝗚𝗕𝗼𝗼𝘀𝘁", were employed to capture the non-linearities and intricate interdependencies among features. These models substantially improved both performance and generalizability, with "𝗫𝗚𝗕𝗼𝗼𝘀𝘁" emerging as the most accurate, boasting a test accuracy "F1 score" of 0.9894.

   Despite these advancements, challenges remained—most notably, classification ambiguity within adjacent calorie burn tiers, especially between "𝗠𝗲𝗱𝗶𝘂𝗺-𝗟𝗼𝘄" and "𝗠𝗲𝗱𝗶𝘂𝗺-𝗛𝗶𝗴𝗵" categories. Misclassifications in these regions highlighted natural overlaps in physiological profiles. This was mitigated through a tier classification pipeline that assigned probabilities to each calorie burn class, followed by blended predictions from tier-specialized models, enhancing robustness near category boundaries.

   An analysis of feature importance from the optimal ‘XGBoost’ model provided critical insights into the drivers of calorie expenditure. "𝗠𝗲𝘁𝗮𝗯𝗼𝗹𝗶𝗰 𝗜𝗻𝘁𝗲𝗻𝘀𝗶𝘁𝘆" emerged as the dominant predictor, with an importance score of 66.798, more than 1.7 times greater than the second most influential feature, "𝗪𝗼𝗿𝗸𝗼𝘂𝘁 𝗗𝘂𝗿𝗮𝘁𝗶𝗼𝗻" (39.067). These two features accounted for the vast majority of model influence, affirming the centrality of exercise intensity and session length in determining caloric output. In contrast, features such as "𝗪𝗲𝗶𝗴𝗵𝘁" (11.384) and "𝗕𝗠𝗜" (2.725) played secondary roles, while commonly tracked health indicators—including steps, heart rate metrics, sleep duration, and even calorie intake—showed minimal contribution (typically <1.5 in importance scores). This skewed importance distribution reinforces the model’s reliance on core activity-based metrics rather than peripheral health data.

In conclusion, the combined approach of feature engineering, tier-specific modeling, and robust ensemble classification proved highly effective in predicting calorie burn categories. The study not only underscores the superiority of "𝗫𝗚𝗕𝗼𝗼𝘀𝘁" in this context but also highlights the central role of metabolic intensity and workout duration as reliable, physiologically grounded predictors. These insights have practical implications for personalized fitness recommendations, allowing more targeted and interpretable feedback for users aiming to optimize their workouts and health outcomes.

For our data product "𝗕𝘂𝗿𝗻𝗜𝘁𝗨𝗽", shifting from a precise calorie estimation ("You will burn approximately X calories") to a categorical prediction ("Your workout will likely result in a HIGH/MEDIUM/LOW calorie burn") offers a more user-centric and realistic experience. This revised approach acknowledges the inherent complexities and variability in individual calorie expenditure, thereby mitigating potential user perceptions of inaccuracy associated with a specific numerical value. By providing a broader, more actionable categorization, users can still effectively gauge the intensity and potential outcome of their workouts without being anchored to a potentially misleadingly precise figure. This change prioritizes providing useful directional guidance over a seemingly definitive but potentially flawed calculation, ultimately enhancing user trust and the perceived value of the data product.

# BurnItUp - 𝑼𝒏𝒍𝒐𝒄𝒌 𝒕𝒉𝒆 𝒑𝒐𝒘𝒆𝒓 𝒐𝒇 𝒚𝒐𝒖𝒓 𝒘𝒐𝒓𝒌𝒐𝒖𝒕𝒔...

1. 𝗦𝗶𝗴𝗻-𝗶𝗻 𝗣𝗮𝗴𝗲

   <img width="1919" height="904" alt="Screenshot 2026-03-29 204919" src="https://github.com/user-attachments/assets/5fa333e0-f144-405f-a456-4a3513016631" />

2. 𝗦𝗶𝗴𝗻-𝘂𝗽 𝗣𝗮𝗴𝗲

   <img width="1919" height="902" alt="Screenshot 2026-03-29 204930" src="https://github.com/user-attachments/assets/f212a142-c5b6-4585-88c1-6257030a8550" />

3. 𝗛𝗼𝗺𝗲 𝗣𝗮𝗴𝗲

   <img width="1919" height="906" alt="Screenshot 2026-03-29 205016" src="https://github.com/user-attachments/assets/ed56675d-9c55-469c-b3d6-212b3c77d3d8" />

   <img width="1919" height="905" alt="Screenshot 2026-03-29 205050" src="https://github.com/user-attachments/assets/126e9952-fc42-4172-8119-fce820147c24" />

   <img width="1919" height="906" alt="Screenshot 2026-03-29 205107" src="https://github.com/user-attachments/assets/7f01a71c-318f-4377-978b-7cdf548d0bc6" />

   <img width="1919" height="686" alt="Screenshot 2026-03-29 205201" src="https://github.com/user-attachments/assets/f2358c19-beab-4ba4-af79-e0931fbd6726" />

4. 𝗖𝗮𝗹𝗼𝗿𝘆 𝗖𝗼𝘂𝗻𝘁𝗲𝗿

   <img width="1919" height="904" alt="Screenshot 2026-03-29 205637" src="https://github.com/user-attachments/assets/84fb6e30-e1ef-489a-a00e-3f9fa548175d" />

   <img width="1916" height="513" alt="Screenshot 2026-03-29 205701" src="https://github.com/user-attachments/assets/c539e81f-401b-4d49-9cb3-674765b580d2" />

   <img width="1919" height="857" alt="Screenshot 2026-03-29 205746" src="https://github.com/user-attachments/assets/f95956e6-fb9a-4e81-a495-54fe0443240f" />

   <img width="1919" height="840" alt="Screenshot 2026-03-29 205849" src="https://github.com/user-attachments/assets/aef12d03-0678-471d-8bd3-fd318c89ace5" />

5. 𝗖𝗼𝗻𝘁𝗮𝗰𝘁 𝗨𝘀 𝗣𝗮𝗴𝗲

   <img width="1919" height="823" alt="Screenshot 2026-03-29 210443" src="https://github.com/user-attachments/assets/7a185d72-b7ac-499c-ba1c-e5e9aec210ed" />

   <img width="1919" height="446" alt="Screenshot 2026-03-29 210457" src="https://github.com/user-attachments/assets/11bca394-30b7-4ae0-98d6-937d0d160427" />

6. 𝗔𝗯𝗼𝘂𝘁 𝗨𝘀 𝗣𝗮𝗴𝗲

   <img width="1919" height="641" alt="Screenshot 2026-03-29 210513" src="https://github.com/user-attachments/assets/4399efef-61c5-44c8-bce4-cff0f704e9d4" />

   <img width="1919" height="889" alt="Screenshot 2026-03-29 210525" src="https://github.com/user-attachments/assets/e722f2f4-734c-46b6-b789-0c479616aa5e" />






