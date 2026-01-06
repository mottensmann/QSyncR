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
shrink_gpkg <- function(dsn = NULL, backup = NULL) {

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


#' Batch apply \link{shrink_gpkg} to all geopackage files within a folder
#' @description
#' See \link{shrink_gpkg} for details
#'
#' @param path path
#' @param recursive boolean
#' @export
#'
shrink_gpkg_batch <- function(path = NULL, recursive = FALSE) {
if (!dir.exists(path)) stop("Provide valid path. ", path, " does not exist")
  gpkg <- list.files(path, pattern = ".gpkg", full.names = T, recursive = recursive)
  out <- sapply(gpkg, shrink_gpkg)
}
