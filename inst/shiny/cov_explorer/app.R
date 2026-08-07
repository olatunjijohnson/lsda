# ---------------------------------------------------------------------------
# Covariance structure explorer -- week 2
#
# Students meet independent / compound symmetry / AR(1) / ARMA(1,1) as algebra
# and then have to choose between them by AIC without ever having seen what
# they look like. This app shows, for the structure and parameters chosen:
#   - the covariance matrix itself,
#   - its correlation heatmap,
#   - simulated trajectories drawn from it.
#
# Uses lsda::cov_structure() so the matrices shown here are the same objects
# the slides and tutorials print.
# ---------------------------------------------------------------------------

library(shiny)
library(lsda)

ui <- fluidPage(
  titlePanel("What do the within-subject covariance structures actually look like?"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("structure", "Structure",
                  c("Independent"       = "independent",
                    "Compound symmetry" = "exchangeable",
                    "AR(1)"             = "ar1",
                    "ARMA(1,1)"         = "arma11")),
      sliderInput("n", "Observations per subject, n_i", 3, 12, 6, step = 1),
      sliderInput("sigma2", "Variance, sigma^2", 0.5, 5, 1, step = 0.1),
      conditionalPanel("input.structure != 'independent'",
        sliderInput("rho", "Correlation, rho", -0.95, 0.95, 0.7, step = 0.05)),
      conditionalPanel("input.structure == 'arma11'",
        sliderInput("theta", "Moving-average, theta", -0.95, 0.95, 0.5, step = 0.05)),
      hr(),
      sliderInput("ntraj", "Simulated subjects to draw", 1, 40, 12, step = 1),
      actionButton("resim", "Redraw"),
      hr(),
      helpText("Compound symmetry says all pairs are equally correlated",
               "however far apart in time. AR(1) says correlation decays",
               "geometrically with the gap. That difference is the whole",
               "reason the choice matters.")
    ),
    mainPanel(
      width = 9,
      fluidRow(
        column(6, h4("Correlation heatmap"), plotOutput("heat", height = "300px")),
        column(6, h4("Simulated trajectories"), plotOutput("traj", height = "300px"))
      ),
      hr(),
      h4("Covariance matrix"),
      verbatimTextOutput("mat"),
      h4("Correlation as a function of lag"),
      plotOutput("decay", height = "220px")
    )
  )
)

server <- function(input, output, session) {

  Sigma <- reactive({
    cov_structure(input$structure, n = input$n, sigma2 = input$sigma2,
                  rho = if (is.null(input$rho)) 0 else input$rho,
                  theta = if (is.null(input$theta)) 0.5 else input$theta)
  })

  output$mat <- renderPrint(round(Sigma(), 3))

  output$heat <- renderPlot({
    S <- Sigma(); R <- stats::cov2cor(S); n <- nrow(R)
    op <- par(mar = c(3, 3, 1, 4)); on.exit(par(op))
    pal <- grDevices::colorRampPalette(c("#2166ac", "white", "#b2182b"))(101)
    # R is symmetric, so no transpose is needed for image()'s [x, y] convention
    image(1:n, 1:n, R, col = pal, zlim = c(-1, 1),
          axes = FALSE, xlab = "", ylab = "")
    axis(1, 1:n, labels = 1:n, tick = FALSE); axis(2, 1:n, labels = 1:n, tick = FALSE)
    for (i in 1:n) for (j in 1:n) {
      text(i, j, sprintf("%.2f", R[i, j]), cex = min(1, 8 / n),
           col = if (abs(R[i, j]) > 0.6) "white" else "black")
    }
    box()
  })

  draws <- reactive({
    input$resim
    S <- Sigma(); n <- nrow(S)
    L <- tryCatch(chol(S), error = function(e) NULL)
    validate(need(!is.null(L),
                  "That parameter combination is not positive definite. Reduce |rho| or |theta|."))
    matrix(rnorm(input$ntraj * n), input$ntraj, n) %*% L
  })

  output$traj <- renderPlot({
    Y <- draws(); n <- ncol(Y)
    op <- par(mar = c(4, 4, 1, 1)); on.exit(par(op))
    matplot(1:n, t(Y), type = "l", lty = 1,
            col = adjustcolor(grDevices::palette.colors(8, "Okabe-Ito"), 0.8),
            xlab = "time", ylab = "response")
    abline(h = 0, col = "grey60", lty = 2)
  })

  output$decay <- renderPlot({
    S <- Sigma(); R <- stats::cov2cor(S); n <- nrow(R)
    lag <- 0:(n - 1)
    cors <- vapply(lag, function(k) mean(R[row(R) - col(R) == k]), numeric(1))
    op <- par(mar = c(4, 4, 1, 1)); on.exit(par(op))
    plot(lag, cors, type = "b", pch = 16, ylim = c(min(0, min(cors)), 1),
         xlab = "lag between observations", ylab = "correlation", col = "#0072B2", lwd = 2)
    abline(h = 0, col = "grey60", lty = 2)
  })
}

shinyApp(ui, server)
