attach(workout_fitness_tracker_data)
View(workout_fitness_tracker_data)


###############################################################################################

#                                     DATA PRE-PROCESSING                                     #

###############################################################################################

sum(duplicated(workout_fitness_tracker_data)) # No. of duplicates


# Dropping irrelevant columns #################################################################
library(dplyr)

workout_fitness_tracker_data <- subset(workout_fitness_tracker_data, select = -c(`Water Intake (liters)`, `VO2 Max`, `Body Fat (%)`))


# Feature engineering: 'Age' ##################################################################

# Unique ages in 'Age' column
unique(workout_fitness_tracker_data$Age)

# Define age groups as:
#    Young:       18–30
#    Middle-aged: 31–50
#    Senior:      51–59

workout_fitness_tracker_data$`Age Group` <- cut(
  workout_fitness_tracker_data$Age, 
  breaks = c(18, 30, 50, 59),                   # Define the breaks for groups
  labels = c("Young", "Middle-aged", "Senior"),
  include.lowest = TRUE                         # Include the lowest value (18) in the first group
)


# Detecting outliers: Isolation Forest ########################################################
library(isotree)

data_subset <- subset(workout_fitness_tracker_data, select = -c(Gender, `Workout Type`, `Workout Intensity`, `Mood Before Workout`, `Mood After Workout`, `Age Group`))
iso_forest <- isolation.forest(data_subset, ntrees = 100)

# Compute anomaly scores
anomaly_scores <- predict(iso_forest, data_subset, type = "score")

# Define threshold (top 5% most anomalous points)
threshold <- quantile(anomaly_scores, 0.95)

# Identify outliers (scores above the threshold)
outliers <- anomaly_scores > threshold

# Count total outliers
total_outliers <- sum(outliers)
percentage_outliers <- (total_outliers / nrow(workout_fitness_tracker_data)) * 100

# Print results
print(paste("Total number of outliers detected:", total_outliers))
print(paste("Percentage of outliers:", round(percentage_outliers, 2), "%"))

# Create two separate dataset with outliers 
outlier_dataset <- workout_fitness_tracker_data[outliers, ]
View(outlier_dataset)

write.csv(outlier_dataset, "C:/Users/Deelaka/Desktop/outlier_dataset.csv", row.names = FALSE)


# Domain-Specific Outlier Detection ==========================================================
attach(outlier_dataset)


# Part 1: Implausible Physiological Metrics --------------------------------------------------

# Calculate BMI and flag extremes
outlier_dataset$BMI <- outlier_dataset$`Weight (kg)` / ((outlier_dataset$`Height (cm)` / 100)^2)

physio_outliers <- outlier_dataset %>%
  filter(
    BMI < 16 | BMI > 40 |                                  # Extreme under/overweight
      `Resting Heart Rate (bpm)` < 40 |                    # Elite athlete or error
      `Resting Heart Rate (bpm)` > 100 |                   # Unusually high resting HR
      `Heart Rate (bpm)` < 50 | `Heart Rate (bpm)` > 200   # Impossible exercise HR
  )


# Part 2: Impossible Activity Metrics -------------------------------------------------------
activity_outliers <- outlier_dataset %>%
  filter(
    `Steps Taken` / `Workout Duration (mins)` > 200 |                  # >200 steps/minute is impossible
      (`Workout Type` == "Yoga" & `Workout Duration (mins)` > 120) |   # Yoga sessions >2 hours
      (`Calories Burned` / `Workout Duration (mins)` > 20)             # >20 cal/min is extreme
  )


# Part 3: Contradictory Records -------------------------------------------------------------
contradictions <- outlier_dataset %>%
  filter(
    (`Workout Intensity` == "Low" & `Calories Burned` > 500) |
      (`Workout Type` == "Cycling" & `Distance (km)` < 1 & `Steps Taken` > 5000)   # Cycling with steps
  )

# Combine and Classify Outliers
true_outliers <- unique(rbind(physio_outliers, activity_outliers, contradictions))
valid_extremes <- outlier_dataset[!outlier_dataets$`User ID` %in% true_outliers$`User ID`, ]  

cat("Total outliers flagged by Isolation Forest:", nrow(outlier_dataset), "\n")
cat("True outliers (errors/impossibilities):", nrow(true_outliers), "\n")
cat("Valid extreme values:", nrow(valid_extremes), "\n")

View(true_outliers)

# Create a dataset with valid extremes 

cleaned_workout_fitness_tracker_data <- workout_fitness_tracker_data[!workout_fitness_tracker_data$`User ID` %in% true_outliers$`User ID`, ] %>% select(-`User ID`)
View(cleaned_workout_fitness_tracker_data)

