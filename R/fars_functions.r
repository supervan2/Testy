#Just a small note: I assumed that the only functions to be exported should be
#fars_summarize_years and fars_map_state and that all other functions are internal
#to these two functions.

#' Read data from external source and output it
#'
#' This function returns a tibble data frame extracted from a CSV file or a CSV
#' file encoded in a .bz2 file. It works best used in conjunction with the
#' \code{make_filename} function to provide a correctly formatted input.
#' Note that it works within the current working directory unless a full path
#' is specified.
#'
#' @param filename A character string providing the name of the file containing
#'    the wanted data.
#'
#' @import readr
#' @import dplyr
#'
#' @return This function returns a tibble data frame as generated by first using
#'    the \code{\link{read_csv}} function contained in the \code{readr} package
#'    and then passing the result on to the \code{dplyr} package function
#'    \code{\link{tbl_df}}. If the provided filename does not exist, an
#'    appropriate error is shown.
#'
#' @examples
#' fars_read("C:/Users/All/Documents/Testy/R/data/accident_2013.csv.bz2")
#' data <- fars_read(make_filename(2013))
#'
fars_read <- function(filename) {
        if(!file.exists(filename))
                stop("file '", filename, "' does not exist")
        data <- suppressMessages({
                readr::read_csv(filename, progress = FALSE)
        })
        dplyr::tbl_df(data)
}

#' Create a full file name
#'
#' This is a simple function that, creates a full filename compatible with the
#' US National Highway Traffic Safety Administration's Fatality Analysis
#' Reporting System datasets. A year is taken as an input and inserted in the
#' file name. The input \code{year} is coerced as an integer with the R function
#' base function \code{\link{as.integer}}
#'
#' @param year A number that represent the year of the data file to be accessed.
#'
#' @return This function returns a character vector which is formatted to
#'    correspond to a filename of a specific year's dataset. The output is printed
#'    to the console.
#'
#' @examples
#' make_filename(2013)
#' when<- 2013
#' make_filename(when)
#' make_filename("2013")
#' data <- make_filename(2013)
#'
make_filename <- function(year) {
        year <- as.integer(year)
        sprintf("accident_%d.csv.bz2", year)
}

#' Read the dataset for multiple years
#'
#' This function builds on the functionality of \code{make_filename} and
#' \code{fars_read} to read the data from multiple CSV files containing
#' the data for the years corresponding to the input years. The \code{dplyr}
#' functions \code{\link{mutate}} and \code{\link{select}}are used to tidy the
#' data and only return the 'MONTH' and 'year' variable collumns respectively.
#' The base R function\code{\link{tryCatch}}is used to catch errors created by
#' \code{\link{make_filename}} and show these errors and the end of running
#' without interrupting the execution of the base R function \code{\link{lapply}}.
#'
#' @param years A vector of numbers or character strings representing years.
#'
#' @import dplyr
#'
#' @return This function returns a list (the same length as \code{years}) of
#'    tibbles. NULL is returned for each input year not corresponding to a valid
#'    dataset.
#'
#' @examples
#' fars_read_years(2013)
#' fars_read_years(c("2013","2014"))
#' data <- fars_read_years(2013)
#'
fars_read_years <- function(years) {
        lapply(years, function(year) {
                file <- make_filename(year)
                tryCatch({
                        dat <- fars_read(file)
                        dplyr::mutate(dat, year = year) %>%
                                dplyr::select(MONTH, year)
                }, error = function(e) {
                        warning("invalid year: ", year)
                        return(NULL)
                })
        })
}

#' Returns ordered and summarized version of datasets
#'
#' This function builds on the functionality of \code{fars_read_years} to read
#' the data from multiple CSV files containing
#' the data for the years corresponding to the input years. The \code{dplyr} and
#' \code{tidyr}
#' functions \code{\link{bind_rows}}, \code{\link{group_by}},
#' \code{\link{group_by}} and \code{\link{spread}} are used to tidy the
#' data and only return the 'MONTH' and 'year' variable columns respectively,
#' while ensuring that the 'MONTH' column is not duplicated when multiple years
#' are used as inputs.
#'
#' @param years A vector of numbers or character strings representing years.
#'
#' @import dplyr
#' @import tidyr
#'
#' @return This function returns a tibble summarizing the data found for each
#'    input year requested. A warning is returned for each input year not
#'    corresponding to a valid dataset, while not affecting the output for valid
#'    years.
#'
#' @examples
#' fars_summarize_years(2013)
#' fars_sumarize_years(c("2013","2014"))
#' data <- fars_summarize_years(2013)
#'
#' @export
fars_summarize_years <- function(years) {
        dat_list <- fars_read_years(years)
        dplyr::bind_rows(dat_list) %>%
                dplyr::group_by(year, MONTH) %>%
                dplyr::summarize(n = n()) %>%
                tidyr::spread(year, n)
}

#' Plot accident locations on a map
#'
#' This function attempts to output a polygon plot of a specific USA state with
#' points ("." by setting \code{pch} to 46 in the \code{\link{points}} function)
#' on the same plot indicating the location of all logged accidents within
#' a specified year. It automatically assigns \code{NA} values to off-planet
#' LAT/LONG combinations with the base R function \code{\link{is.na}}. The
#' values \code{xlim} and \code{ylim} of \code{link{map}} is bound by the most
#' outlying LAT/LONG points found within the data and subsequently the polygon
#' drawn is clipped beyond these bounds.
#'
#' @param state.num A number coerced to integer correspnding to an USA state.
#' @param year A number representing the data for a specific year. This cannot
#'    be a vector. (It can, but things go wrong.)
#'
#' @import maps
#' @import graphics
#' @import dplyr
#'
#' @return A plot combining polygons and points.
#'    If \code{state.num} is not found within the dataset selected with
#'    \code{year}, no plot is created and an error is returned.
#'    If the combination of \code{state.num} and \code{year} is valid, but there
#'    are no accident data, the function returns NULL, but not made visible in
#'    the console, while an appropriate message (not error) is displayed.
#'
#' @examples
#' fars_map_state(1,2015)
#' fars_map_state(54,2015)
#'
#' @export
fars_map_state <- function(state.num, year) {
        filename <- make_filename(year)
        data <- fars_read(filename)
        state.num <- as.integer(state.num)

        if(!(state.num %in% unique(data$STATE)))
                stop("invalid STATE number: ", state.num)
        data.sub <- dplyr::filter(data, STATE == state.num)
        if(nrow(data.sub) == 0L) {
                message("no accidents to plot")
                return(invisible(NULL))
        }
        is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
        is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
        with(data.sub, {
                maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
                          xlim = range(LONGITUD, na.rm = TRUE))
                graphics::points(LONGITUD, LATITUDE, pch = 46)
        })
}

