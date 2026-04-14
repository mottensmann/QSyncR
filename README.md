
## `QSyncR` package

------------------------------------------------------------------------

This package provides a few simple workflows for cleaning, checking and
maintaining [GeoPackage](https://www.geopackage.org/) databases that are
used in conjunction with [QGIS](https://qgis.org/) and
[QField](https://qfield.org/).

*In development*

To install the package, use
[devtools](https://github.com/r-lib/devtools):

``` r
devtools::install_github("mottensmann/QSyncR")
```

Load the package once installed:

``` r
library(QSyncR)
```

## Functions

### `sync`: Handle duplicated data

Allows to solve duplicate entries after merging file versions.
Duplicates are identified based on sharing the same `uuid`. If
differences exist, the most recent version is picked based on a
attribute representing the time stamp of most recent changes
(e.g. `mtime`).

``` r
## Load two versions of the same layer to merge
dfv1 <- sf::read_sf("~/GIS/QField/Test/Avifauna.gpkg", "Aves")
dfv2 <- sf::read_sf("~/GIS/QField/Test/Avifauna_v20260413085858.gpkg", "Aves")
```

`dfv1` contains 13126 datapoints, and `dfv2` contains 13077. Next the
two data frames are merged and conflicts are summarised.

``` r
## merge data ...
library(magrittr)
df.merged <- rbind(dfv1, dfv2) %>%
    ## keep unique rows
unique.data.frame()

## Show new entries df1
dplyr::filter(dfv1, !uuid %in% dfv2[["uuid"]]) %>%
    as.data.frame() %>%
    subset(., select = c(KUERZEL, MTIME, uuid)) %>%
    head()
#>   KUERZEL               MTIME                                   uuid
#> 1     Stk 2026-04-14 09:23:45 {f6a0c0b5-d7f7-45e0-b50c-d603892f8f87}
#> 2     Stk 2026-04-14 09:23:45 {19f4de55-6d5d-4ce9-8d17-d7fdd35a7a8a}
#> 3     Stk 2026-04-14 09:39:13 {249bfa60-b86f-4889-a5be-7cf1de9dc177}
#> 4     Stk 2026-04-14 09:38:16 {b44fc033-c125-4115-be52-28064b9f38ac}
#> 5     Stk 2026-04-14 09:38:16 {8a8141cf-76c5-47fe-bb49-3d0b68dd4b31}
#> 6     Stk 2026-04-14 09:38:16 {6e613ce0-16cd-4e73-ae57-798bc472dbde}

## Show conflicts
dplyr::filter(df.merged, uuid %in% df.merged[["uuid"]][duplicated(df.merged[["uuid"]])]) %>%
    as.data.frame() %>%
    subset(., select = c(KUERZEL, MTIME, uuid)) %>%
    dplyr::arrange(uuid) %>%
    head()
#>   KUERZEL               MTIME                                   uuid
#> 1     Ssp 2026-04-14 08:26:58 {0012c58b-fb76-4336-9d2e-b86e5950e810}
#> 2     Ssp 2026-02-03 13:48:15 {0012c58b-fb76-4336-9d2e-b86e5950e810}
#> 3     Stk 2026-04-14 09:24:35 {0029e664-ebb3-4a56-acd7-5c3684131bb3}
#> 4     Stk 2026-04-01 10:41:06 {0029e664-ebb3-4a56-acd7-5c3684131bb3}
#> 5     Stk 2026-04-14 09:42:49 {089881e1-8f01-4dfa-85f2-02633653503b}
#> 6     Stk 2026-03-26 17:38:41 {089881e1-8f01-4dfa-85f2-02633653503b}
```

Now, conflicts are solved using function `sync`:

``` r
## handle duplicates
df.resolved <- sync(DF = df.merged, UUID = "uuid", MTIME = "MTIME")
#> 52 duplicated datapoints detected
#> Solve duplicate 1 out if 52 ...finished
#> Solve duplicate 2 out if 52 ...finished
#> Solve duplicate 3 out if 52 ...finished
#> Solve duplicate 4 out if 52 ...finished
#> Solve duplicate 5 out if 52 ...finished
#> Solve duplicate 6 out if 52 ...finished
#> Solve duplicate 7 out if 52 ...finished
#> Solve duplicate 8 out if 52 ...finished
#> Solve duplicate 9 out if 52 ...finished
#> Solve duplicate 10 out if 52 ...finished
#> Solve duplicate 11 out if 52 ...finished
#> Solve duplicate 12 out if 52 ...finished
#> Solve duplicate 13 out if 52 ...finished
#> Solve duplicate 14 out if 52 ...finished
#> Solve duplicate 15 out if 52 ...finished
#> Solve duplicate 16 out if 52 ...finished
#> Solve duplicate 17 out if 52 ...finished
#> Solve duplicate 18 out if 52 ...finished
#> Solve duplicate 19 out if 52 ...finished
#> Solve duplicate 20 out if 52 ...finished
#> Solve duplicate 21 out if 52 ...finished
#> Solve duplicate 22 out if 52 ...finished
#> Solve duplicate 23 out if 52 ...finished
#> Solve duplicate 24 out if 52 ...finished
#> Solve duplicate 25 out if 52 ...finished
#> Solve duplicate 26 out if 52 ...finished
#> Solve duplicate 27 out if 52 ...finished
#> Solve duplicate 28 out if 52 ...finished
#> Solve duplicate 29 out if 52 ...finished
#> Solve duplicate 30 out if 52 ...finished
#> Solve duplicate 31 out if 52 ...finished
#> Solve duplicate 32 out if 52 ...finished
#> Solve duplicate 33 out if 52 ...finished
#> Solve duplicate 34 out if 52 ...finished
#> Solve duplicate 35 out if 52 ...finished
#> Solve duplicate 36 out if 52 ...finished
#> Solve duplicate 37 out if 52 ...finished
#> Solve duplicate 38 out if 52 ...finished
#> Solve duplicate 39 out if 52 ...finished
#> Solve duplicate 40 out if 52 ...finished
#> Solve duplicate 41 out if 52 ...finished
#> Solve duplicate 42 out if 52 ...finished
#> Solve duplicate 43 out if 52 ...finished
#> Solve duplicate 44 out if 52 ...finished
#> Solve duplicate 45 out if 52 ...finished
#> Solve duplicate 46 out if 52 ...finished
#> Solve duplicate 47 out if 52 ...finished
#> Solve duplicate 48 out if 52 ...finished
#> Solve duplicate 49 out if 52 ...finished
#> Solve duplicate 50 out if 52 ...finished
#> Solve duplicate 51 out if 52 ...finished
#> Solve duplicate 52 out if 52 ...finished

## export to gpkg
sf::st_write(df.resolved, dsn = "~/GIS/QField/Test/Avifauna_new.gpkg", layer = "Aves",
    layer_options = "OVERWRITE=YES", append = FALSE)
#> Deleting layer `Aves' using driver `GPKG'
#> Writing layer `Aves' to data source 
#>   `C:\Users\Meinolf Ottensmann\Documents\GIS\QField\Test\Avifauna_new.gpkg' using driver `GPKG'
#> options:        OVERWRITE=YES 
#> Writing 13126 features with 71 fields and geometry type Point.
```

### `VACUUM`: Reduce Geopackage file size

[SQLite](https://sqlite.org/), the underlying database format for
`GeoPackage`, does *not* release unused space back to the filesystem by
default. Hence, there is the need to *VACUUM* the database in or to
reclaim space. This is especially useful when, for example many features
where deleted and the file size remained more or less constant.

``` r
## Example
VACUUM(dsn = "~/GIS/QField/Test/Avifauna_new.gpkg")
#> File: ~/GIS/QField/Test/Avifauna_new.gpkg
#> VACUUM completed:
#> Initial size: 9179136
#> Resulting size: 9142272
#> Reduction by: 0.4%
```

### `download_raster`

Small helper function to query raster data (e.g. orthophtos) in a batch
mode.

``` r
## NOT RUN
url = c("https://dop20-rgb.s3.eu-de.cloud-object-storage.appdomain.cloud/324565774/2017-03-24/dop20rgb_32_456_5774_2_ni_2017-03-24.tif",
    "https://dop20-rgb.s3.eu-de.cloud-object-storage.appdomain.cloud/324525776/2014-05-03/dop20rgb_32_452_5776_2_ni_2014-05-03.tif")
download_raster(url, filename = basename(url), dest = "output_folder")
```
