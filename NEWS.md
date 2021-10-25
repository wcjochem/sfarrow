# sfarrow 0.4.1

* Cleaning examples to remove reverse dependency check errors in `arrow`
(reported by @jonkeane).

# sfarrow 0.4.0

* New `find_geom` parameter in `read_sf_dataset()` adds any geometry columns to
the `arrow_dplyr_query`. Default behaviour is `FALSE` for consistent behaviour.

* Cleaning documentation and preparing for CRAN submission

# sfarrow 0.3.0

* New `st_write_feather()` and `st_read_feather()` allow similar functionality
to read/write to .feather formats with `sf` objects.
* Following `arrow` 2.0.0, properties to `st_write_parquet()` are deprecated.

# sfarrow 0.2.0

* New `write_sf_dataset()` and `read_sf_dataset()` to handle partitioned
datasets. These also work with `dplyr` and grouped variables to define
partitions.

* New vignettes added for documentation of all functions.

# sfarrow 0.1.1

* `st_write_parquet()` now warns uses that geo metadata format may change.

# sfarrow 0.1.0

* This is the initial release of `sfarrow`.
