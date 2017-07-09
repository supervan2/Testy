#I need to contrcut a test. Can it be multiple lines of "expect_that..." or must it be contained within a "test_that"
#function, I do not know. When will these be called and by who, I do not know either. Can functions be tested that have

#' These are the tests that should run on Travis
#'
#' Should this have markdown comments? No one will really ever see this.
#'
#'@importFrom testthat()
#'
testthat::expect_that(make_filename(2013), equals("accident_2013.csv.bz2"))
