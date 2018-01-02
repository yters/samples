library(MASS)

# Function to generate noisey training and test data.
gen_data <- function(n) {
    x <- sort(runif(n))
    ytrue <- (cos(x) + 2) / (cos(1.4 * x) + 2)
    noise <- runif(n) * 0.2
    y <- ytrue + noise
    return(cbind(x,y))
}

# Euclidean distance function.
dist <- function(x1,x2) {
    result <- 0
    for(i in 1:length(x1)) {
        result <- result + (x1[i]-x2[i])^2
    }
    return(sqrt(result))
}

# A helper function to visualize progress.
plot_w <- function(x,y,w,plot_title,y_lim=c(0.8,1.4),x_lim=c(0,1)) {
    xt <- sort(runif(1000))
    plot(xt,colSums(mapply(function(x)eqn(x,w),xt)),pch='.',xlab='x',ylab='y',ylim=y_lim,xlim=x_lim)
    lines(xt,colSums(mapply(function(x)eqn(x,w),xt)))
    par(new=TRUE)
    plot(x,y,ylim=y_lim,xlim=x_lim)
    title(plot_title)
}

# Construct a polynomial equation from x values and weights.
eqn <- function(x, w) {
    result <- c()
    for (i in 1:length(w)) {
        result <- c(result, w[i] * x^(i-1))
    }
    return(result)
}

# Construct a polynomial equation from x values, without weights.
eqn_ <- function(x, w) {
    result <- c()
    for (i in 1:length(w)) {
        result <- c(result, x^(i-1))
    }
    return(result)
}

# Optimize the weights using regression method.
optimize <- function(x,y,func,lmbda,eta,its,w=rep(0,11),plot_title="",vis=TRUE) {
    for (i in 1:its) {
        w_ <- func(x,y,w,lmbda)
        w1 <- w - eta * w_
        d <- dist(w,w1)
        w <- w1
        
        if (vis && i%%10==0) plot_w(x,y,w,plot_title)
    }
    return(w)
}

# Detect if running in slave mode.  If so, turn off visualization.
slave <- FALSE
if ("--slave" %in% commandArgs()) slave <- TRUE

# Derivatives used for gradient descent optimization.
derv <- function(w) function(x,y) -2 * eqn_(x,w) * (y - sum(eqn(x,w)))
dEin <- function(x,y,w,lmbda) rowSums(mapply(derv(w),x,y))/length(x)

# Regularization methods.
lasso <- function(x,y,w,lmbda) rowSums(mapply(derv(w),x,y))/length(x) + lmbda*sign(w)
ridge <- function(x,y,w,lmbda) rowSums(mapply(derv(w),x,y))/length(x) + 2*lmbda*abs(w)
direct <- function(xs,ys,lmbda) ginv(xs %*% t(xs) + lmbda * diag(dim(xs)[1])) %*% xs %*% ys

# Generate training and test datasets.
data <- gen_data(100)
x_train <- data[,1]
y_train <- data[,2]

data <- gen_data(100)
x_test <- data[,1]
y_test <- data[,2]

# Set training parameters.
eta <- 0.1
iterations <- 100

# Train model.
w <- rep(0,11)
w <- optimize(x_train,y_train,dEin,0,eta,w=w,iterations,"Unregularized Gradient Descent")
Ein_err <- sum((w %*% apply(matrix(x_test,ncol=1), 1, function(x) eqn_(x,w)) - y_test)^2)
plot_w(x_train, y_train, w, paste("Unregularized Gradient Descent, MSE=",round(Ein_err,2),sep=""))
Sys.sleep(1)

lasso_augerr <- c()
lasso_err <- c()
ridge_augerr <- c()
ridge_err <- c()
direct_augerr <- c()
direct_err <- c()

# The different amounts of regularization to use.
data_points <- c(0.00001, 0.0001,0.0005,0.001,0.005,0.01,0.05,0.1,0.2,0.4,0.6,0.8,1) 

