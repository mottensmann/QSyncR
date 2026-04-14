##' clean database by removing duplicated entries based on [uuid](https://en.wikipedia.org/wiki/Universally_unique_identifier) and MTIME
##'
##' @param DF data frame after merging file versions
##' @param UUID string denoting field representing an universally unique identifier [uuid](https://en.wikipedia.org/wiki/Universally_unique_identifier)
##' @param MTIME string denoting field representing a timestamp of last modification
##' @export
sync <- function(DF = NULL, UUID = 'uuid', MTIME = 'MTIME') {
    ## detect duplicates
    if (any(duplicated(DF[[UUID]]))) {
      ## select uuids
      uuids <- unique(DF[[UUID]][duplicated(DF[[UUID]])])
      cat(length(uuids), "duplicated datapoints detected\n")
      for (i in 1:length(uuids)) {
        cat("Solve duplicate", i, "out if", length(uuids), "...")
        ## find indices of x
        indices <- which(DF[[UUID]] == uuids[i])
        ## find and delete oldest record
        indices.sorted <- order(DF[[MTIME]][indices], decreasing = T)
        DF <- DF[-indices[indices.sorted[2:length(indices.sorted)]],]
        cat("finished\n")
      }
    } else {
      cat("No duplicates found\n")
    }
    return(DF)
}

#' Download files
#'
#' @description
#' Small function to download raster files (e.g. tif, png) in a batch mode
#'
#' @param url url
#' @param filename name
#' @param dest output folder
#' @export
#'
download_raster <- function(url, filename = basename(url), dest) {
  utils::download.file(url = url, destfile = file.path(dest, filename), mode = "wb")
}

#' Reduce GeoPackage size to save disk space
#'
#' @description
#' Running VACUUM on a GeoPackage
#'
#' @param dsn Path to GeoPackage
#' @param backup optional create backup before running VACUUM
#' @importFrom DBI dbConnect
#' @importFrom RSQLite SQLite
#' @importFrom DBI dbExecute
#' @importFrom DBI dbDisconnect
#' @export
#'
VACUUM <- function(dsn = NULL, backup = NULL) {

  if (!file.exists(dsn)) stop(dsn, " not found!")
  if (!is.null(backup)) {
    file.copy(from = dsn, to = backup)
  }

  ## check file size before size reduction
  size.before <- file.info(dsn)[["size"]]

  ## Connect to the GeoPackage
  conn <- DBI::dbConnect(RSQLite::SQLite(), dsn)

  ## Run VACUUM
  DBI::dbExecute(conn, "VACUUM;")

  ## Disconnect
  DBI::dbDisconnect(conn)

  ## check file size before size reduction
  size.after <- file.info(dsn)[["size"]]

  message(
    "File: ", dsn, "\n",
    "VACUUM completed:\n",
    "Initial size: ", size.before, "\n",
    "Resulting size: ", size.after, "\n",
    "Reduction by: ", round(100 * (1 - (size.after/size.before)),2), "%\n")
}


#' Batch apply \link{VACUUM} to all geopackage files within a folder
#' @description
#' See \link{VACUUM} for details
#'
#' @param path path
#' @param recursive boolean
#' @export
#'
VACUUM.batch <- function(path = NULL, recursive = FALSE) {
if (!dir.exists(path)) stop("Provide valid path. ", path, " does not exist")
  gpkg <- list.files(path, pattern = ".gpkg", full.names = T, recursive = recursive)
  out <- sapply(gpkg, VACUUM)
}
