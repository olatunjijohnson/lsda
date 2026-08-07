# ---------------------------------------------------------------------------
# Linear mixed model simulator -- weeks 2 and 3
#
# Students fit LMMs and read off estimates, but rarely see that an estimate is
# a random variable with a sampling distribution. Here they set the truth,
# simulate, fit, and repeat -- so "unbiased", "consistent" and "standard error"
# become things they have watched happen.
#
# Also demonstrates the classic result that variance components are estimated
# much less precisely than fixed effects, and that ML underestimates variance
# components while REML corrects for it.
# ---------------------------------------------------------------------------

library(shiny)

has_nlme <- requireNamespace("nlme", quietly = TRUE)

ui <- fluidPage(
  titlePanel("Linear mixed model: set the truth, then try to recover it"),
  sidebarLayout(
    sidebarPanel(
      width = 4,
      h4("The true model"),
      withMathJax(helpText("$$Y_{ij} = \\beta_0 + \\beta_1 t_{ij} + b_i + \\varepsilon_{ij}$$",
                           "$$b_i \\sim N(0, \\sigma_b^2), \\quad \\varepsilon_{ij} \\sim N(0, \\sigma_e^2)$$")),
      sliderInput("b0", "Intercept, beta0", -5, 5, 1, step = 0.5),
      sliderInput("b1", "Slope, beta1", -3, 3, 0.5, step = 0.1),
      sliderInput("sb", "Between-subject SD, sigma_b", 0.1, 5, 2, step = 0.1),
      sliderInput("se", "Within-subject SD, sigma_e", 0.1, 5, 1, step = 0.1),
      hr(),
      h4("The design"),
      # Default deliberately small: the ML/REML difference in variance
      # components is a small-sample effect. At m = 30 with two fixed effects
      # the two methods agree to within about 1%, so a larger default would
      # make the ML-vs-REML demonstration silently fail.
      sliderInput("m",  "Subjects, m", 5, 200, 10, step = 5),
      sliderInput("ni", "Observations each, n_i", 2, 20, 5, step = 1),
      radioButtons("method", "Estimation", c("REML" = "REML", "ML" = "ML"),
                   inline = TRUE),
      sliderInput("nsim", "Simulations", 20, 500, 200, step = 20),
      actionButton("go", "Run", class = "btn-primary")
    ),
    mainPanel(
      width = 8,
      if (!has_nlme)
        div(class = "alert alert-warning", "Package 'nlme' is required."),
      tabsetPanel(
        tabPanel("One dataset",
          br(),
          p("A single simulated dataset, so you can see what the model is fitted to."),
          plotOutput("one", height = "340px")),
        tabPanel("Sampling distributions",
          br(),
          p("Each histogram is the distribution of an estimate across repeated",
            "simulations. The orange line is the truth."),
          plotOutput("sampling", height = "420px"),
          tableOutput("summ"),
          uiOutput("notes"))
      )
    )
  )
)

simulate_one <- function(m, ni, b0, b1, sb, se) {
  id <- rep(seq_len(m), each = ni)
  t  <- rep(seq_len(ni), times = m)
  b  <- rnorm(m, 0, sb)[id]
  y  <- b0 + b1 * t + b + rnorm(m * ni, 0, se)
  data.frame(id = factor(id), t = t, y = y)
}

