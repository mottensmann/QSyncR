
## `GeoPackageR` package

------------------------------------------------------------------------

This package provides a few simple workflows for cleaning, checking and
maintaining [GeoPackage](https://www.geopackage.org/) databases that are
used in [QGIS](https://qgis.org/).

*In development*

To install the package, use
[devtools](https://github.com/r-lib/devtools):

``` r
devtools::install_github("mottensmann/GeoPackageR")
```

Load the package once installed:

``` r
library(GeoPackageR)
```

## Functions

### `shrink_gpkg`

[SQLite](https://sqlite.org/), the underlying database format for
`GeoPackage`, does *not* release unused space back to the filesystem by
default. Hence, there is the need to *vacuum* the database in or to
reclaim space. This is especially useful when, for example many features
where deleted and the file size remained more or less constant.

``` r
## Example
shrink_gpkg(dsn = "~/GIS/QField/Backups/Avifauna.gpkg")
#> VACUUM completed:
#> Initial size: 9940992
#> Resulting size: 4857856
#> Reduction by: 51.13%
```