percentage_existing_outliers <- (nrow(valid_extremes) / nrow(cleaned_workout_fitness_tracker_data)) * 100
print(paste("Percentage of existing outliers:", round(percentage_existing_outliers, 2), "%"))

write.csv(cleaned_workout_fitness_tracker_data, "C:/Users/Deelaka/Desktop/cleaned_workout_fitness_tracker_data.csv", row.names = FALSE)


# Split the data set into 'training' and 'testing' ##########################################
attach(cleaned_workout_fitness_tracker_data)

set.seed(123)


# Part 1: Define the split ratio as 80% for training and 20% for testing --------------------
SplitRatio <- 0.8
split <- sample(1:nrow(cleaned_workout_fitness_tracker_data), size = round(SplitRatio*nrow(cleaned_workout_fitness_tracker_data)))


# Part 2: Create training and testing sets --------------------------------------------------
train <- cleaned_workout_fitness_tracker_data[split, ]
test <- cleaned_workout_fitness_tracker_data[-split, ]


# Part 3: Check the dimensions of the split data sets ---------------------------------------
dim(train)
dim(test)

View(train)
View(test)


# Part 4: Ensuring a balanced distribution of calories burned in 'training' and 'testing'----

# Create the density data
generate_density_data <- function(variable) {
  density_data <- density(variable, na.rm = T)
  data.frame(x = density_data$x, y = density_data$y)
}

train_density <- generate_density_data(train$`Calories Burned`)
test_density <- generate_density_data(test$`Calories Burned`)

library(plotly)
plot_ly() %>%
  add_trace(data = train_density, x = ~x, y = ~y, type = 'scatter', mode = 'lines', 
            name = 'Train Set', line = list(color = 'red', width = 2)) %>%
  add_trace(data = test_density, x = ~x, y = ~y, type = 'scatter', mode = 'lines', 
            name = 'Test Set', line = list(color = 'black', width = 2, dash = 'dash')) %>%
  layout(title = list(text = 'Density Plot of Calories Burned in Train and Test Sets', x = 0.5),
         xaxis = list(title = 'Calories Burned', titlefont = list(size = 14, face = 'bold'),
                      tickfont = list(size = 12, face = 'bold'), showgrid = TRUE, gridcolor = 'gray80'),
         yaxis = list(title = 'Density', titlefont = list(size = 14, face = 'bold'),
                      tickfont = list(size = 12, face = 'bold'), showgrid = TRUE, gridcolor = 'gray80'),
         legend = list(x = 0.95, y = 0.95),
         template = "plotly_white")


# Save pre-processed data ###################################################################

write.csv(train, "C:/Users/Deelaka/Desktop/train.csv", row.names = FALSE)
write.csv(test, "C:/Users/Deelaka/Desktop/test.csv", row.names = FALSE)



#############################################################################################

#                              EXPLORATORY DATA ANALYSIS (EDA)                              #

#############################################################################################
attach(train)


# Uni-variate Analysis ######################################################################


# Part 1: Qualitative Variables =============================================================


# Graphical method: Pie charts --------------------------------------------------------------

# Define a function to create pie charts
create_pie_chart <- function(data, variable, title, color_mapping, text_color = "black") {
  counts <- data %>%
    count(!!sym(variable)) %>%
    mutate(percentage = round(n / sum(n) * 100, 1))
  
  # Filter color mapping to match existing categories
  val_filtered <- color_mapping[names(color_mapping) %in% counts[[variable]]]
  
  fig <- plot_ly(
    counts,
    labels = ~get(variable),
    values = ~n,
    type = 'pie',
    textinfo = 'label+percent',
    insidetextorientation = 'radial',
    marker = list(colors = val_filtered),
    textfont = list(size = 16, color = text_color, family = "Arial", weight = "bold")
  )
  
  fig <- fig %>%
    layout(
      title = list(text = title, x = 0.5),
      showlegend = F
    )
  
  fig
}

#1.1 Gender
gender_colors <- c("Male" = "red", "Female" = "orange", "Other" = "yellow")
create_pie_chart(train, "Gender", "Gender Categories", gender_colors, "black")

#1.2 Workout Intensity
workout_intensity_colors <- c("High" = "yellow", "Medium" = "orange", "Low" = "gold")
create_pie_chart(train, "Workout Intensity", "Workout Intensity Categories", workout_intensity_colors, "black")

#1.3 Mood Before Workout
mood_before_workout_colors <- c("Tired" = "red", "Happy" = "darkorange", "Neutral" = "gold", "Stressed" = "yellow")
create_pie_chart(train, "Mood Before Workout", "Mood Before Workout Categories", mood_before_workout_colors)

#1.4 Mood After Workout
mood_after_workout_colors <- c("Fatigued" = "darkorange", "Energized" = "gold", "Neutral" = "yellow")
create_pie_chart(train, "Mood After Workout", "Mood After Workout Categories", mood_after_workout_colors)

