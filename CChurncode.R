# Load necessary libraries
library(ggplot2)
library(gridExtra)
library(leaps)
library(glmnet)
library(pls)
library(randomForest)
library(neuralnet)
library(caret)

# Load data
data <- read.csv("C:/Users/kumar/CustomerChurn.csv")
View(data)

# Exploratory Data Analysis
plot(data)
head(data)
dim(data)
names(data)
summary(data)

# Correlation matrix (remove non-numeric columns if present)
cor(data[sapply(data, is.numeric)])

# Histogram of Customer.Value
hist(data$Customer.Value, main = "Histogram of Customer Value", xlab = "Customer Value", col = "skyblue")

# Boxplot of Customer.Value by Tariff.Plan
boxplot(data$Customer.Value ~ data$Tariff.Plan, main = "Customer Value by Tariff Plan",
        xlab = "Tariff Plan", ylab = "Customer Value")

# Scatter plot of Age vs Customer.Value
plot(data$Age, data$Customer.Value, main = "Age vs Customer Value",
     xlab = "Age", ylab = "Customer Value", col = "blue")

# ggplot Scatter plot
if("Tariff.Plan" %in% names(data)) {
  ggplot(data, aes(x = Age, y = Customer.Value, color = Tariff.Plan)) +
    geom_point() +
    labs(title = "Age vs Customer Value by Tariff Plan", x = "Age", y = "Customer Value")
}

# Aggregate Customer Value by Age Group
if("Age.Group" %in% names(data)) {
  aggregate(Customer.Value ~ Age.Group, data = data, FUN = mean)
}

# Splitting the data into training and testing sets
set.seed(1)
train <- sample(1:nrow(data), 0.7 * nrow(data))
test <- setdiff(1:nrow(data), train)

train_data <- data[train, ]
test_data <- data[test, ]

# Regression subsets
m1 <- regsubsets(Customer.Value ~ ., data = data)
summary(m1)

m2 <- regsubsets(Customer.Value ~ ., data = data, nvmax = 14)
s <- summary(m2)

# Plot Regression Subsets
par(mfrow = c(2, 2))
plot(s$rss, xlab = "Number of Variables", ylab = "RSS", type = "l", main = "RSS")
plot(s$adjr2, xlab = "Number of Variables", ylab = "Adjusted R-Squared", type = "l", main = "Adjusted R-Squared")
points(which.max(s$adjr2), max(s$adjr2), col = "red", cex = 2, pch = 20)
plot(s$cp, xlab = "Number of Variables", ylab = "Cp", type = "l", main = "Cp")
points(which.min(s$cp), min(s$cp), col = "red", cex = 2, pch = 20)
plot(s$bic, xlab = "Number of Variables", ylab = "BIC", type = "l", main = "BIC")
points(which.min(s$bic), min(s$bic), col = "red", cex = 2, pch = 20)

# Forward Selection
regfit.fwd <- regsubsets(Customer.Value ~ ., data = train_data, nvmax = 14, method = "forward")
summary(regfit.fwd)

# Backward Selection
regfit.bwd <- regsubsets(Customer.Value ~ ., data = train_data, nvmax = 14, method = "backward")
summary(regfit.bwd)

# Ridge Regression
if("Customer.Value" %in% names(data)) {
  polyX <- model.matrix(Customer.Value ~ ., data = data)[, -1]
  Y <- data$Customer.Value
  
  grid <- 10^seq(2, -5, length = 100)
  ridge_model <- glmnet(polyX[train, ], Y[train], alpha = 0, lambda = grid)
  ridge_pred <- predict(ridge_model, s = 4, newx = polyX[test, ])
  
  print("Ridge Regression MSE:")
  mean((ridge_pred - Y[test])^2)
  
  cv.out <- cv.glmnet(polyX[train, ], Y[train], alpha = 0)
  plot(cv.out)
  best_lambda <- cv.out$lambda.min
  log(best_lambda)
}

# Lasso Regression
lasso_model <- glmnet(polyX[train, ], Y[train], alpha = 1, lambda = grid)
lasso_pred <- predict(lasso_model, s = 4, newx = polyX[test, ])

print("Lasso Regression MSE:")
mean((lasso_pred - Y[test])^2)

# PCR
pcr.fit <- pcr(Y ~ ., data = as.data.frame(polyX), scale = TRUE, validation = "CV")
summary(pcr.fit)

# PCA
PCA <- prcomp(polyX, center = TRUE, scale. = TRUE)
plot(PCA)
summary(PCA)

# Random Forest
rf_model <- randomForest(x = train_data[, -ncol(train_data)],
                         y = train_data$Customer.Value,
                         ntree = 500, importance = TRUE)
rf_pred <- predict(rf_model, newdata = test_data[, -ncol(test_data)])

# Neural Network
#nn_model <- neuralnet(Customer.Value ~ ., data = train_data, hidden = c(5, 2), linear.output = TRUE)
#nn_pred <- compute(nn_model, test_data[, -ncol(test_data)])
#nn_pred <- nn_pred$net.result

# Visualization
# Ensure Age.Group and Tariff.Plan are factors
data$Age.Group <- factor(data$Age.Group)
data$Tariff.Plan <- factor(data$Tariff.Plan)

# Plot 1: Customer Value Distribution
plot1 <- ggplot(data, aes(x = Customer.Value)) +
  geom_histogram(fill = "skyblue", color = "black", bins = 30) +
  labs(title = "Customer Value Distribution", x = "Customer Value", y = "Frequency")

# Plot 2: Boxplot by Age Group
plot2 <- ggplot(data, aes(x = Age.Group, y = Customer.Value, fill = Age.Group)) +
  geom_boxplot() +
  labs(title = "Customer Value by Age Group", x = "Age Group", y = "Customer Value")

# Plot 3: Boxplot by Tariff Plan
plot3 <- ggplot(data, aes(x = Tariff.Plan, y = Customer.Value, fill = Tariff.Plan)) +
  geom_boxplot() +
  labs(title = "Customer Value by Tariff Plan", x = "Tariff Plan", y = "Customer Value")

# Plot 4: Scatter Plot of Seconds of Use vs Customer Value
if("Seconds.of.Use" %in% names(data)) {
  plot4 <- ggplot(data, aes(x = Seconds.of.Use, y = Customer.Value)) +
    geom_point(color = "darkorange") +
    labs(title = "Seconds of Use vs Customer Value", x = "Seconds of Use", y = "Customer Value")
}

# Arrange plots in a grid
grid.arrange(plot1, plot2, plot3, plot4, ncol = 2)
