test_that("cov_structure returns valid covariance matrices", {
  for (s in c("independent", "exchangeable", "ar1", "arma11")) {
    m <- cov_structure(s, n = 5, sigma2 = 2, rho = 0.6)
    expect_equal(dim(m), c(5L, 5L))
    expect_true(isSymmetric(unname(m)), info = s)
    expect_equal(unname(diag(m)), rep(2, 5), info = s)
    # a covariance matrix must be positive definite
    expect_true(all(eigen(m, only.values = TRUE)$values > 0), info = s)
  }
})

test_that("ar1 correlation decays with lag", {
  m <- cov_structure("ar1", n = 4, rho = 0.7)
  expect_equal(m[1, 2], 0.7)
  expect_equal(m[1, 3], 0.49)
  expect_equal(m[1, 4], 0.343)
  expect_true(m[1, 2] > m[1, 3] && m[1, 3] > m[1, 4])
})

test_that("exchangeable has constant off-diagonal", {
  m <- cov_structure("exchangeable", n = 4, rho = 0.3)
  off <- m[upper.tri(m)]
  expect_true(all(abs(off - 0.3) < 1e-12))
})

test_that("independent is the identity scaled by sigma2", {
  expect_equal(unname(cov_structure("independent", n = 3, sigma2 = 4)),
               diag(4, 3))
})

test_that("cov_structure validates its inputs", {
  expect_error(cov_structure("ar1", n = 0), "at least 1")
  expect_error(cov_structure("ar1", sigma2 = -1), "positive")
  expect_error(cov_structure("nonsense"), "should be one of")
  expect_warning(cov_structure("ar1", n = 3, rho = 1.5), "positive definite")
  expect_error(cov_structure("unstructured", n = 3, values = c(0.1)),
               "needs 3 values")
})

test_that("sir divides observed by expected", {
  expect_equal(sir(c(10, 20), c(5, 10)), c(2, 2))
  expect_error(sir(1:3, 1:2), "same length")
  expect_warning(sir(1, 0), "non-positive")
})

test_that("emp_variogram_mc detects correlation when it is there", {
  set.seed(42)
  n <- 60
  x <- runif(n, 0, 10); y <- runif(n, 0, 10)

  # strongly spatially structured: value is a smooth function of position
  z_spatial <- 3 * sin(x / 2) + 3 * cos(y / 2)
  r_spatial <- emp_variogram_mc(x, y, z_spatial, nsim = 199, nbins = 8)
  expect_lt(r_spatial$p_value, 0.05)

  # pure noise: no spatial structure
  z_noise <- rnorm(n)
  r_noise <- emp_variogram_mc(x, y, z_noise, nsim = 199, nbins = 8)
  expect_gt(r_noise$p_value, 0.05)
})

test_that("emp_variogram_mc returns a well-formed object", {
  set.seed(1)
  r <- emp_variogram_mc(runif(30), runif(30), rnorm(30), nsim = 49, nbins = 6)
  expect_s3_class(r, "lsda_variogram_mc")
  expect_length(r$dist, 6)
  expect_length(r$semivariance, 6)
  expect_true(all(r$lower <= r$upper, na.rm = TRUE))
  expect_true(r$p_value > 0 && r$p_value <= 1)
})

test_that("spaghetti_plot works in wide and long form", {
  data(cattle, package = "lsda")
  data(fev1, package = "lsda")
  tmp <- tempfile(fileext = ".png"); grDevices::png(tmp)
  on.exit({ grDevices::dev.off(); unlink(tmp) }, add = TRUE)

  expect_silent(spaghetti_plot(cattle, group = "group"))
  expect_silent(spaghetti_plot(fev1, id = "id", time = "age",
                               response = "logfev1_ht"))
  expect_error(spaghetti_plot(fev1, id = "nope", time = "age",
                              response = "logfev1_ht"), "not found")
})

test_that("run_app lists apps rather than failing when given no argument", {
  expect_message(run_app(), "app")
})
