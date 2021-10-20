#' Create standardised geo metadata for Parquet files
#'
#' @param df object of class \code{sf}
#'
#' @details Reference for metadata standard:
#'   \url{https://github.com/geopandas/geo-arrow-spec}. This is compatible with
#'   \code{GeoPandas} Parquet files.
#'
#' @return JSON formatted list with geo-metadata
#' @keywords internal
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


#' Basic checking of key geo metadata columns
#'
#' @param metadata list for geo metadata
#' @return None. Throws an error and stops execution
#' @keywords internal
validate_metadata <- function(metadata){
  if(is.null(metadata) | !is.list(metadata)){
    stop("Error: empty or malformed geo metadata", call. = F)
  } else{
    # check for presence of required geo keys
    req_names <- c("primary_column", "columns")
    for(n in req_names){
      if(!n %in% names(metadata)){
        stop(paste0("Required name: '", n, "' not found in geo metadata"),
             call. = FALSE)
      }
    }
    # check for presence of required geometry columns info
    req_geo_names <- c("crs", "encoding")
    for(c in names(metadata[["columns"]])){
      geo_col <- metadata[["columns"]][[c]]

      for(ng in req_geo_names){
        if(!ng %in% names(geo_col)){
          stop(paste0("Required 'geo' metadata item '", ng, "' not found in ", c),
               call. = FALSE)
        }
        if(geo_col[["encoding"]] != "WKB"){
          stop("Only well-known binary (WKB) encoding is currently supported.",
               call. = FALSE)
        }
      }
    }
  }
}


#' Convert \code{sfc} geometry columns into a WKB binary format
#'
#' @param df \code{sf} object
#'
#' @details Allows for more than one geometry column in \code{sfc} format
#'
#' @return \code{data.frame} with binary geometry column(s)
#' @keywords internal
encode_wkb <- function(df){
  geom_cols <- lapply(df, function(i) inherits(i, "sfc"))
  geom_cols <- names(which(geom_cols==TRUE))

  df <- as.data.frame(df)

  for(col in geom_cols){
    obj_geo <- sf::st_as_binary(df[[col]])
    attr(obj_geo, "class") <- c("arrow_binary", "vctrs_vctr", attr(obj_geo, "class"), "list")
    df[[col]] <- obj_geo
  }
  return(df)
}


#' Helper function to convert 'data.frame' to \code{sf}
#'
#' @param tbl \code{data.frame} from reading an Arrow dataset
#' @param metadata \code{list} of validated geo metadata
#'
#' @return object of \code{sf} with CRS and geometry columns
#' @keywords internal
arrow_to_sf <- function(tbl, metadata){
  geom_cols <- names(metadata$columns)
  geom_cols <- intersect(colnames(tbl), geom_cols)

  primary_geom <- metadata$primary_column

  if(length(geom_cols) < 1){ stop("Malformed file and geo metatdata.") }
  if(!primary_geom %in% geom_cols){
    primary_geom <- geom_cols[1]
    warning("Primary geometry column not found, using next available.")
  }

  for(col in geom_cols){
    tbl[[col]] <- sf::st_as_sfc(tbl[[col]],
                                crs = sf::st_crs(metadata$columns[[col]]$crs))
  }

  tbl <- sf::st_sf(tbl, sf_column_name = primary_geom)
  return(tbl)
}


#' Read a Parquet file to \code{sf} object
#'
#' @description Read a Parquet file. Uses standard metadata information to
#'   identify geometry columns and coordinate reference system information.
#' @param dsn character file path to a data source
#' @param col_select A character vector of column names to keep. Default is
#'   \code{NULL} which returns all columns
#' @param props Now deprecated in \code{\link[arrow]{read_parquet}}.
#' @param ... additional parameters to pass to
#'   \code{\link[arrow]{ParquetFileReader}}
#'
#' @details Reference for the metadata used:
#'   \url{https://github.com/geopandas/geo-arrow-spec}. These are standard with
#'   the Python \code{GeoPandas} library.
#'
#' @seealso \code{\link[arrow]{read_parquet}}, \code{\link[sf]{st_read}}
#'
#' @return object of class \code{\link[sf]{sf}}
#'
#' @examples
#' # load Natural Earth low-res dataset.
#' # Created in Python with GeoPandas.to_parquet()
#' path <- system.file("extdata", package = "sfarrow")
#'
#' world <- st_read_parquet(file.path(path, "world.parquet"))
#'
#' world
#' plot(sf::st_geometry(world))
#'
#' @export
st_read_parquet <- function(dsn, col_select = NULL,
                            props = NULL, ...){
  if(missing(dsn)){
    stop("Please provide a data source")
  }

  if(!is.null(props)){ warning("'props' is deprecated in `arrow`. See arrow::ParquetFileWriter.") }

  pq <- arrow::ParquetFileReader$create(dsn, ...)
  schema <- pq$GetSchema()
  metadata <- schema$metadata

  if(!"geo" %in% names(metadata)){
    stop("No geometry metadata found. Use arrow::read_parquet")
  } else{
    geo <- jsonlite::fromJSON(metadata$geo)
    validate_metadata(geo)
  }

  if(!is.null(col_select)){
    indices <- which(names(schema) %in% col_select) - 1L # 0-indexing
    tbl <- pq$ReadTable(indices)
  } else{
    tbl <- pq$ReadTable()
  }

  # covert and create sf
  tbl <- data.frame(tbl)
  tbl <- arrow_to_sf(tbl, geo)

  return(tbl)
}


