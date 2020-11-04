
<!-- README.md is generated from README.Rmd. Please edit that file -->

# sfarrow: An R implementation to read/write between Simple Feature (`sf`)

spatial objects to parquet files.

`sfarrow` is an experimental and work-in-progress file for testing how
to read/write Parquet files from `sf` objects.

Simple features are a popular format for representing spatial vector
data using `data.frames` and a list-like geometry column, implemented in
the R package `[sf](https://r-spatial.github.io/sf/)`. Parquet files are
an open-source, column-oriented data storage formate from Apache
(<https://parquet.apache.org/>) which enable efficient read/writing for
large files. Parquet files are also becoming popular across programming
languages and can be used in `R` using the package
`[arrow](https://github.com/apache/arrow/)`. The `sfarrow`
implementation translates simple feature data objects and reads/writes
Parquet files. A key goal is for interoperability of the parquet files
(particularly with Python `GeoPandas`), so coordinate reference system
information is maintained in a standard metadata format
(<https://github.com/geopandas/geo-arrow-spec>).

## Installation

Installation of the `sfarrow` package is through Github:

``` r
devtools::install_github("https://github.com/wcjochem/sfarrow.git@main")
#> Downloading GitHub repo wcjochem/sfarrow@master
#> Error in utils::download.file(url, path, method = method, quiet = quiet,  : 
#>   cannot open URL 'https://api.github.com/repos/wcjochem/sfarrow/tarball/master'
```

## Basic usage

These files can be read within Python using `GeoPandas`

``` python
nc = geopandas.read_parquet('path/to/file/nc.parquet')
```

## Acknowledgements

``` r
citation("sfarrow")
#> 
#> To cite package 'sfarrow' in publications use:
#> 
#>   Chris Jochem (2020). sfarrow: Read/write Simple Feature Objects
#>   (`sf`) to Parquet Files with Apache Arrow. R package version 0.1.0.
#>   https://github.com/wcjochem/sfarrow
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     title = {sfarrow: Read/write Simple Feature Objects (`sf`) to Parquet Files with Apache Arrow},
#>     author = {Chris Jochem},
#>     year = {2020},
#>     note = {R package version 0.1.0},
#>     url = {https://github.com/wcjochem/sfarrow},
#>   }
```

This work benefited from the work by developers in the GeoPandas, Arrow,
and r-spatial teams. Thank you to their excellent, open-source work.
