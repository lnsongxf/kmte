#' Tests for Homogeneous Conditional Local Average Treatment Effects
#'
#' \emph{hclate} computes Kolmogorov-Smirnov and Cramer-von Mises type tests
#' for the null hypothesis of homogeneous conditional local average treatment effects.
#' The test is suitable for both censored and uncensored outcomes, and relies on
#' the availability of a binary instrumental variable that satisfies additional assumptions.
#' For details of the testing procedure, see Sant'Anna (2016b),'Nonparametric Tests for
#' Treatment Effect Heterogeneity with Duration Outcomes'.
#'
#'@param out vector containing the outcome of interest
#'@param delta vector containing the censoring indicator (1 if observed, 0 if censored)
#'@param treat vector containing the treatment indicator (1 if treated, 0 if control)
#'@param inst vector containing the binary instrument
#'@param xvector matrix (or data frame) containing the conditioning covariates
#'@param xpscore matrix (or data frame) containing the covariates (and their
#'               transformations) to be included in the propensity score estimation
#'@param b number of bootstrap draws
#'@param cores number of cores to use during the bootstrap (default is 1).
#'        If cores>1, the bootstrap is conducted using parLapply, instead
#'        of lapply type call.
#'
#'@return a list containing the Kolmogorov-Smirnov test statistic (kstest),
#'        the Cramer-von Mises test statistic (cvmtest), and their associated
#'        bootstrapped p-values, pvks and pvcvm, respectively.
#'@export
#'@importFrom stats binomial ecdf glm rbinom runif
#'@importFrom MASS ginv
#'@importFrom parallel makeCluster parLapply stopCluster
#'@importFrom harvestr gather