#' Read a Feather file to \code{sf} object
#'
#' @description Read a Feather file. Uses standard metadata information to
#'   identify geometry columns and coordinate reference system information.
#' @param dsn character file path to a data source
#' @param col_select A character vector of column names to keep. Default is
#'   \code{NULL} which returns all columns
#' @param ... additional parameters to pass to
#'   \code{\link[arrow]{FeatherReader}}
#'
#' @details Reference for the metadata used:
#'   \url{https://github.com/geopandas/geo-arrow-spec}. These are standard with
#'   the Python \code{GeoPandas} library.
#'
#' @seealso \code{\link[arrow]{read_feather}}, \code{\link[sf]{st_read}}
#'
#' @return object of class \code{\link[sf]{sf}}
#'
#' @examples
#' # load Natural Earth low-res dataset.
#' # Created in Python with GeoPandas.to_feather()
#' path <- system.file("extdata", package = "sfarrow")
#'
#' world <- st_read_feather(file.path(path, "world.feather"))
#'
#' world
#' plot(sf::st_geometry(world))
#'
#' @export
st_read_feather <- function(dsn, col_select = NULL, ...){
  if(missing(dsn)){
    stop("Please provide a data source")
  }

  f <- arrow::read_feather(dsn, col_select, as_data_frame = FALSE, ...)
  schema <- f$schema
  metadata <- schema$metadata

  if(!"geo" %in% names(metadata)){
    stop("No geometry metadata found. Use arrow::read_parquet")
  } else{
    geo <- jsonlite::fromJSON(metadata$geo)
    validate_metadata(geo)
  }

  # covert and create sf
  tbl <- data.frame(f)
  tbl <- arrow_to_sf(tbl, geo)

  return(tbl)
}


#' Write \code{sf} object to Parquet file
#'
#' @description Convert a simple features spatial object from \code{sf} and
#'   write to a Parquet file using \code{\link[arrow]{write_parquet}}. Geometry
#'   columns (type \code{sfc}) are converted to well-known binary (WKB) format.
#'
#' @param obj object of class \code{\link[sf]{sf}}
#' @param dsn data source name. A path and file name with .parquet extension
#' @param ... additional options to pass to \code{\link[arrow]{write_parquet}}
#'
#' @return \code{obj} invisibly
#'
#' @seealso \code{\link[arrow]{write_parquet}}
#'
#' @examples
#' # read spatial object
#' nc <- sf::st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
#'
#' # create temp file
#' tf <- tempfile(fileext = '.parquet')
#' on.exit(unlink(tf))
#'
#' # write out object
#' st_write_parquet(obj = nc, dsn = tf)
#'
#' # In Python, read the new file with geopandas.read_parquet(...)
#' # read back into R
#' nc_p <- st_read_parquet(tf)
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

  invisible(obj)
}


#' Write \code{sf} object to Feather file
#'
#' @description Convert a simple features spatial object from \code{sf} and
#'   write to a Feather file using \code{\link[arrow]{write_feather}}. Geometry
#'   columns (type \code{sfc}) are converted to well-known binary (WKB) format.
#'
#' @param obj object of class \code{\link[sf]{sf}}
#' @param dsn data source name. A path and file name with .parquet extension
#' @param ... additional options to pass to \code{\link[arrow]{write_feather}}
#'
#' @return \code{obj} invisibly
#'
#' @seealso \code{\link[arrow]{write_feather}}
#'
#' @examples
#' # read spatial object
#' nc <- sf::st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
#'
#' # create temp file
#' tf <- tempfile(fileext = '.feather')
#' on.exit(unlink(tf))
#'
#' # write out object
#' st_write_feather(obj = nc, dsn = tf)
#'
#' # In Python, read the new file with geopandas.read_feather(...)
#' # read back into R
#' nc_f <- st_read_feather(tf)
#'
#' @export
st_write_feather <- function(obj, dsn, ...){
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

  arrow::write_feather(tbl, sink = dsn, ...)

  invisible(obj)
}


