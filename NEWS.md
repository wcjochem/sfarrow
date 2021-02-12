# sfarrow 0.3.0

* New `st_write_feather()` and `st_read_feather()` allow similar functionality
to read/write to .feather formats with `sf` objects.
* Updated 
* Following `arrow` 2.0.0, properties to `st_write_parquet()` are deprecated.

# sfarrow 0.2.0

* New `write_sf_dataset()` and `read_sf_dataset()` to handle partitioned
datasets. These also work with `dplyr` and grouped variables to define
paritions.

* New vignettes added for documentation of all functions.

# sfarrow 0.1.1

* `st_write_parquet()` now warns uses that geo metadata format may change.

# sfarrow 0.1.0

* This is the initial release of `sfarrow`.
