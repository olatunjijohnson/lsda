# ---------------------------------------------------------------------------
# GEE robustness -- week 5
#
# The single most important idea about GEE, and the one students most often
# take on faith: if the working correlation is wrong, beta-hat is STILL
# consistent, but the naive (model-based) standard errors are NOT. The robust
# sandwich standard errors fix the second problem.
#
# This app simulates from a known truth, fits GEE under a working correlation
# the student chooses, and repeats. It then shows:
#   - the sampling distribution of beta-hat, centred on the truth regardless of
#     the working correlation chosen;
#   - the empirical (true) standard error, next to the average naive SE and the
#     average robust SE, so the student sees which one tracks reality.
# ---------------------------------------------------------------------------

library(shiny)

has_geepack <- requireNamespace("geepack", quietly = TRUE)

ui <- fluidPage(
  titlePanel("GEE: what happens when the working correlation is wrong?"),
  sidebarLayout(
    sidebarPanel(
      width = 4,
      helpText("Data are simulated with a known true correlation. You choose",
               "what GEE assumes. Watch what stays right and what goes wrong."),
      selectInput("true_cor", "TRUE correlation (used to simulate)",
                  c("Exchangeable" = "exch", "AR(1)" = "ar1",
                    "Independent" = "ind"), selected = "exch"),
      sliderInput("rho", "True correlation, rho", 0, 0.9, 0.7, step = 0.05),
      selectInput("work_cor", "WORKING correlation (what GEE assumes)",
                  c("Independence" = "independence",
                    "Exchangeable" = "exchangeable",
                    "AR(1)" = "ar1"), selected = "independence"),
      hr(),
      sliderInput("m",  "Number of subjects", 20, 300, 60, step = 10),
      sliderInput("ni", "Observations per subject", 3, 12, 6, step = 1),
      sliderInput("beta1", "True slope, beta1", -2, 2, 1, step = 0.1),
      sliderInput("nsim", "Simulations", 50, 1000, 300, step = 50),
      actionButton("go", "Run simulation", class = "btn-primary"),
      hr(),
      helpText(strong("What to look for:"),
               "the histogram stays centred on the true slope whatever you",
               "assume, but when the working correlation is wrong the naive SE",
               "drifts away from the truth while the robust SE tracks it.")
    ),
    mainPanel(
      width = 8,
      if (!has_geepack)
        div(class = "alert alert-warning",
            "Package 'geepack' is not installed; install it to use this app."),
      plotOutput("dist", height = "320px"),
      hr(),
      h4("Standard errors: which one tells the truth?"),
      tableOutput("setab"),
      uiOutput("verdict")
    )
  )
)

server <- function(input, output, session) {

  sim <- eventReactive(input$go, {
    validate(need(has_geepack, "geepack is required"))
    m <- input$m; ni <- input$ni; rho <- input$rho
    b0 <- 0; b1 <- input$beta1

    R <- switch(input$true_cor,
      exch = { r <- matrix(rho, ni, ni); diag(r) <- 1; r },
      ar1  = rho ^ abs(outer(seq_len(ni), seq_len(ni), "-")),
      ind  = diag(ni))
    L <- chol(R)

    est <- naive <- robust <- numeric(input$nsim)
    withProgress(message = "Simulating", value = 0, {
      for (s in seq_len(input$nsim)) {
        incProgress(1 / input$nsim)
        id <- rep(seq_len(m), each = ni)
        x  <- rep(seq_len(ni), times = m)          # time-varying covariate
        e  <- as.vector(t(matrix(rnorm(m * ni), m, ni) %*% L))
        y  <- b0 + b1 * x + e
        d  <- data.frame(id, x, y)

        fit <- try(geepack::geeglm(y ~ x, id = id, data = d,
                                   family = gaussian,
                                   corstr = input$work_cor), silent = TRUE)
        if (inherits(fit, "try-error")) { est[s] <- NA; next }

        est[s]    <- unname(coef(fit)[["x"]])
        robust[s] <- summary(fit)$coefficients["x", "Std.err"]
        # Naive (model-based) SE lives in geese$vbeta.naiv; the sandwich version
        # is geese$vbeta. Neither carries dimnames, so index by position: the
        # model is y ~ x, so row 2 is the slope.
        nv <- fit$geese$vbeta.naiv
        naive[s] <- if (!is.null(nv)) sqrt(diag(nv))[2] else NA_real_
      }
    })
    list(est = est, naive = naive, robust = robust, truth = b1)
  })

  output$dist <- renderPlot({
    r <- sim(); e <- r$est[is.finite(r$est)]
    op <- par(mar = c(4.5, 4.5, 3, 1)); on.exit(par(op))
    hist(e, breaks = 30, col = "#9ecae1", border = "white",
         main = sprintf("Sampling distribution of beta1-hat  (mean = %.3f, truth = %.3f)",
                        mean(e), r$truth),
         xlab = "estimated slope")
    abline(v = r$truth, col = "#d95f02", lwd = 3)
    abline(v = mean(e), col = "#1b9e77", lwd = 3, lty = 2)
    legend("topright", bty = "n", lwd = 3, lty = c(1, 2),
           col = c("#d95f02", "#1b9e77"),
           legend = c("true beta1", "mean of estimates"))
  })

  output$setab <- renderTable({
    r <- sim()
    emp <- sd(r$est, na.rm = TRUE)
    data.frame(
      Quantity = c("Empirical SE (the truth)",
                   "Mean naive / model-based SE",
                   "Mean robust / sandwich SE"),
      Value = round(c(emp, mean(r$naive, na.rm = TRUE),
                      mean(r$robust, na.rm = TRUE)), 4),
      `Error vs truth` = c("--",
        sprintf("%+.1f%%", 100 * (mean(r$naive,  na.rm = TRUE) / emp - 1)),
        sprintf("%+.1f%%", 100 * (mean(r$robust, na.rm = TRUE) / emp - 1))),
      check.names = FALSE)
  }, striped = TRUE)

  output$verdict <- renderUI({
    r <- sim()
    emp <- sd(r$est, na.rm = TRUE)
    bias_est <- abs(mean(r$est, na.rm = TRUE) - r$truth) / max(emp, 1e-9)
    nv <- abs(mean(r$naive,  na.rm = TRUE) / emp - 1)
    rb <- abs(mean(r$robust, na.rm = TRUE) / emp - 1)
    tagList(
      p(strong("beta-hat: "),
        if (bias_est < 0.25)
          span(style = "color:#1b9e77", "unbiased, as theory promises — even though the working correlation may be wrong.")
        else
          span(style = "color:#d95f02", "looks off-centre; increase the number of simulations.")),
      p(strong("Standard errors: "),
        sprintf("naive is out by %.0f%%, robust by %.0f%%.", 100 * nv, 100 * rb),
        if (nv > rb + 0.05)
          span(style = "color:#1b9e77", " The sandwich estimator is doing its job.")
        else if (identical(input$work_cor, tolower(gsub("exch", "exchangeable", input$true_cor))))
          span(" Working correlation matches the truth, so both are fine — try mis-specifying it.")
        else span("")))
  })
}

shinyApp(ui, server)