#' Read an Arrow multi-file dataset and create \code{sf} object
#'
#' @param dataset a \code{Dataset} object created by \code{arrow::open_dataset}
#'   or an \code{arrow_dplyr_query}
#' @param find_geom logical. Only needed when returning a subset of columns.
#'   Should all available geometry columns be selected and added to to the
#'   dataset query without being named? Default is \code{FALSE} to require
#'   geometry column(s) to be selected specifically.
#'
#' @details This function is primarily for use after opening a dataset with
#'   \code{arrow::open_dataset}. Users can then query the \code{arrow Dataset}
#'   using \code{dplyr} methods such as \code{\link[dplyr]{filter}} or
#'   \code{\link[dplyr]{select}}. Passing the resulting query to this function
#'   will parse the datasets and create an \code{sf} object. The function
#'   expects consistent geographic metadata to be stored with the dataset in
#'   order to create \code{\link[sf]{sf}} objects.
#'
#' @return object of class \code{\link[sf]{sf}}
#'
#' @seealso \code{\link[arrow]{open_dataset}}, \code{\link[sf]{st_read}}, \code{\link{st_read_parquet}}
#'
#' @examples
#' # read spatial object
#' nc <- sf::st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
#'
#' # create random grouping
#' nc$group <- sample(1:3, nrow(nc), replace = TRUE)
#'
#' # use dplyr to group the dataset. %>% also allowed
#' nc_g <- dplyr::group_by(nc, group)
#'
#' # write out to parquet datasets
#' tf <- tempfile()  # create temporary location
#' on.exit(unlink(tf))
#' # partitioning determined by dplyr 'group_vars'
#' write_sf_dataset(nc_g, path = tf)
#'
#' list.files(tf, recursive = TRUE)
#'
#' # open parquet files from dataset
#' ds <- arrow::open_dataset(tf)
#'
#' # create a query. %>% also allowed
#' q <- dplyr::filter(ds, group == 1)
#'
#' # read the dataset (piping syntax also works)
#' nc_d <- read_sf_dataset(dataset = q)
#'
#' nc_d
#' plot(sf::st_geometry(nc_d))
#'
#' @export
read_sf_dataset <- function(dataset, find_geom = FALSE){
  if(missing(dataset)){
    stop("Must provide an Arrow dataset or 'dplyr' arrow query")
  }

  if(inherits(dataset, "arrow_dplyr_query")){
    metadata <- dataset$.data$metadata
  } else{
    metadata <- dataset$metadata
  }

  if(!"geo" %in% names(metadata)){
    stop("No geometry metadata found. Use arrow::read_parquet")
  } else{
    geo <- jsonlite::fromJSON(metadata$geo)
    validate_metadata(geo)
  }

  if(find_geom){
    geom_cols <- names(geo$columns)
    dataset <- dplyr::select(dataset$.data$clone(),
                             c(names(dataset), geom_cols))
  }

  # execute query, or read dataset connection
  tbl <- dplyr::collect(dataset)
  tbl <- data.frame(tbl)

  tbl <- arrow_to_sf(tbl, geo)

  return(tbl)
}


#' Write \code{sf} object to an Arrow multi-file dataset
#'
#' @param obj object of class \code{\link[sf]{sf}}
#' @param path string path referencing a directory for the output
#' @param format output file format ("parquet" or "feather")
#' @param partitioning character vector of columns in \code{obj} for grouping or
#'   the \code{dplyr::group_vars}
#' @param ... additional arguments and options passed to
#'   \code{arrow::write_dataset}
#'
#' @details Translate an \code{sf} spatial object to \code{data.frame} with WKB
#'   geometry columns and then write to an \code{arrow} dataset with
#'   partitioning. Allows for \code{dplyr} grouped datasets (using
#'   \code{\link[dplyr]{group_by}}) and uses those variables to define
#'   partitions.
#'
#' @return \code{obj} invisibly
#'
#' @seealso \code{\link[arrow]{write_dataset}}, \code{\link{st_read_parquet}}
#'
#' @examples
#' # read spatial object
#' nc <- sf::st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
#'
#' # create random grouping
#' nc$group <- sample(1:3, nrow(nc), replace = TRUE)
#'
#' # use dplyr to group the dataset. %>% also allowed
#' nc_g <- dplyr::group_by(nc, group)
#'
#' # write out to parquet datasets
#' tf <- tempfile()  # create temporary location
#' on.exit(unlink(tf))
#' # partitioning determined by dplyr 'group_vars'
#' write_sf_dataset(nc_g, path = tf)
#'
#' list.files(tf, recursive = TRUE)
#'
#' # open parquet files from dataset
#' ds <- arrow::open_dataset(tf)
#'
#' # create a query. %>% also allowed
#' q <- dplyr::filter(ds, group == 1)
#'
#' # read the dataset (piping syntax also works)
#' nc_d <- read_sf_dataset(dataset = q)
#'
#' nc_d
#' plot(sf::st_geometry(nc_d))
#'
#' @export
write_sf_dataset <- function(obj, path,
                             format = "parquet",
                             partitioning = dplyr::group_vars(obj),
                             ...){

  if(!inherits(obj, "sf")){
    stop("Must be an sf data format. Use arrow::write_dataset instead")
  }

  if(missing(path)){
    stop("Must provide a file path for output dataset")
  }

  geo_metadata <- create_metadata(obj)

  if(inherits(obj, "grouped_df")){
    partitioning <- force(partitioning)
    dataset <- dplyr::group_modify(obj, ~ encode_wkb(.x))
    dataset <- dplyr::ungroup(dataset)
  } else{
    dataset <- encode_wkb(obj)
  }

  tbl <- arrow::Table$create(dataset)
  tbl$metadata[["geo"]] <- geo_metadata

  arrow::write_dataset(dataset=tbl,
                       path = path,
                       format = format,
                       partitioning = partitioning,
                       ...)

  invisible(obj)
}
