# Teaching helpers. Deliberately small and readable: students are expected to
# be able to open these and see exactly what is being computed.

#' Spaghetti plot for longitudinal data
#'
#' One line per subject. Accepts either wide data (one row per subject, one
#' column per time) or long data (one row per observation) via \code{id},
#' \code{time} and \code{response}.
#'
#' @param data A data frame.
#' @param id,time,response Column names, as strings, for long-format data. Leave
#'   \code{NULL} for wide format.
#' @param group Optional grouping column; lines are coloured by it and a legend
#'   is drawn.
#' @param times Numeric times for wide format. Defaults to \code{1:ncol}.
#' @param col Line colour when \code{group} is \code{NULL}.
#' @param alpha Line opacity between 0 and 1.
#' @param ... Passed to \code{\link[graphics]{plot}}.
#'
#' @return Invisibly, the plotted data. Called for the side effect.
#' @export
#' @examples
#' data(cattle)
#' spaghetti_plot(cattle, group = "group")
#'
#' data(fev1)
#' spaghetti_plot(fev1, id = "id", time = "age", response = "logfev1_ht")
spaghetti_plot <- function(data, id = NULL, time = NULL, response = NULL,
                           group = NULL, times = NULL, col = "grey30",
                           alpha = 0.6, ...) {
  long <- !is.null(id) && !is.null(time) && !is.null(response)

  if (long) {
    for (nm in c(id, time, response)) {
      if (!nm %in% names(data)) stop("column '", nm, "' not found", call. = FALSE)
    }
    ids <- unique(data[[id]])
    xr  <- range(data[[time]],     na.rm = TRUE)
    yr  <- range(data[[response]], na.rm = TRUE)
    xlab <- time; ylab <- response
  } else {
    grp_vals <- if (!is.null(group)) data[[group]] else NULL
    mat <- data[, setdiff(names(data), group), drop = FALSE]
    mat <- mat[, vapply(mat, is.numeric, logical(1)), drop = FALSE]
    if (is.null(times)) times <- seq_len(ncol(mat))
    xr <- range(times); yr <- range(as.matrix(mat), na.rm = TRUE)
    xlab <- "Time"; ylab <- "Response"
  }

  dots <- list(...)
  if (is.null(dots$xlab)) dots$xlab <- xlab
  if (is.null(dots$ylab)) dots$ylab <- ylab
  do.call(graphics::plot,
          c(list(NA, xlim = xr, ylim = yr), dots))

  fade <- function(x, a) {
    rgb <- grDevices::col2rgb(x) / 255
    grDevices::rgb(rgb[1], rgb[2], rgb[3], alpha = a)
  }

  if (long) {
    gv <- if (!is.null(group)) data[[group]] else NULL
    pal <- if (!is.null(gv)) stats::setNames(
      grDevices::palette.colors(nlevels(factor(gv)), "Okabe-Ito"),
      levels(factor(gv))) else NULL
    for (u in ids) {
      sub <- data[data[[id]] == u, ]
      sub <- sub[order(sub[[time]]), ]
      cc  <- if (is.null(pal)) col else pal[[as.character(sub[[group]][1])]]
      graphics::lines(sub[[time]], sub[[response]], col = fade(cc, alpha))
    }
    if (!is.null(pal)) {
      graphics::legend("topleft", legend = names(pal), col = pal, lty = 1, bty = "n")
    }
  } else {
    pal <- if (!is.null(grp_vals)) stats::setNames(
      grDevices::palette.colors(nlevels(factor(grp_vals)), "Okabe-Ito"),
      levels(factor(grp_vals))) else NULL
    for (i in seq_len(nrow(mat))) {
      cc <- if (is.null(pal)) col else pal[[as.character(grp_vals[i])]]
      graphics::lines(times, as.numeric(mat[i, ]), col = fade(cc, alpha))
    }
    if (!is.null(pal)) {
      graphics::legend("topleft", legend = names(pal), col = pal, lty = 1, bty = "n")
    }
  }
  invisible(data)
}