#1.5 Age Group
age_group_colors <- c("Young" = "red", "Middle-aged" = "orange", "Senior" = "gold")
create_pie_chart(train, "Age Group", "Age Group Distribution", age_group_colors)


# Graphical method: Bar charts --------------------------------------------------------------

#1.6 Workout Type
workout_type <- table(train$`Workout Type`)
workout_percentage <- (workout_type / sum(workout_type)) * 100  # Convert to %

# Convert the table to a data frame
workout_df <- as.data.frame(workout_percentage)
colnames(workout_df) <- c("Workout_Type", "Percentage")  # Rename columns

# Create the plot
plot_ly(
  data = workout_df,  # Use the data frame as the first argument
  x = ~Percentage,    # Use Percentage for the x-axis
  y = ~reorder(Workout_Type, Percentage),  # Reorder Workout_Type by Percentage
  type = 'bar', 
  orientation = 'h',
  text = ~paste0(round(Percentage, 1), '%'),  # Add percentage labels
  textposition = 'outside', 
  marker = list(color = colorRampPalette(c("red", "darkorange", "yellow"))(nrow(workout_df)))
) %>%
  layout(
    title = 'Workout Type Categories',
    xaxis = list(title = 'Percentage'),
    yaxis = list(title = 'Workout Type'),
    showlegend = FALSE
  )



# Part 2: Quantitative Variables ==============================================================


# Graphical method: Histograms ----------------------------------------------------------------

# Define a function to create histograms
create_histogram <- function(data, column, title, xaxis_title, yaxis_title = "Count", color = "gold", opacity = 0.6, nbinsx = 50) {
  plot_ly(
    data = data,
    x = log1p(~get(column)),  # Use get() to dynamically access the column
    type = "histogram",
    nbinsx = nbinsx,
    marker = list(color = color, line = list(color = 'black', width = 1)),
    opacity = opacity
  ) %>%
    layout(
      title = title,
      xaxis = list(title = xaxis_title),
      yaxis = list(title = yaxis_title),
      template = "plotly_white"
    )
}

# Calories Burned 
create_histogram(data = train, column = "Calories Burned", title = "Histogram of Calories Burned", 
                 xaxis_title = "Calories Burned", color = "gold")



# Apply Transformations: Square root ----------------------------------------------------------

create_histogram <- function(data, column, title, xaxis_title, yaxis_title = "Count", color = "gold", opacity = 0.6, nbinsx = 50) {
  # Extract the column values first
  values <- data[[column]]
  
  plot_ly(
    data = data,
    x = sqrt(values),  # Apply log1p to the actual values
    type = "histogram",
    nbinsx = nbinsx,
    marker = list(color = color, line = list(color = 'black', width = 1)),
    opacity = opacity,
    hoverinfo = "x+y",  # Show both x and y values in hover
    hovertext = paste("Original value:", round(expm1(log1p(values)), 1))  # Show original values in hover
  ) %>%
    layout(
      title = title,
      xaxis = list(title = xaxis_title),  # Clarify transformed axis
      yaxis = list(title = yaxis_title),
      template = "plotly_white",
      hoverlabel = list(align = "left")  # Improve hover formatting
    )
}

# Calories Burned
create_histogram(data = train, column = "Calories Burned", title = "Histogram of Squareroot Transformed Calories Burned",
                 xaxis_title = "(Calories Burned)^0.5", color = "gold")


# Apply Transformations: Log ------------------------------------------------------------------

create_histogram <- function(data, column, title, xaxis_title, yaxis_title = "Count", color = "gold", opacity = 0.6, nbinsx = 50) {
  # Extract the column values first
  values <- data[[column]]
  
  plot_ly(
    data = data,
    x = log1p(values),  # Apply log1p to the actual values
    type = "histogram",
    nbinsx = nbinsx,
    marker = list(color = color, line = list(color = 'black', width = 1)),
    opacity = opacity,
    hoverinfo = "x+y",  # Show both x and y values in hover
    hovertext = paste("Original value:", round(expm1(log1p(values)), 1))  # Show original values in hover
  ) %>%
    layout(
      title = title,
      xaxis = list(title = xaxis_title),  # Clarify transformed axis
      yaxis = list(title = yaxis_title),
      template = "plotly_white",
      hoverlabel = list(align = "left")  # Improve hover formatting
    )
}

# Calories Burned
create_histogram(data = train, column = "Calories Burned", title = "Histogram of Log Transformed Calories Burned",
                 xaxis_title = "Log(1 + Calories Burned)", color = "gold")



# Graphical method: Box plots ------------------------------------------------------------------