# Train a model with each regularization value.
for (lmbda in data_points) {
    # Trai
    w <- rep(0,11)
    w <- optimize(x_train,y_train,lasso,lmbda,eta,w=w,iterations,paste("LASSO Gradient Descent Regularized, Lambda=",lmbda,sep=""),vis=!slave)
    mse <- sum((w %*% apply(matrix(x_test,ncol=1), 1, function(x) eqn_(x,w)) - y_test)^2)
    if (!slave) plot_w(x_train, y_train, w, paste("LASSO Gradient Descent Regularized, Lambda=",lmbda,", Test MSE=",round(mse,2),sep=""))
    cat("LASSO Gradient Descent Regularized, ")
    cat(paste("Lambda:",lmbda,"Weights:",paste(w,collapse=" "),"Test Mean Squared Error:",mse,"\n"))
    lasso_augerr <- c(lasso_augerr, sum((w %*% apply(matrix(x_train,ncol=1), 1, function(x) eqn_(x,w)) - y_test)^2 + lmbda * sum(abs(w))))
    lasso_err <- c(lasso_err, mse)
    if (!slave) Sys.sleep(1)

    w <- rep(0,11)
    w <- optimize(x_train,y_train,ridge,lmbda,eta,w=w,iterations,paste("Ridge Gradient Descent Regularized, Lambda=",lmbda,sep=""),vis=!slave)
    mse <- sum((w %*% apply(matrix(x_test,ncol=1), 1, function(x) eqn_(x,w)) - y_test)^2)
    if (!slave) plot_w(x_train, y_train, w, paste("Ridge Gradient Descent Regularized, Lambda=",lmbda,", Test MSE=",round(mse,2),sep=""))
    cat("Ridge Gradient Descent Regularized, ")
    cat(paste("Lambda:",lmbda,"Weights:",paste(w,collapse=" "),"Test Mean Squared Error:",mse,"\n"))
    ridge_augerr <- c(ridge_augerr, sum((w %*% apply(matrix(x_train,ncol=1), 1, function(x) eqn_(x,w)) - y_test)^2 + lmbda * sum(w^2)))
    ridge_err <- c(ridge_err, mse)
    if (!slave) Sys.sleep(1)

    xs <- apply(matrix(x_train,ncol=1),1,function(x) eqn_(x,rep(0,11)))
    w <- direct(xs, y_train, lmbda)
    mse <- sum((t(w) %*% apply(matrix(x_test,ncol=1), 1, function(x) eqn_(x,w)) - y_test)^2)
    if (!slave) plot_w(x_train, y_train, w, paste("Ridge Pseudoinverse Regularized, Lambda=",lmbda,", Test MSE=",round(mse,2),sep=""))
    cat("Ridge Pseudoinverse Regularized, ")
    cat(paste("Lambda:",lmbda,"Weights:",paste(w,collapse=" "),"Test Mean Squared Error:",mse,"\n"))
    direct_augerr <- c(direct_augerr, sum((t(w) %*% apply(matrix(x_train,ncol=1), 1, function(x) eqn_(x,w)) - y_test)^2 + lmbda * sum(w^2)))
    direct_err <- c(direct_err, mse)
    if (!slave) Sys.sleep(1)
}

# Output comparison graphs
training_error_plot <- function() {
    source <- lasso_augerr
    plot(data_points,log(source),ylim=c(-1.1,5),pch='L',xlab="Lambda",ylab="log(Augmented Error)",log="x")
    lines(data_points,log(source),ylim=c(-1.1,5),xlab="Lambda",ylab="log(Augmented Error)")
    par(new=TRUE)
    source <- ridge_augerr
    plot(data_points,log(source),ylim=c(-1.1,5),pch='R',xlab="Lambda",ylab="log(Augmented Error)",log="x")
    lines(data_points,log(source),ylim=c(-1.1,5),xlab="Lambda",ylab="log(Augmented Error)")
    par(new=TRUE)
    source <- direct_augerr
    plot(data_points,log(source),ylim=c(-1.1,5),pch='P',xlab="Lambda",ylab="log(Augmented Error)",log="x")
    lines(data_points,log(source),ylim=c(-1.1,5),xlab="Lambda",ylab="log(Augmented Error)")
    abline(h=log(Ein_err),lty=6)
    legend("topleft", c("LASSO","Ridge","Pseudo"), pch=c("L","R","P"), cex = 1.0);
    title("Training Error")
}

if (!slave) {
    training_error_plot()
    Sys.sleep(4)
}

outfile <- "augment_lambda"
setEPS();
postscript(paste("./", outfile, ".eps", sep=""), onefile=FALSE);
training_error_plot()
dump <- dev.off()

testing_error_plot <- function() {
    source <- lasso_err
    plot(data_points,log(source),ylim=c(-1.1,3.2),pch='L',xlab="Lambda",ylab="log(Error)",log="x")
    lines(data_points,log(source),ylim=c(-1.1,3.2),xlab="Lambda",ylab="log(Error)")
    par(new=TRUE)
    source <- ridge_err
    plot(data_points,log(source),ylim=c(-1.1,3.2),pch='R',xlab="Lambda",ylab="log(Error)",log="x")
    lines(data_points,log(source),ylim=c(-1.1,3.2),xlab="Lambda",ylab="log(Error)")
    par(new=TRUE)
    source <- direct_err
    plot(data_points,log(source),ylim=c(-1.1,3.2),pch='P',xlab="Lambda",ylab="log(Error)",log="x")
    lines(data_points,log(source),ylim=c(-1.1,3.2),xlab="Lambda",ylab="log(Error)")
    abline(h=log(Ein_err),lty=6)
    legend("topleft", c("LASSO","Ridge","Pseudo"), pch=c("L","R","P"), cex = 1.0);
    text(1,-0.9,"MSE")
    title("Testing Error")
}

if (!slave) {
    testing_error_plot()
    Sys.sleep(4)
}

outfile <- "error_lambda"
setEPS();
postscript(paste("./", outfile, ".eps", sep=""), onefile=FALSE);
testing_error_plot()
dump <- dev.off()