server <- function(input, output, session) {

  one <- reactive({
    input$go
    simulate_one(input$m, input$ni, input$b0, input$b1, input$sb, input$se)
  })

  output$one <- renderPlot({
    d <- one()
    op <- par(mar = c(4.5, 4.5, 2, 1)); on.exit(par(op))
    plot(NA, xlim = range(d$t), ylim = range(d$y),
         xlab = "time", ylab = "response",
         main = sprintf("%d subjects x %d observations", input$m, input$ni))
    for (u in levels(d$id)) {
      s <- d[d$id == u, ]
      lines(s$t, s$y, col = adjustcolor("grey30", 0.5))
    }
    abline(a = input$b0, b = input$b1, col = "#d95f02", lwd = 3)
    legend("topleft", bty = "n", lwd = 3, col = "#d95f02",
           legend = "true population line")
  })

  res <- eventReactive(input$go, {
    validate(need(has_nlme, "nlme is required"))
    out <- matrix(NA_real_, input$nsim, 4,
                  dimnames = list(NULL, c("b0", "b1", "sb", "se")))
    withProgress(message = "Simulating", value = 0, {
      for (s in seq_len(input$nsim)) {
        incProgress(1 / input$nsim)
        d <- simulate_one(input$m, input$ni, input$b0, input$b1,
                          input$sb, input$se)
        fit <- try(nlme::lme(y ~ t, random = ~ 1 | id, data = d,
                             method = input$method), silent = TRUE)
        if (inherits(fit, "try-error")) next
        fx <- nlme::fixef(fit)
        vc <- as.numeric(nlme::VarCorr(fit)[, "StdDev"])
        out[s, ] <- c(fx[[1]], fx[[2]], vc[[1]], vc[[2]])
      }
    })
    out[stats::complete.cases(out), , drop = FALSE]
  })

  truth <- reactive(c(b0 = input$b0, b1 = input$b1,
                      sb = input$sb, se = input$se))

  output$sampling <- renderPlot({
    r <- res(); tv <- truth()
    labs <- c(b0 = "intercept  beta0", b1 = "slope  beta1",
              sb = "between-subject SD  sigma_b",
              se = "within-subject SD  sigma_e")
    op <- par(mfrow = c(2, 2), mar = c(4, 4, 2.5, 1)); on.exit(par(op))
    for (p in colnames(r)) {
      hist(r[, p], breaks = 25, col = "#9ecae1", border = "white",
           main = labs[[p]], xlab = "")
      abline(v = tv[[p]],        col = "#d95f02", lwd = 3)
      abline(v = mean(r[, p]),   col = "#1b9e77", lwd = 2, lty = 2)
    }
  })

  output$summ <- renderTable({
    r <- res(); tv <- truth()
    data.frame(
      Parameter = c("beta0", "beta1", "sigma_b", "sigma_e"),
      Truth     = round(as.numeric(tv), 3),
      Mean      = round(colMeans(r), 3),
      Bias      = round(colMeans(r) - as.numeric(tv), 3),
      `Bias %`  = sprintf("%+.1f%%", 100 * (colMeans(r) / as.numeric(tv) - 1)),
      `SD (empirical SE)` = round(apply(r, 2, sd), 3),
      check.names = FALSE)
  }, striped = TRUE)

  output$notes <- renderUI({
    r <- res(); tv <- truth()
    rel_fixed <- abs(mean(r[, "b1"]) / tv[["b1"]] - 1)
    rel_sb    <- abs(mean(r[, "sb"]) / tv[["sb"]] - 1)
    tagList(
      p(strong("Notice: "),
        sprintf("the slope is recovered to within %.1f%%, but sigma_b to within %.1f%%.",
                100 * rel_fixed, 100 * rel_sb)),
      p("Variance components need far more subjects than fixed effects do.",
        "Try dropping m to 10 and watch sigma_b become badly unstable while",
        "beta1 stays reasonable."),
      if (identical(input$method, "ML"))
        p(style = "color:#d95f02",
          strong("ML is selected. "),
          "ML underestimates variance components because it ignores the degrees",
          "of freedom spent estimating the fixed effects. With",
          sprintf(" m = %d ", input$m),
          if (input$m <= 15)
            "subjects that bias should be clearly visible in sigma_b above."
          else
            paste("subjects the bias is small — the correction is of order p/m,",
                  "so it washes out as m grows. Drop m to 10 to see it plainly."),
          " Switch to REML and compare.")
      else
        p(style = "color:#1b9e77",
          strong("REML is selected. "),
          "REML should give a near-unbiased sigma_b. Switch to ML and compare —",
          if (input$m <= 15)
            "at this sample size you should see ML bite."
          else
            paste("but note that at m =", input$m,
                  "the two methods nearly agree. The ML bias is a small-sample",
                  "effect of order p/m; reduce m to 10 to make it obvious."))
    )
  })
}

shinyApp(ui, server)