#' Build a within- or between-subject covariance matrix
#'
#' Constructs the covariance structures met in week 2, so that slides, notes and
#' tutorials all display the same matrices. Useful for showing students what a
#' structure *is* before asking them to fit one.
#'
#' @param structure One of \code{"independent"}, \code{"exchangeable"} (compound
#'   symmetry), \code{"ar1"}, \code{"arma11"}, \code{"unstructured"}.
#' @param n Dimension of the matrix.
#' @param sigma2 Variance.
#' @param rho Correlation parameter. For \code{"arma11"} this is the AR
#'   parameter \eqn{\phi}.
#' @param theta Moving-average parameter, \code{"arma11"} only.
#' @param values Optional vector of correlations for \code{"unstructured"},
#'   filling the lower triangle by column.
#'
#' @return A symmetric \code{n} by \code{n} covariance matrix.
#' @export
#' @examples
#' cov_structure("ar1", n = 5, rho = 0.8)
#' cov_structure("exchangeable", n = 4, rho = 0.5, sigma2 = 2)
cov_structure <- function(structure = c("independent", "exchangeable", "ar1",
                                        "arma11", "unstructured"),
                          n = 5, sigma2 = 1, rho = 0.5, theta = 0.5,
                          values = NULL) {
  structure <- match.arg(structure)
  if (n < 1) stop("n must be at least 1", call. = FALSE)
  if (sigma2 <= 0) stop("sigma2 must be positive", call. = FALSE)
  lag <- abs(outer(seq_len(n), seq_len(n), "-"))

  R <- switch(structure,
    independent  = diag(n),
    exchangeable = { m <- matrix(rho, n, n); diag(m) <- 1; m },
    ar1          = rho ^ lag,
    arma11       = {
      m <- theta * rho ^ pmax(lag - 1, 0)
      diag(m) <- 1
      m
    },
    unstructured = {
      m <- diag(n)
      if (!is.null(values)) {
        idx <- which(lower.tri(m))
        if (length(values) != length(idx)) {
          stop("unstructured needs ", length(idx), " values, got ",
               length(values), call. = FALSE)
        }
        m[idx] <- values
        m <- m + t(m) - diag(n)
      }
      m
    })

  if (structure != "independent" && (rho <= -1 || rho >= 1)) {
    warning("rho outside (-1, 1); the result may not be positive definite",
            call. = FALSE)
  }
  out <- sigma2 * R
  dimnames(out) <- list(paste0("t", seq_len(n)), paste0("t", seq_len(n)))
  out
}

#' Standardised incidence ratio
#'
#' @param observed Observed counts.
#' @param expected Expected counts.
#' @return Numeric vector of ratios.
#' @export
#' @examples
#' data(scotland_lip)
#' head(sir(scotland_lip$cases, scotland_lip$expected))
sir <- function(observed, expected) {
  if (length(observed) != length(expected)) {
    stop("observed and expected must be the same length", call. = FALSE)
  }
  if (any(expected <= 0, na.rm = TRUE)) {
    warning("non-positive expected counts give undefined ratios", call. = FALSE)
  }
  observed / expected
}

