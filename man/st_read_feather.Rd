% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/st_arrow.R
\name{st_read_feather}
\alias{st_read_feather}
\title{Read a Feather file to \code{sf} object}
\usage{
st_read_feather(dsn, col_select = NULL, ...)
}
\arguments{
\item{dsn}{character file path to a data source}

\item{col_select}{A character vector of column names to keep. Default is
\code{NULL} which returns all columns}

\item{...}{additional parameters to pass to
\code{\link[arrow]{FeatherReader}}}
}
\value{
object of class \code{\link[sf]{sf}}
}
\description{
Read a Feather file. Uses standard metadata information to
identify geometry columns and coordinate reference system information.
}
\details{
Reference for the metadata used:
\url{https://github.com/geopandas/geo-arrow-spec}. These are standard with
the Python \code{GeoPandas} library.
}
\examples{
# load Natural Earth low-res dataset.
# Created in Python with GeoPandas.to_feather()
path <- system.file("extdata", package = "sfarrow")

world <- st_read_feather(file.path(path, "world.feather"))

world
plot(sf::st_geometry(world))

}
\seealso{
\code{\link[arrow]{read_feather}}, \code{\link[sf]{st_read}}
}