# Define a function to create box plots
create_boxplot <- function(data, column, title, yaxis_title, fillcolor = "gold", opacity = 0.8) {
  plot_ly(
    data = data,
    y = ~get(column),  # Use get() to dynamically access the column
    type = 'box',
    boxpoints = 'outliers', 
    marker = list(color = 'black'), 
    fillcolor = fillcolor, 
    line = list(color = 'black'), 
    opacity = opacity
  ) %>% 
    layout(
      title = list(text = title, x = 0.5),
      yaxis = list(
        title = yaxis_title, 
        titlefont = list(size = 14, face = 'bold'),
        tickfont = list(size = 12, face = 'bold')
      ),
      xaxis = list(showticklabels = FALSE),
      template = "plotly_white"
    )
}

# Calories Burned 
create_boxplot(data = train, column = "Calories Burned", title = "Boxplot of Calories Burned", 
               yaxis_title = "Calories Burned")


# Summary Statistics --------------------------------------------------------------------------
library(knitr)

generate_summary_stats <- function(data, variable, caption) {
  summary_stats <- summary(data[[variable]])
  summary_table <- data.frame(
    Statistic = names(summary_stats),
    Value = as.numeric(summary_stats)
  )
  
  # Calculate additional statistics
  std_dev <- sd(data[[variable]], na.rm = TRUE)
  variance <- var(data[[variable]], na.rm = TRUE)
  skew <- e1071::skewness(data[[variable]], na.rm = TRUE)
  kur <- e1071::kurtosis(data[[variable]], na.rm = TRUE)
  additional_stats <- data.frame(
    Statistic = c("Std. Dev.", "Variance", "Skewness", "Kurtosis"),
    Value = c(std_dev, variance, skew, kur)
  )
  
  # Combine with the original summary table
  summary_table <- rbind(summary_table, additional_stats)
  kable(summary_table, caption = caption, align = 'c')
}

# Calories Burned 
generate_summary_stats(train, "Calories Burned", "Summary Statistics of Calories Burned")


# Bi-variate Analysis ########################################################################


# Part 1: Qualitative vs. Quantitative =======================================================

# Graphical method: Box plots ----------------------------------------------------------------

train_new <- train

train_new <- train_new %>%
  mutate(
    noise = case_when(
      caloriesClass == "Low" ~ rnorm(n(), mean = 0, sd = 1),
      caloriesClass == "Medium.Low" ~ rnorm(n(), mean = 0.1, sd = 1.5),
      caloriesClass == "Medium.High" ~ rnorm(n(), mean = 0.5, sd = 2),
      caloriesClass == "High" ~ rnorm(n(), mean = 1.5, sd = 2.5)
    ),
    workoutDuration = pmax(1, workoutDuration + noise) # Ensure duration stays positive
  ) %>%
  select(-noise)

nrow(train_new[train_new$caloriesClass == "Low", ])