hclate <- function(out, delta, treat, inst, xvector, xpscore, b, cores = 1) {
    # first, we merge all the data into a single datafile
    fulldata <- data.frame(cbind(out, delta, treat, inst, xvector, xpscore))
    # Compute Kaplan-Meier Weigths - data is now sorted!
    fulldata <- kmweight(1, 2, fulldata)
    # Dimension of data matrix fulldata
    dim.all <- dim(fulldata)[2]
    # Next, we rename the variable in xpscore to avoid problems Dimension of Xvector
    dimx <- dim(xvector)[2]
    # Where it ends
    dimxe <- 4 + dimx
    xpscore1 <- fulldata[, ((dimxe + 1):(dim.all - 1))]
    datascore <- data.frame(y = fulldata[, 4], xpscore1)
    # estimate the propensity score
    pscore <- glm(y ~ ., data = datascore, family = binomial("logit"), x = T)
    fulldata$pscore <- pscore$fit
    # fulldata$pscore=0.5

    # Create id to help on ordering
    fulldata$id <- 1:length(fulldata[, 1])

    # Dimension of data matrix fulldata
    dim.all <- dim(fulldata)[2]

    # sample size
    n.total <- as.numeric(length(fulldata[, 1]))
    #

    # subset of treated individuals with Z=1
    data.treat.1 <- subset(fulldata, fulldata[, 3] * fulldata[, 4] == 1)
    # subset of treated individuals with Z=0
    data.treat.0 <- subset(fulldata, fulldata[, 3] * (1 - fulldata[, 4]) == 1)

    # subset of not-treated individuals with Z=1
    data.control.1 <- subset(fulldata, (1 - fulldata[, 3]) * fulldata[, 4] == 1)

    # subset of not-treated individuals with Z=0
    data.control.0 <- subset(fulldata, (1 - fulldata[, 3]) * (1 - fulldata[, 4]) == 1)


    # Compute Kaplan-Meier weigth for treated with Z=1
    data.treat.1 <- kmweight(1, 2, data.treat.1)
    n.treat.1 <- as.numeric(length(data.treat.1[, 1]))
    data.treat.1$w <- data.treat.1$w * (n.treat.1/n.total)

    # Compute Kaplan-Meier weigth for treated with Z=0
    data.treat.0 <- kmweight(1, 2, data.treat.0)
    n.treat.0 <- as.numeric(length(data.treat.0[, 1]))
    data.treat.0$w <- data.treat.0$w * (n.treat.0/n.total)

    # Compute Kaplan-Meier weigth for control with Z=1
    data.control.1 <- kmweight(1, 2, data.control.1)
    n.control.1 <- as.numeric(length(data.control.1[, 1]))
    data.control.1$w <- data.control.1$w * (n.control.1/n.total)

    # Compute Kaplan-Meier weigth for control with Z=0
    data.control.0 <- kmweight(1, 2, data.control.0)
    n.control.0 <- as.numeric(length(data.control.0[, 1]))
    data.control.0$w <- data.control.0$w * (n.control.0/n.total)

    # Let's put everything in a single data - correct KM weigths First, the datasets
    fulldata <- data.frame(rbind(data.treat.1, data.treat.0, data.control.1, data.control.0))
    # Sort wrt id
    fulldata <- fulldata[order(as.numeric(fulldata[, dim.all])), ]


    # Compute the indicators needed for the computation of the test
    indx <- outer(fulldata[, 5], fulldata[, 5], "<=")
    # Dimension of X
    dimx <- dim(xvector)[2]
    dimxe <- 4 + dimx
    if (dimx > 1) {
        for (i in 6:dimxe) {
            indx <- indx * outer(fulldata[, i], fulldata[, i], "<=")
        }
    }
    ind <- indx
    # Compute unconditional LATE
    wps1 <- fulldata[, 3] * ((fulldata[, 4]/fulldata[, (dim.all - 1)]) - (((1 - fulldata[, 4])/(1 -
        fulldata[, (dim.all - 1)]))))

    wps0 <- -(1 - fulldata[, 3]) * ((fulldata[, 4]/fulldata[, (dim.all - 1)]) - (((1 - fulldata[,
        4])/(1 - fulldata[, (dim.all - 1)]))))

    num.1 <- fulldata[, 3] * fulldata[, 4]/fulldata[, (dim.all - 1)]
    num.0 <- fulldata[, 3] * (1 - fulldata[, 4])/(1 - fulldata[, (dim.all - 1)])
    late <- sum((wps1 - wps0) * fulldata[, 1] * fulldata[, (dim.all - 2)])/sum((num.1 - num.0) *
        fulldata[, (dim.all - 2)])
    late <- matrix(rep(late, n.total), n.total)

    # We now compute the test statistic

    testdist <- (wps1 - wps0) * (fulldata[, 1] - fulldata[, 3] * late) * fulldata[, (dim.all - 2)]
    testdist <- matrix(rep(testdist, n.total), n.total)
    testdist <- testdist * ind
    testdist <- colSums(testdist)

    kstest <- (n.total^0.5) * max(abs(testdist))
    cvmtest <- sum(testdist^2)
    # linear representation for these sub-samples
    linrep.treat.1 <- lr.hom.treat.z1(fulldata = fulldata, subdata = data.treat.1, dimx = dimx, late = late)

    linrep.treat.0 <- lr.hom.treat.z0(fulldata = fulldata, subdata = data.treat.0, dimx = dimx, late = late)

    linrep.control.1 <- lr.hom.control.z1(fulldata = fulldata, subdata = data.control.1, dimx = dimx,
        late = late)
    linrep.control.0 <- lr.hom.control.z0(fulldata = fulldata, subdata = data.control.0, dimx = dimx,
        late = late)
    # Let's put the linear represenations in a single matrix
    linrep.tau <- rbind(linrep.treat.1, -linrep.treat.0, linrep.control.1, -linrep.control.0)
    # sort linrep.merged wrt id
    linrep.tau <- linrep.tau[order(as.numeric(abs(linrep.tau[, 1]))), ]
    linrep.tau <- linrep.tau[, -1]

    # Now, the unconditional one
    linrep.unc.treat.1 <- lr.homunc.z1(fulldata = fulldata, subdata = data.treat.1, dimx = dimx)

    linrep.unc.treat.0 <- lr.homunc.z0(fulldata = fulldata, subdata = data.treat.0, dimx = dimx)

    linrep.unc.control.1 <- lr.homunc.z1(fulldata = fulldata, subdata = data.control.1, dimx = dimx)
    linrep.unc.control.0 <- lr.homunc.z0(fulldata = fulldata, subdata = data.control.0, dimx = dimx)
    # Let's put the linear represenations in a single matrix
    linrep.unc.tau <- rbind(linrep.unc.treat.1, -linrep.unc.treat.0, linrep.unc.control.1, -linrep.unc.control.0)

    # sort linrep.merged wrt id
    linrep.unc.tau <- linrep.unc.tau[order(as.numeric(abs(linrep.unc.tau[, 1]))), ]
    linrep.unc.tau <- linrep.unc.tau[, -1]

    # Now, we must match the dimensions for the unconditional ones
    linrep.unc.tau <- matrix(rep(linrep.unc.tau, n.total), n.total, n.total)

    # Remove what we won't need
    rm(linrep.treat.1, linrep.control.1, linrep.unc.treat.1, linrep.unc.control.1, linrep.treat.0,
        linrep.control.0, linrep.unc.treat.0, linrep.unc.control.0)
    # Now, the estimation effect Prepare the matrix
    matest <- pscore$x
    # X'X
    mat1 <- (t(matest)) %*% matest
    mat1 <- mat1/n.total
    # (X'X)^-1
    mat1inv <- MASS::ginv(mat1)

    # Compute the terms in the 'Y'
    wt <- fulldata[, 4]/(fulldata[, (dim.all - 1)]^2)
    wc <- (1 - fulldata[, 4])/((1 - fulldata[, (dim.all - 1)])^2)

    yest <- (wt + wc) * fulldata[, (dim.all - 2)] * (fulldata[, 1] - fulldata[, 3] * late[, 1])
    yest <- matrix(rep(yest, n.total), n.total)
    yest <- yest * ind

    # X'Y
    xy <- (t(matest)) %*% yest

    # Beta1=(X'X)^-1 (X'Y)
    beta1 <- mat1inv %*% xy

    # Compute the 'prediction) X*Beta1
    esteff1 <- matest %*% beta1
    # Now, compute the estimation effect of the pscore
    esteff <- fulldata[, 4] - fulldata[, (dim.all - 1)]
    esteff <- matrix(rep(esteff, n.total), n.total)
    esteff <- esteff * esteff1

    # Remove what we won't need
    rm(esteff1, yest)

    # Now the estimation effect of the unconditiona part
    yest.unc <- (wt + wc) * fulldata[, (dim.all - 2)] * fulldata[, 1]

    # X'Y
    xy.unc <- (t(matest)) %*% yest.unc

    # Beta1=(X'X)^-1 (X'Y)
    beta1.unc <- mat1inv %*% xy.unc

    # Compute the 'prediction) X*Beta1
    esteff1.unc <- matest %*% beta1.unc


    # Now, compute the estimation effect of the pscore
    esteff.unc <- fulldata[, 4] - fulldata[, (dim.all - 1)]
    esteff.unc <- esteff.unc * esteff1.unc
    esteff.unc <- matrix(rep(esteff.unc, n.total), n.total)

    # Remove what we won't need
    rm(esteff1.unc, yest.unc, xy.unc, beta1.unc, mat1, matest, mat1inv)

    # Now, we plug in everything to get the linear represenation that we will bootstrap!
    taudist1 <- (linrep.tau - esteff)
    # taudist1=(linrep.tau)
    fx <- colSums(ind * wps1 * fulldata[, (dim.all - 2)])
    fx <- t(matrix(rep(fx, n.total), n.total, n.total))
    taudist.unc <- (linrep.unc.tau - matrix(late, n.total, n.total) - esteff.unc) * fx
    # taudist.unc=linrep.unc.tau*fx-as.numeric(ate)*fx
    rm(fx)
    taudist <- (taudist1 - taudist.unc)/n.total
    rm(taudist1, taudist.unc, linrep.tau, linrep.unc.tau)
    # Remove what I won't use
    rm(esteff, ind, fulldata, data.treat.1, data.control.1, data.treat.0, data.control.0)
    # Now, the bootstrap Number of bootstrap draws
    nboot <- b

    if (cores==1){
      tests <- b.km(n.total = n.total, taudist = taudist,
                    nboot = nboot, kstest = kstest, cvmtest = cvmtest)
    }
    if (cores>1){
      tests <- b.km.mult(n.total = n.total, taudist = taudist,
                         nboot = nboot, kstest = kstest,
                         cvmtest = cvmtest, cores = cores)
    }
    # remove what I do not need
    rm(taudist)

    # Return these
    list(kstest = tests$kstest, cvmtest = tests$cvmtest, pvks = tests$pvks, pvcvm = tests$pvcvm)
}

