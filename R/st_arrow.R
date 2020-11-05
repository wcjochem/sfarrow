#' Create standardised geo metadata for Parquet files
#'
#' @param df object of class \code{sf}
#'
#' @details Reference for metadata standard:
#'   \url{https://github.com/geopandas/geo-arrow-spec}. This is compatible with
#'   \code{GeoPandas} Parquet files.
#'
#' @return JSON formatted list with geo-metadata
create_metadata <- function(df){
  warning(strwrap("This is an initial implementation of Parquet/Feather file support
                  and geo metadata. This is tracking version 0.1.0 of the metadata
                  (https://github.com/geopandas/geo-arrow-spec). This metadata
                  specification may change and does not yet make stability promises.
                  We do not yet recommend using this in a production setting unless
                  you are able to rewrite your Parquet/Feather files.",
                  prefix = "\n", initial = ""
         ), call.=FALSE)

  # reference: https://github.com/geopandas/geo-arrow-spec
  geom_cols <- lapply(df, function(i) inherits(i, "sfc"))
  geom_cols <- names(which(geom_cols==TRUE))
  col_meta <- list()

  for(col in geom_cols){
    col_meta[[col]] <- list(crs = sf::st_crs(df[[col]])$wkt,
                            encoding = "WKB",
                            bbox = as.numeric(sf::st_bbox(df[[col]])))
  }

  geo_metadata <- list(primary_column = attr(df, "sf_column"),
                       columns = col_meta,
                       schema_version = "0.1.0",
                       creator = list(library="sfarrow"))

  return(jsonlite::toJSON(geo_metadata, auto_unbox=TRUE))
}

#' Convert \code{sfc} geometry columns into a WKB binary format
#'
#' @param df \code{sf} object
#'
#' @details Allows for more than one geometry column in \code{sfc} format
#'
#' @return \code{data.frame} with binary geometry column(s)
encode_wkb <- function(df){
  geom_cols <- lapply(df, function(i) inherits(i, "sfc"))
  geom_cols <- names(which(geom_cols==TRUE))

  df <- as.data.frame(df)

  for(col in geom_cols){
    obj_geo <- sf::st_as_binary(df[[col]])
    attr(obj_geo, "class") <- c("arrow_binary", attr(obj_geo, "class"))
    df[[col]] <- obj_geo
  }
  return(df)
}


#' Read a Parquet file to `sf` object
#'
#' @description Read a Parquet file. Uses standard metadata information to
#'   identify geometry columns and coordinate reference system information.
#' @param dsn character file path to a data source
#' @param col_select. a character vector of column names to keep. Default is
#'   \code{NULL} which returns all columns
#' @param props additional \code{\link[arrow]{ParquetReaderProperties}}
#' @param ... additional parameters to pass to
#'   \code{\link[arrow]{ParquetFileReader}}
#'
#' @details Reference for the metadata used:
#'   \url{https://github.com/geopandas/geo-arrow-spec}. These are standard with
#'   the Python \code{GeoPandas} library.
#'
#' @return object of class \code{sf}
#'
#' @examples
#' # load Natural Earth low-res dataset. Created in Python with GeoPandas.to_parquet()
#' path <- system.file("extdata", package = "sfarrow")
#'
#' world <- st_read_parquet(file.path(path, "world.parquet"))
#'
#' world
#' plot(sf::st_geometry(world))
#'
#' @export
st_read_parquet <- function(dsn, col_select = NULL,
                            props = arrow::ParquetReaderProperties$create(), ...){
  if(missing(dsn)){
    stop("Please provide a data source")
  }

  pq <- arrow::ParquetFileReader$create(dsn, props = props, ...)
  schema <- pq$GetSchema()
  metadata <- schema$metadata

  if(!"geo" %in% names(metadata)){
    stop("No geometry metadata found. Use arrow::read_parquet")
  }

  if(!is.null(col_select)){
    indices <- which(names(schema) %in% col_select) - 1L # 0-indexing
    tbl <- pq$ReadTable(indices)
  } else{
    tbl <- pq$ReadTable()
  }

  geo <- jsonlite::fromJSON(metadata$geo)

  # covert and create sf
  tbl <- data.frame(tbl)

  geom_cols <- names(geo$columns)
  geom_cols <- intersect(colnames(tbl), geom_cols)

  primary_geom <- geo$primary_column

  if(length(geom_cols) < 1){ stop("Malformed file and geo metatdata.") }
  if(!primary_geom %in% geom_cols){
    primary_geom <- geom_cols[1]
    warning("Primary geometry column not found, using next available.")
  }

  for(col in geom_cols){
    tbl[[col]] <- sf::st_as_sfc(tbl[[col]],
                                crs = sf::st_crs(geo$columns[[col]]$crs))
  }

  tbl <- sf::st_sf(tbl, sf_column_name = primary_geom)
  return(tbl)
}


#' Write `sf` object to Parquet file
#'
#' @description Convert a simple features spatial object from \code{sf} and
#'   write to a Parquet file using \code{\link[arrow]{write_parquet}}. Geometry
#'   columns (type \code{sfc}) are converted to well-known binary (WKB) format.
#' @param obj object of class \code{sf}
#' @param dsn data source name. A path and file name with .parquet extension
#' @param ... additional options to pass to \code{\link[arrow]{write_parquet}}
#'
#' @examples
#' nc <- sf::st_read(system.file("shape/nc.shp", package="sf"))
#'
#' st_write_parquet(obj=nc, dsn=file.path(tempdir(), "nc.parquet"))
#'
#' # In Python, read the new file with geopandas.read_parquet(...)
#'
#' nc_p <- st_read_parquet(file.path(tempdir(), "nc.parquet"))
#'
#' @export
st_write_parquet <- function(obj, dsn, ...){
  if(!inherits(obj, "sf")){
    stop("Must be sf data format")
  }

  if(missing(dsn)){
    stop("Missing output file")
  }

  geo_metadata <- create_metadata(obj)

  df <- encode_wkb(obj)
  tbl <- arrow::Table$create(df)

  tbl$metadata[["geo"]] <- geo_metadata

  arrow::write_parquet(tbl, sink = dsn, ...)
}

