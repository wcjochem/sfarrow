% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/st_arrow.R
\name{st_write_feather}
\alias{st_write_feather}
\title{Write \code{sf} object to Feather file}
\usage{
st_write_feather(obj, dsn, ...)
}
\arguments{
\item{obj}{object of class \code{sf}}

\item{dsn}{data source name. A path and file name with .parquet extension}

\item{...}{additional options to pass to \code{\link[arrow]{write_feather}}}
}
\description{
Convert a simple features spatial object from \code{sf} and
write to a Feather file using \code{\link[arrow]{write_feather}}. Geometry
columns (type \code{sfc}) are converted to well-known binary (WKB) format.
}
\examples{
nc <- sf::st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)

st_write_feather(obj=nc, dsn=file.path(tempdir(), "nc.feather"))

# In Python, read the new file with geopandas.read_feather(...)

nc_f <- st_read_feather(file.path(tempdir(), "nc.feather"))

}
\seealso{
\code{\link[arrow]{write_feather}}
}