#' \code{sfarrow}: An R package for reading/writing simple feature (\code{sf})
#' objects from/to Arrow parquet/feather files with \code{arrow}
#'
#' Simple features are a popular, standardised way to create spatial vector data
#' with a list-type geometry column. Parquet files are standard column-oriented
#' files designed by Apache Arrow (\url{https://parquet.apache.org/}) for fast
#' read/writes. \code{sfarrow} is designed to support the reading and writing of
#' simple features in \code{sf} objects from/to Parquet files (.parquet) and
#' Feather files (.feather) within \code{R}. A key goal of \code{sfarrow} is to
#' support interoperability of spatial data in files between \code{R} and
#' \code{Python} through the use of standardised metadata.
#'
#' @section Metadata:
#' Coordinate reference and geometry field information for \code{sf} objects are
#' stored in standard metadata tables within the files. The metadata are based
#' on a standard representation (Version 0.1.0, reference:
#' \url{https://github.com/geopandas/geo-arrow-spec}). This is compatible with
#' the format used by the Python library \code{GeoPandas} for read/writing
#' Parquet/Feather files. Note to users: this metadata format is not yet stable
#' for production uses and may change in the future.
#'
#' @section Credits:
#' This work was undertaken by Chris Jochem, a member of the WorldPop Research
#' Group at the University of Southampton(\url{https://www.worldpop.org/}).
#'
#' @docType package
#' @keywords internal
#' @name sfarrow
NULL
