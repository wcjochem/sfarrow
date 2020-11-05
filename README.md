
<!-- README.md is generated from README.Rmd. Please edit that file -->

# sfarrow: An R implementation to read/write between `sf` spatial objects to Parquet files

`sfarrow` is an experimental and work-in-progress package for testing
how to read/write Parquet files from `sf` objects.

Simple features are a popular format for representing spatial vector
data using `data.frames` and a list-like geometry column, implemented in
the R package [`sf`](https://r-spatial.github.io/sf/). Parquet files are
an open-source, column-oriented data storage format from Apache
(<https://parquet.apache.org/>) which enable efficient read/writing for
large files. Parquet files are also becoming popular across programming
languages and can be used in `R` using the package
[`arrow`](https://github.com/apache/arrow/).

The `sfarrow` implementation translates simple feature data objects
using WKB and reads/writes Parquet files. A key goal of the package is
for interoperability of the parquet files (particularly with Python
`GeoPandas`), so coordinate reference system information is maintained
in a standard metadata format
(<https://github.com/geopandas/geo-arrow-spec>). Note to users: this
metadata format is not yet stable for production uses and may change in
the future.

## Installation

Installation of the `sfarrow` package is through Github:

``` r
devtools::install_github("wcjochem/sfarrow@main")
```

Load the library to begin using.

``` r
library(sfarrow)
```

### `arrow` package

The installation requires the Arrow library which should be installed
with the `R` package `arrow` dependency. However, some systems may need
to follow additional steps to enable full support of that library.
Please refer to the [`arrow` package
documentation](https://cran.r-project.org/web/packages/arrow/vignettes/install.html).

## Basic usage

Reading Parquet data of spatial files created with `GeoPandas`.

``` r
# load Natural Earth low-res dataset. 
# Created in Python with GeoPandas.to_parquet()
path <- system.file("extdata", "world.parquet", package = "sfarrow")

world <- st_read_parquet(path)

head(world)
#> Simple feature collection with 6 features and 5 fields
#> geometry type:  GEOMETRY
#> dimension:      XY
#> bbox:           xmin: -180 ymin: -18.28799 xmax: 180 ymax: 83.23324
#> geographic CRS: WGS 84
#>     pop_est     continent                     name iso_a3 gdp_md_est
#> 1    920938       Oceania                     Fiji    FJI  8.374e+03
#> 2  53950935        Africa                 Tanzania    TZA  1.506e+05
#> 3    603253        Africa                W. Sahara    ESH  9.065e+02
#> 4  35623680 North America                   Canada    CAN  1.674e+06
#> 5 326625791 North America United States of America    USA  1.856e+07
#> 6  18556698          Asia               Kazakhstan    KAZ  4.607e+05
#>                         geometry
#> 1 MULTIPOLYGON (((180 -16.067...
#> 2 POLYGON ((33.90371 -0.95, 3...
#> 3 POLYGON ((-8.66559 27.65643...
#> 4 MULTIPOLYGON (((-122.84 49,...
#> 5 MULTIPOLYGON (((-122.84 49,...
#> 6 POLYGON ((87.35997 49.21498...
plot(sf::st_geometry(world))
```

<img src="man/figures/REAsDME-unnamed-chunk-3-1.png" width="100%" />

Writing `sf` objects to Parquet format files.

``` r
nc <- sf::st_read(system.file("shape/nc.shp", package="sf"))
#> Reading layer `nc' from data source `/home/jochem/R/x86_64-pc-linux-gnu-library/3.6/sf/shape/nc.shp' using driver `ESRI Shapefile'
#> Simple feature collection with 100 features and 14 fields
#> geometry type:  MULTIPOLYGON
#> dimension:      XY
#> bbox:           xmin: -84.32385 ymin: 33.88199 xmax: -75.45698 ymax: 36.58965
#> geographic CRS: NAD27

st_write_parquet(obj=nc, dsn=file.path(tempdir(), "nc.parquet"))
#> Warning: This is an initial implementation of Parquet/Feather file support and
#> geo metadata. This is tracking version 0.1.0 of the metadata
#> (https://github.com/geopandas/geo-arrow-spec). This metadata
#> specification may change and does not yet make stability promises.  We
#> do not yet recommend using this in a production setting unless you are
#> able to rewrite your Parquet/Feather files.

# read back into R
nc_p <- st_read_parquet(file.path(tempdir(), "nc.parquet"))

head(nc_p)
#> Simple feature collection with 6 features and 14 fields
#> geometry type:  MULTIPOLYGON
#> dimension:      XY
#> bbox:           xmin: -81.74107 ymin: 36.07282 xmax: -75.77316 ymax: 36.58965
#> geographic CRS: NAD27
#>    AREA PERIMETER CNTY_ CNTY_ID        NAME  FIPS FIPSNO CRESS_ID BIR74 SID74
#> 1 0.114     1.442  1825    1825        Ashe 37009  37009        5  1091     1
#> 2 0.061     1.231  1827    1827   Alleghany 37005  37005        3   487     0
#> 3 0.143     1.630  1828    1828       Surry 37171  37171       86  3188     5
#> 4 0.070     2.968  1831    1831   Currituck 37053  37053       27   508     1
#> 5 0.153     2.206  1832    1832 Northampton 37131  37131       66  1421     9
#> 6 0.097     1.670  1833    1833    Hertford 37091  37091       46  1452     7
#>   NWBIR74 BIR79 SID79 NWBIR79                       geometry
#> 1      10  1364     0      19 MULTIPOLYGON (((-81.47276 3...
#> 2      10   542     3      12 MULTIPOLYGON (((-81.23989 3...
#> 3     208  3616     6     260 MULTIPOLYGON (((-80.45634 3...
#> 4     123   830     2     145 MULTIPOLYGON (((-76.00897 3...
#> 5    1066  1606     3    1197 MULTIPOLYGON (((-77.21767 3...
#> 6     954  1838     5    1237 MULTIPOLYGON (((-76.74506 3...
plot(sf::st_geometry(nc_p))
```

<img src="man/figures/REAsDME-unnamed-chunk-4-1.png" width="100%" />

These Parquet files created with `sfarrow` can be read within Python
using `GeoPandas`.

``` python
nc = geopandas.read_parquet('path/to/file/nc.parquet')
```

## Contributions

Contributions, questions, ideas, and issue reports are welcome. Please
raise an issue to discuss or submit a pull request.

## Acknowledgements

This work benefited from the work by developers in the GeoPandas, Arrow,
and r-spatial teams. Thank you to their excellent, open-source work.

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