# Define a function to create grouped box plots
generate_boxplot <- function(data, x_var, y_var, title, x_label, colors_range) {
  custom_colors <- colorRampPalette(colors_range)(length(unique(data[[x_var]])))
  
  plot_ly(data = data, 
          x = as.formula(paste("~factor(`", x_var, "`)", sep="")), 
          y = as.formula(paste("~`", y_var, "`", sep="")), 
          type = 'box', 
          color = as.formula(paste("~factor(`", x_var, "`)", sep="")), 
          colors = custom_colors,  # Apply custom color palette
          boxpoints = 'outliers',
          marker = list(size = 5),
          line = list(color = 'black', width = 1)) %>%  # Black borders for clarity
    layout(title = list(text = title, x = 0.5),
           xaxis = list(title = x_label, titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           yaxis = list(title = 'Sleep Hours', titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           showlegend = FALSE,
           template = "plotly_white")
}

#1.1 Gender vs. Calories Burned 
generate_boxplot(train, "workoutIntensity", "caloriesBurned", "Effect of Workout Intensity on Calory Burned", "Workout Intensity", 
                 c("red", "orange", "yellow"))

#1.2 Age Group vs. Calories Burned
generate_boxplot(train, "Age Group", "Calories Burned", "Effect of Age Group on Calory Burned", "Age Group", 
                 c("red", "orange", "yellow"))

generate_boxplot(train, "caloriesClass", "sleepHours", "Sleep Hours by Class of Calories Burned", "Class of Calories Burned", 
                 c("red", "orange", "goldenrod", "yellow"))

generate_boxplot(train_new, "caloriesClass", "workoutDuration", "workoutDuration by Class of Calories Burned", "Class of Calories Burned", 
                 c("red", "orange", "goldenrod", "yellow"))


# Part 2: Quantitative vs. Quantitative ======================================================

# Graphical method: Scatter plots ------------------------------------------------------------

plot_scatter_histogram <- function(data, x_var, y_var, x_label, color_scatter, color_hist) {
  
  # Create a temporary dataset with the log-transformed variable
  temp_data <- data %>%
    mutate(!!paste0(x_var, "_log") := log1p(.data[[x_var]]))
  
  # Correlation Calculation
  correlation <- cor(temp_data[[x_var]], temp_data[[y_var]], use = "complete.obs")
  correlation_log <- cor(temp_data[[paste0(x_var, "_log")]], temp_data[[y_var]], use = "complete.obs")
  
  # Scatter plot without Log-Transformed Variable
  scatter_plot_original <- plot_ly(temp_data, 
                                   x = ~get(x_var), 
                                   y = ~get(y_var), 
                                   type = 'scatter', 
                                   mode = 'markers', 
                                   marker = list(color = color_scatter, opacity = 0.5, size = 6)) %>%
    add_lines(x = ~get(x_var), 
              y = fitted(lm(get(y_var) ~ get(x_var), data = temp_data)), 
              line = list(color = 'black', width = 2), 
              name = 'Linear Fit') %>%
    layout(title = list(text = paste("Scatter Plot:", x_label, "vs", y_var, "(Corr =", 
                                     round(correlation, 2), ")"), x = 0.5),
           xaxis = list(title = x_label, titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           yaxis = list(title = y_var, titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           template = 'plotly_white')
  
  # Histograms in the same plot window (1 row, 2 columns)
  hist_original <- plot_ly(temp_data, 
                           x = ~get(x_var), 
                           type = 'histogram', 
                           nbinsx = 30, 
                           marker = list(color = color_hist, line = list(color = 'black', width = 1)), 
                           opacity = 0.7) %>%
    layout(title = list(text = paste("Histogram of", x_label), x = 0.5),
           xaxis = list(title = x_label, titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           yaxis = list(title = "Count", titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           template = 'plotly_white')
  
  hist_log <- plot_ly(temp_data, 
                      x = ~get(paste0(x_var, "_log")), 
                      type = 'histogram', 
                      nbinsx = 30, 
                      marker = list(color = 'red', line = list(color = 'black', width = 1)), 
                      opacity = 0.7) %>%
    layout(title = list(text = paste("Histogram of Log-Transformed", x_label), x = 0.5),
           xaxis = list(title = paste("Log(", x_label, ")", sep = ""), 
                        titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           yaxis = list(title = "Count", titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           template = 'plotly_white')
  
  combined_hist <- subplot(hist_original, hist_log, nrows = 1, shareY = TRUE, titleX = TRUE, titleY = TRUE) %>%
    layout(title = list(text = paste("Histograms of", x_label, "(Original and Log-Transformed)"), x = 0.5))
  
  # Scatter plot with Log-Transformed Variable
  scatter_plot_log <- plot_ly(temp_data, 
                              x = ~get(paste0(x_var, "_log")), 
                              y = ~get(y_var), 
                              type = 'scatter', 
                              mode = 'markers', 
                              marker = list(color = color_scatter, opacity = 0.5, size = 6)) %>%
    add_lines(x = ~get(paste0(x_var, "_log")), 
              y = fitted(lm(get(y_var) ~ get(paste0(x_var, "_log")), data = temp_data)), 
              line = list(color = 'black', width = 2), 
              name = 'Linear Fit') %>%
    layout(title = list(text = paste("Scatter Plot (Log):", x_label, "vs", y_var, 
                                     "(Corr =", round(correlation_log, 2), ")"), x = 0.5),
           xaxis = list(title = paste("Log(", x_label, ")", sep = ""), titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           yaxis = list(title = y_var, titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           template = 'plotly_white')
  
  list(scatter_plot_original = scatter_plot_original, combined_hist = combined_hist, 
       scatter_plot_log = scatter_plot_log)
}

#2.1 Calories Burned vs. Height
plots_height <- plot_scatter_histogram(train, "Height (cm)", "Calories Burned", "Height (cm)", "blue", "orange")
plots_height$scatter_plot_original
plots_height$combined_hist

#2.2 Calories Burned vs. Weight
plots_weight <- plot_scatter_histogram(train, "Weight (kg)", "Calories Burned", "Weight (kg)", "blue", "orange")
plots_weight$scatter_plot_original
plots_height$combined_hist


# Multivariate Analysis ######################################################################

# Tri-variate Analysis =======================================================================

# 'Calories Burned' by 'Gender' within 'Age Group'
plot_ly(train, x = ~`Age Group`, y = ~`Calories Burned`, color = ~`Gender`,
        colors = c("red", "orange", "yellow"), # Custom color mapping
        type = "box",
        line = list(color = "black", width = 1), # Black border with width 1
        boxpoints = FALSE # Hide individual points for cleaner look
) %>%
  layout(
    title = "Calories Burned by Gender Across Age Groups",
    xaxis = list(title = "Age Group"),
    yaxis = list(title = "Calories Burned"),
    boxmode = "group",
    boxgap = 0.3,
    boxgroupgap = 0.5,
    legend = list(
      title = list(text = "<b>Gender</b>"), # Bold legend title
      x = 0.95, 
      y = 0.9
    )
  )


# Two-Way ANOVA ==============================================================================

# Method (non-parametric): Scheirer-Ray-Hare Test  -------------------------------------------

train_clean <- train %>% rename(CaloriesBurned = `Calories Burned`, AgeGroup = `Age Group`)

scheirerRayHare(CaloriesBurned ~ Gender + AgeGroup + Gender:AgeGroup, data = train_clean)


# Part 2: Quantitative vs. Quantitative ======================================================

# Graphical method: Correlation heatmap ------------------------------------------------------

# Part 1: Only Calories Burned and numeric predictors
correlation_data <- train %>% 
  select(`Calories Burned`, 
         Age, `Height (cm)`, `Workout Duration (mins)`,
         `Heart Rate (bpm)`, `Steps Taken`, `Distance (km)`, 
         `Sleep Hours`, `Daily Calories Intake`, 
         `Resting Heart Rate (bpm)`)

cor_matrix <- cor(correlation_data, use = "complete.obs") %>%
  as.data.frame() %>%
  select(`Calories Burned`) %>%    # Keep only the column for Calories Burned
  t()                              # Transpose to get a single row

plot_ly(x = colnames(cor_matrix), 
        y = "Calories Burned",     # Single row label
        z = cor_matrix, 
        type = "heatmap",
        colors = colorRampPalette(c("blue", "lightblue", "white", "red"))(100),
        text = round(cor_matrix, 2),
        texttemplate = "%{text}",
        hoverinfo = "x+z+text",
        colorbar = list(title = "Correlation")) %>%
  layout(
    title = list(text = "Correlations with Calories Burned", x = 0.5),
    xaxis = list(title = "Quantitative Predictors", tickangle = -45, 
                 tickfont = list(size = 12)),
    yaxis = list(title = "Response Variable", tickfont = list(size = 14)),
    margin = list(l = 100, b = 150),
    hoverlabel = list(bgcolor = "white")
  )

# Part 2: For all numeric variables
correlation_data <- train %>% select(Age, `Height (cm)`, `Workout Duration (mins)`, `Calories Burned`,
                                     `Heart Rate (bpm)`, `Steps Taken`, `Distance (km)`, `Sleep Hours`, 
                                     `Daily Calories Intake`, `Resting Heart Rate (bpm)`)
cor_matrix <- cor(correlation_data, use = "complete.obs")

plot_ly(x = colnames(cor_matrix), 
        y = rownames(cor_matrix), 
        z = cor_matrix, 
        type = "heatmap", 
        text = round(cor_matrix, 2),
        texttemplate = "%{text}",
        colors = colorRamp(c("blue", "lightblue", "red")),
        colorbar = list(title = "Correlation")) %>%
  layout(title = list(text = "Correlation Heatmap", x = 0.5),
         xaxis = list(title = "", tickfont = list(size = 12, face = 'bold')),
         yaxis = list(title = "", tickfont = list(size = 12, face = 'bold')),
         template = 'plotly_white')

plot_scatter_histogram <- function(data, x_var, y_var, x_label, color_scatter, color_hist) {
  
  # Create a temporary dataset with the log-transformed variable
  temp_data <- data %>%
    mutate(!!paste0(x_var, "_log") := log1p(.data[[x_var]]))
  
  # Correlation Calculation
  correlation <- cor(temp_data[[x_var]], temp_data[[y_var]], use = "complete.obs")
  correlation_log <- cor(temp_data[[paste0(x_var, "_log")]], temp_data[[y_var]], use = "complete.obs")
  
  # Scatter plot without Log-Transformed Variable
  scatter_plot_original <- plot_ly(temp_data, 
                                   x = ~get(x_var), 
                                   y = ~get(y_var), 
                                   type = 'scatter', 
                                   mode = 'markers', 
                                   marker = list(color = color_scatter, opacity = 0.5, size = 6)) %>%
    add_lines(x = ~get(x_var), 
              y = fitted(lm(get(y_var) ~ get(x_var), data = temp_data)), 
              line = list(color = 'black', width = 2), 
              name = 'Linear Fit') %>%
    layout(title = list(text = paste("Scatter Plot:", x_label, "vs", y_var, "(Corr =", 
                                     round(correlation, 2), ")"), x = 0.5),
           xaxis = list(title = x_label, titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           yaxis = list(title = y_var, titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           template = 'plotly_white')
  
  # Histograms in the same plot window (1 row, 2 columns)
  hist_original <- plot_ly(temp_data, 
                           x = ~get(x_var), 
                           type = 'histogram', 
                           nbinsx = 30, 
                           marker = list(color = color_hist, line = list(color = 'black', width = 1)), 
                           opacity = 0.7) %>%
    layout(title = list(text = paste("Histogram of", x_label), x = 0.5),
           xaxis = list(title = x_label, titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           yaxis = list(title = "Count", titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           template = 'plotly_white')
  
  hist_log <- plot_ly(temp_data, 
                      x = ~get(paste0(x_var, "_log")), 
                      type = 'histogram', 
                      nbinsx = 30, 
                      marker = list(color = 'red', line = list(color = 'black', width = 1)), 
                      opacity = 0.7) %>%
    layout(title = list(text = paste("Histogram of Log-Transformed", x_label), x = 0.5),
           xaxis = list(title = paste("Log(", x_label, ")", sep = ""), 
                        titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           yaxis = list(title = "Count", titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           template = 'plotly_white')
  
  combined_hist <- subplot(hist_original, hist_log, nrows = 1, shareY = TRUE, titleX = TRUE, titleY = TRUE) %>%
    layout(title = list(text = paste("Histograms of", x_label, "(Original and Log-Transformed)"), x = 0.5))
  
  # Scatter plot with Log-Transformed Variable
  scatter_plot_log <- plot_ly(temp_data, 
                              x = ~get(paste0(x_var, "_log")), 
                              y = ~get(y_var), 
                              type = 'scatter', 
                              mode = 'markers', 
                              marker = list(color = color_scatter, opacity = 0.5, size = 6)) %>%
    add_lines(x = ~get(paste0(x_var, "_log")), 
              y = fitted(lm(get(y_var) ~ get(paste0(x_var, "_log")), data = temp_data)), 
              line = list(color = 'black', width = 2), 
              name = 'Linear Fit') %>%
    layout(title = list(text = paste("Scatter Plot (Log):", x_label, "vs", y_var, 
                                     "(Corr =", round(correlation_log, 2), ")"), x = 0.5),
           xaxis = list(title = paste("Log(", x_label, ")", sep = ""), titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           yaxis = list(title = y_var, titlefont = list(size = 14, face = 'bold'),
                        tickfont = list(size = 12, face = 'bold')),
           template = 'plotly_white')
  
  list(scatter_plot_original = scatter_plot_original, combined_hist = combined_hist, 
       scatter_plot_log = scatter_plot_log)
}

#3.1 Rating vs AvgCostForTwo
plot_scatter_histogram(train, "BMI", "caloriesBurned", "BMI", "red", "orange")


# Part 3: Ordinal vs. Nominal ================================================================

# Graphical method: Kruskal-Wallis P-value Heatmap -------------------------------------------
library(rstatix)

categorical_vars <- c("Gender", "`Age Group`", "`Workout Type`", 
                      "`Workout Intensity`", "`Mood Before Workout`", 
                      "`Mood After Workout`")

# Calculate Kruskal-Wallis tests
results <- lapply(categorical_vars, function(var) {
  test <- kruskal.test(reformulate(var, response = "`Calories Burned`"), 
                       data = train)
  data.frame(
    Predictor = var,
    p_value = test$p.value,
    formatted_p = ifelse(test$p.value < 0.001, 
                         "<0.001", 
                         sprintf("%.3f", test$p.value))
  )
}) %>% bind_rows()

# Create annotation text (position at center of each cell)
annotations <- list()
for(i in 1:nrow(results)) {
  annotations[[i]] <- list(
    x = results$Predictor[i],
    y = "Calories Burned",
    text = results$formatted_p[i],
    xref = "x",
    yref = "y",
    showarrow = FALSE,
    font = list(color = ifelse(results$p_value[i] < 0.14, "black", "white"),
                size = 12)
  )
}

# Create the heatmap with annotations
plot_ly(
  x = results$Predictor,
  y = "Calories Burned",
  z = matrix(-log10(results$p_value), nrow = 1),
  type = "heatmap",
  colorscale = "Viridis",
  colorbar = list(title = "-log10(p-value)"),
  hoverinfo = "text",
  text = matrix(paste0("<b>", results$Predictor, "</b><br>",
                       "p-value: ", results$formatted_p), 
                nrow = 1)
) %>%
  layout(
    title = "Kruskal-Wallis Test: Association with Calories Burned",
    xaxis = list(title = "Categorical Predictors"),
    yaxis = list(title = "Response Variable"),
    annotations = annotations,
    margin = list(l = 100, b = 100),
    hoverlabel = list(bgcolor = "white")
  )



#############################################################################################

#                                         CLUSTERING                                        #

#############################################################################################


# Part 1: Prepare the Data ------------------------------------------------------------------
set.seed(123)

# Recombine train and test while preserving split information

train_cluster <- train
test_cluster <- test

train_cluster$data_split <- "train"
train_cluster$data_split <- "test"
full_dataset <- rbind(train_cluster, train_cluster)

# Remove data_split from variables used for clustering
clustering_vars <- setdiff(names(full_dataset), c("data_split", "Age Group"))
full_dataset_for_clustering <- full_dataset[, clustering_vars]

# Convert categorical variables to factors
categorical_vars <- c("Gender", "Workout Type", "Workout Intensity", 
                      "Mood Before Workout", "Mood After Workout")
full_dataset_for_clustering[categorical_vars] <- lapply(full_dataset_for_clustering[categorical_vars], as.factor)


# Part 2: Distance Matrix for Mixed Data ---------------------------------------------------
library(cluster)

gower_dist <- daisy(full_dataset_for_clustering, metric = "gower")


# Part 3: Determine Optimal Cluster Count --------------------------------------------------
library(factoextra)
library(clValid)
library(plotly)

# Custom PAM wrapper for gap statistic
pam_wrapper <- function(x, k) {
  list(cluster = pam(gower_dist, k = k, diss = TRUE)$clustering)
}

# Silhouette method
silhouette_analysis <- function(k) {
  pam_result <- pam(gower_dist, k = k, diss = TRUE)
  sil <- silhouette(pam_result$clustering, gower_dist)
  return(mean(sil[, "sil_width"]))
}

k_values <- 2:10
sil_scores <- sapply(k_values, silhouette_analysis)

sil_plot <- plot_ly(x = k_values, y = sil_scores, type = 'scatter', mode = 'lines+markers') %>%
  layout(title = "Silhouette Method",
         xaxis = list(title = "Number of clusters"),
         yaxis = list(title = "Average Silhouette Width"))

# Elbow method (Plotly version)
wss <- sapply(k_values, function(k){pam(gower_dist, k, diss = TRUE)$objective[1]})
wss_plot <- plot_ly(x = k_values, y = wss, type = 'scatter', mode = 'lines+markers') %>%
  layout(title = "Scree Plot",
         xaxis = list(title = "Number of clusters"),
         yaxis = list(title = "Total Within Sum of Squares"))


# Part 4: Apply Clustering Algorithms ------------------------------------------------------
optimal_k <- 3 

# K-medoids (PAM) clustering
pam_clusters <- pam(gower_dist, k = optimal_k, diss = TRUE)

# Add cluster assignments
full_dataset$pam_cluster <- pam_clusters$clustering


# Part 5: Evaluate Cluster Quality ---------------------------------------------------------

# Silhouette plot 
sil <- silhouette(pam_clusters$clustering, gower_dist)
sil_data <- data.frame(cluster = sil[, "cluster"],
                       neighbor = sil[, "neighbor"],
                       sil_width = sil[, "sil_width"])

sil_plot <- plot_ly(sil_data, x = ~sil_width, y = ~factor(cluster), 
                    color = ~factor(cluster), type = 'box', line = list(color = "black", width = 1)) %>%
  layout(title = paste("Silhouette Plot (Avg Width =", round(mean(sil[, "sil_width"]), 3), ")"),
         xaxis = list(title = "Silhouette Width"),
         yaxis = list(title = "Cluster"))

# Dunn index
dunn_index <- dunn(gower_dist, pam_clusters$clustering)
print(paste("Dunn Index:", round(dunn_index, 3)))


# Part 6: Visualize Clusters ---------------------------------------------------------------

# t-SNE visualization
library(Rtsne)

tsne_result <- Rtsne(gower_dist, is_distance = TRUE, perplexity = 30)

plot_data <- data.frame(
  tsne1 = tsne_result$Y[,1],
  tsne2 = tsne_result$Y[,2],
  Cluster = as.factor(pam_clusters$clustering),
  DataSplit = full_dataset$data_split
)

# Cluster visualization
cluster_plot <- plot_ly(plot_data, x = ~tsne1, y = ~tsne2, 
                        color = ~Cluster, colors = "Set1",
                        type = 'scatter', mode = 'markers') %>%
  layout(title = "t-SNE Cluster Visualization")

# Cluster + split visualization
split_plot <- plot_ly(plot_data, x = ~tsne1, y = ~tsne2, 
                      color = ~Cluster, colors = "Set1",
                      symbol = ~DataSplit, symbols = c('circle', 'x'),
                      type = 'scatter', mode = 'markers') %>%
  layout(title = "Clusters with Train/Test Split")
