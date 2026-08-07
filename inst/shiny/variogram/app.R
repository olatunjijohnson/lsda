# ---------------------------------------------------------------------------
# Variogram and covariance function explorer -- week 7
#
# Built to match the parameterisation used in the week 7 slides (see the course
# script variogram.R): nugget, sill and practical range, with the exponential,
# Gaussian, spherical and Matern families.
#
# NOTE: if you already have a variogram Shiny app you prefer, drop it in here
# in place of this file -- run_app("variogram") will pick it up unchanged.
# ---------------------------------------------------------------------------

library(shiny)

# Semivariogram gamma(u) and covariance C(u) = sill - gamma(u), with a nugget.
gamma_fun <- function(u, model, nugget, sill, range, kappa = 1.5) {
  partial <- sill - nugget
  rho <- switch(model,
    exponential = 1 - exp(-u / range),
    gaussian    = 1 - exp(-(u / range)^2),
    spherical   = ifelse(u >= range, 1,
                         1.5 * (u / range) - 0.5 * (u / range)^3),
    matern      = {
      # Matern correlation, then converted to a variogram
      uu <- pmax(u, 1e-10) / range
      cor <- (2^(1 - kappa) / gamma(kappa)) * (uu^kappa) * besselK(uu, kappa)
      cor[u == 0] <- 1
      1 - cor
    })
  ifelse(u == 0, 0, nugget + partial * rho)
}

practical_range <- function(model, range) {
  switch(model,
    exponential = 3 * range,
    gaussian    = sqrt(3) * range,
    spherical   = range,
    matern      = 3 * range)
}

ui <- fluidPage(
  titlePanel("Variogram and covariance function"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("model", "Correlation family",
                  c("Exponential" = "exponential",
                    "Gaussian"    = "gaussian",
                    "Spherical"   = "spherical",
                    "Matern"      = "matern")),
      conditionalPanel("input.model == 'matern'",
        sliderInput("kappa", "Smoothness, kappa", 0.5, 3, 1.5, step = 0.5)),
      sliderInput("nugget", "Nugget, tau^2", 0, 1, 0.2, step = 0.05),
      sliderInput("sill",   "Sill, tau^2 + sigma^2", 0.1, 2, 1, step = 0.05),
      sliderInput("range",  "Range parameter, phi", 0.1, 5, 1, step = 0.1),
      hr(),
      checkboxInput("show_realisation", "Show a simulated 1-D realisation", TRUE),
      actionButton("resim", "Redraw realisation"),
      hr(),
      helpText("The nugget is the jump at the origin: variation at distances",
               "shorter than the closest pair of points, plus measurement",
               "error. The practical range is where correlation has decayed",
               "to about 0.05.")
    ),
    mainPanel(
      width = 9,
      fluidRow(
        column(6, h4("Semivariogram"),        plotOutput("vario", height = "300px")),
        column(6, h4("Covariance function"),  plotOutput("covar", height = "300px"))
      ),
      conditionalPanel("input.show_realisation",
        hr(), h4("A realisation with this covariance structure"),
        plotOutput("real", height = "240px")),
      hr(),
      verbatimTextOutput("summary")
    )
  )
)

server <- function(input, output, session) {

  valid <- reactive(input$sill > input$nugget)

  u <- seq(0, 12, length.out = 400)

  output$vario <- renderPlot({
    validate(need(valid(), "The sill must exceed the nugget."))
    kap <- if (is.null(input$kappa)) 1.5 else input$kappa
    g <- gamma_fun(u, input$model, input$nugget, input$sill, input$range, kap)
    pr <- practical_range(input$model, input$range)
    op <- par(mar = c(4.5, 4.5, 1, 1)); on.exit(par(op))
    plot(u, g, type = "l", lwd = 2, col = "#0072B2",
         xlab = "distance, u", ylab = expression(gamma(u)),
         ylim = c(0, input$sill * 1.15))
    abline(h = input$sill,   lty = 2, col = "grey40")
    abline(h = input$nugget, lty = 3, col = "grey40")
    abline(v = pr,           lty = 2, col = "#d95f02")
    text(max(u) * 0.85, input$sill,   "sill",   pos = 3, col = "grey30", cex = 0.9)
    text(max(u) * 0.85, input$nugget, "nugget", pos = 3, col = "grey30", cex = 0.9)
    text(pr, input$sill * 0.15, "practical range", srt = 90, pos = 4,
         col = "#d95f02", cex = 0.9)
  })

  output$covar <- renderPlot({
    validate(need(valid(), "The sill must exceed the nugget."))
    kap <- if (is.null(input$kappa)) 1.5 else input$kappa
    g <- gamma_fun(u, input$model, input$nugget, input$sill, input$range, kap)
    C <- input$sill - g          # C(u) = sill - gamma(u)
    op <- par(mar = c(4.5, 4.5, 1, 1)); on.exit(par(op))
    plot(u, C, type = "l", lwd = 2, col = "#1b9e77",
         xlab = "distance, u", ylab = "C(u)",
         ylim = c(0, input$sill * 1.15))
    abline(h = 0, col = "grey60", lty = 2)
    abline(v = practical_range(input$model, input$range), lty = 2, col = "#d95f02")
  })

  output$real <- renderPlot({
    input$resim
    validate(need(valid(), "The sill must exceed the nugget."))
    kap <- if (is.null(input$kappa)) 1.5 else input$kappa
    s <- seq(0, 12, length.out = 220)
    D <- as.matrix(dist(s))
    Sig <- input$sill - gamma_fun(D, input$model, input$nugget,
                                  input$sill, input$range, kap)
    diag(Sig) <- input$sill
    L <- tryCatch(chol(Sig + diag(1e-8, nrow(Sig))), error = function(e) NULL)
    validate(need(!is.null(L),
                  "Not positive definite at these settings (the Gaussian family is prone to this); nudge the range or add a nugget."))
    z <- as.vector(crossprod(L, rnorm(nrow(Sig))))
    op <- par(mar = c(4.5, 4.5, 1, 1)); on.exit(par(op))
    plot(s, z, type = "l", lwd = 2, col = "#7570b3",
         xlab = "location", ylab = "Z(s)")
    abline(h = 0, col = "grey60", lty = 2)
  })

  output$summary <- renderPrint({
    kap <- if (is.null(input$kappa)) 1.5 else input$kappa
    cat("model:            ", input$model, "\n")
    if (identical(input$model, "matern")) cat("smoothness kappa: ", kap, "\n")
    cat("nugget  tau^2:    ", input$nugget, "\n")
    cat("partial sill:     ", round(input$sill - input$nugget, 3), "\n")
    cat("sill:             ", input$sill, "\n")
    cat("range phi:        ", input$range, "\n")
    cat("practical range:  ", round(practical_range(input$model, input$range), 3), "\n")
    cat("nugget / sill:    ", round(input$nugget / input$sill, 3),
        " (proportion of variance that is not spatially structured)\n")
  })
}

shinyApp(ui, server)