#' Monte Carlo envelope test for spatial correlation
#'
#' Repeatedly permutes the values across locations and recomputes the empirical
#' variogram. Under the null of no spatial correlation the observed variogram
#' should sit inside the envelope of the permuted ones. This is the test used in
#' the week 7 tutorial.
#'
#' @param x,y Coordinates.
#' @param z Values, typically residuals from a covariate-only fit.
#' @param nsim Number of permutations.
#' @param nbins Number of distance bins.
#' @param max_dist Largest distance considered. Defaults to half the maximum
#'   separation.
#'
#' @return A list with the bin midpoints, the observed semivariance, the
#'   simulated envelope, and a permutation p-value.
#' @export
#' @examples
#' data(galicia)
#' fit <- lm(loglead ~ pm10, data = galicia)
#' res <- emp_variogram_mc(galicia$long, galicia$lat, resid(fit), nsim = 99)
#' res$p_value
emp_variogram_mc <- function(x, y, z, nsim = 999, nbins = 15, max_dist = NULL) {
  stopifnot(length(x) == length(y), length(y) == length(z))
  d <- as.matrix(stats::dist(cbind(x, y)))
  if (is.null(max_dist)) max_dist <- max(d) / 2
  breaks <- seq(0, max_dist, length.out = nbins + 1)
  mids   <- (breaks[-1] + breaks[-length(breaks)]) / 2
  ut     <- upper.tri(d)
  dv     <- d[ut]
  keep   <- dv <= max_dist
  bin    <- cut(dv[keep], breaks, include.lowest = TRUE)

  semivar <- function(vals) {
    sq <- (outer(vals, vals, "-")^2 / 2)[ut][keep]
    as.numeric(tapply(sq, bin, mean))
  }

  obs <- semivar(z)
  sim <- replicate(nsim, semivar(sample(z)))

  # one-sided: real spatial correlation makes short-range semivariance small
  lo <- apply(sim, 1, stats::quantile, 0.025, na.rm = TRUE)
  hi <- apply(sim, 1, stats::quantile, 0.975, na.rm = TRUE)

  # global test statistic: distance of the observed curve from the simulated mean
  mu   <- rowMeans(sim, na.rm = TRUE)
  tobs <- sum((obs - mu)^2, na.rm = TRUE)
  tsim <- apply(sim, 2, function(s) sum((s - mu)^2, na.rm = TRUE))
  p    <- (1 + sum(tsim >= tobs)) / (1 + nsim)

  structure(list(dist = mids, semivariance = obs, lower = lo, upper = hi,
                 p_value = p, nsim = nsim),
            class = "lsda_variogram_mc")
}

#' @export
print.lsda_variogram_mc <- function(x, ...) {
  cat("Monte Carlo envelope test for spatial correlation\n")
  cat("  permutations:", x$nsim, "\n")
  cat("  p-value:     ", format.pval(x$p_value, digits = 3), "\n")
  invisible(x)
}

#' @export
plot.lsda_variogram_mc <- function(x, ...) {
  graphics::plot(x$dist, x$semivariance, type = "n",
                 ylim = range(c(x$lower, x$upper, x$semivariance), na.rm = TRUE),
                 xlab = "Distance", ylab = "Semivariance", ...)
  graphics::polygon(c(x$dist, rev(x$dist)), c(x$lower, rev(x$upper)),
                    col = "grey85", border = NA)
  graphics::lines(x$dist, x$semivariance, lwd = 2, col = "#0072B2")
  graphics::points(x$dist, x$semivariance, pch = 16, col = "#0072B2")
  graphics::legend("bottomright", bty = "n",
                   legend = c("observed", "95% envelope under no correlation"),
                   col = c("#0072B2", "grey85"), lwd = c(2, 8))
  invisible(x)
}

#' Launch a course Shiny application
#'
#' @param app Application name. Omit to list what is available.
#' @param ... Passed to \code{\link[shiny]{runApp}}.
#' @return Called for its side effect.
#' @export
#' @examples
#' \dontrun{
#' run_app()              # list the apps
#' run_app("variogram")
#' }
run_app <- function(app = NULL, ...) {
  dir <- system.file("shiny", package = "lsda")
  available <- if (nzchar(dir)) list.dirs(dir, recursive = FALSE, full.names = FALSE) else character(0)
  if (is.null(app)) {
    if (!length(available)) {
      message("No apps installed.")
    } else {
      message("Available apps:\n  ", paste(available, collapse = "\n  "),
              "\n\nRun one with e.g. run_app(\"", available[[1]], "\")")
    }
    return(invisible(available))
  }
  if (!app %in% available) {
    stop("unknown app '", app, "'. Available: ",
         paste(available, collapse = ", "), call. = FALSE)
  }
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("package 'shiny' is required to run the apps", call. = FALSE)
  }
  shiny::runApp(file.path(dir, app), ...)
}
