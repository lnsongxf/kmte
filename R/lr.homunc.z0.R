lr.homunc.z0 <- function(fulldata, subdata, dimx) {

    # Dimension of fulldata
    dimfull <- dim(fulldata)[2]

    subdatakm <- subdata
    fulldatakm <- fulldata

    n.sub <- dim(subdatakm)[1]
    nfull <- dim(fulldata)[1]
    if (n.sub > 0) {

        ###########################################################
        ########### Necessary ingridients for the  ################
        ###########   linear represenation and     ################
        ###########         the bootstrap          ################
        ###########################################################
        # Compute integrand of gamma0
        h.sub <- stats::ecdf(subdatakm[, 1])
        distq.sub <- h.sub(subdatakm[, 1])
        # Avoid problem of numerator (this is just mechanical,
        #given that the last obs of gamma0 is zero)
        s1.sub <- ifelse(distq.sub == 1, 1e-06, 1 - distq.sub)
        nc.sub <- (1 - subdatakm[, 2])/s1.sub

        # Compute Gamma0
        indy1.sub <- outer(subdatakm[, 1], subdatakm[, 1], "<")

        # gamma0.sub is a n.sub x 1 matrix
        gamma0.sub <- exp((t(indy1.sub) %*% nc.sub)/n.sub)

        # Delete what I won't use to save memory
        rm(nc.sub, h.sub)

        # Leading term of the expansion for treated
        err <- subdatakm[, 1]/(1 - subdatakm[, (dimfull - 1)])
        tau.sub <- err * gamma0.sub * subdatakm[, 2]

        # Compute gamma1 and the second term of the expansion
        t.sub <- (outer(subdatakm[, 1], subdatakm[, 1], ">"))

        gamma1.sub <- ((t(t.sub) %*% tau.sub)/n.sub)

        # compute the gamma1
        gamma1.sub <- gamma1.sub/matrix(s1.sub)

        # Now, compute the second term of the expansion
        term2.sub <- gamma1.sub * matrix((1 - subdatakm[, 2]))

        # Now, compute gamma2 and the last term of the expansion
        gamma2.sub <- matrix((1 - subdatakm[, 2])/s1.sub)
        gamma2.sub <- gamma1.sub * gamma2.sub
        gamma2.sub <- (t(indy1.sub) %*% (gamma2.sub))/n.sub

        # This is the term of the asymptotic expansion free of
        # the estimation effect
        terms.sub <- tau.sub + term2.sub - gamma2.sub
        # First term is the id of observation
        terms.sub <- cbind(subdatakm[, dimfull], terms.sub)
        return(terms.sub)

    }
    if (n.sub == 0) {
        terms.sub <- matrix(0, nrow = 0, ncol = 2)
        return(terms.sub)
    }
}
