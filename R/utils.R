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

#' Compare folders containing qfield attachments
#'
#' @description
#' To save space in a QFieldCloud-Project it can help to reduce image sizes by replacing original file versions by a thumbnail. This function allows to quickly identify new files and check for deleted images in the cloud.
#'
#'
#' @param path_qfield path to QFieldCloud-Project
#' @param path_local path to a local copy of attachments of the same QFieldCloud-Project
#' @export
#'
compare.DCIM <- function(path_qfield = NULL, path_local = NULL) {

  cat('Check data in', path_qfield, '\n')
  files_cloud <- data.frame(
    name = list.files(file.path(path_qfield, 'DCIM')))

  cat('Check data in', file.path(path_local, 'DCIM/org'), '\n')
  files_local <- data.frame(
    name = list.files(file.path(path_local, 'DCIM/org')))

  out <- list(added = dplyr::anti_join(x = files_cloud, y = files_local),
              combined = dplyr::full_join(x = files_cloud, y = files_local),
              removed = dplyr::anti_join(y = files_cloud, x = files_local))

  cat(nrow(out[["added"]]), 'files are new\n',
      nrow(out[["removed"]]), 'files were removed\n',
      nrow(out[["combined"]]), 'files combined\n')

  cat('Copy new files to', file.path(path_local, 'DCIM/org'), '\n')
  file.copy(from = file.path(file.path(path_qfield, 'DCIM'), out[["added"]][["name"]]),
            to = file.path(file.path(path_local, 'DCIM/org'), out[["added"]][["name"]]))

  cat('Copy new files to', file.path(path_local, 'DCIM/import'), '\n' )
  file.copy(from = file.path(file.path(path_qfield, 'DCIM'), out[["added"]][["name"]]),
            to = file.path(file.path(path_local, 'DCIM/import')))

  return(out)
}

#' Build MBTiles from a directory of TIFF files
#'
#' @description
#' Builds a VRT mosaic from a directory of TIFF files and converts it to an
#' MBTiles file. Optionally clips to a bounding box before conversion, and
#' adds overview levels (zoom pyramid) via \code{gdaladdo}.
#'
#' @param input Character. Folder containing TIFF files.
#' @param mbtiles Character. Path for the output MBTiles file.
#' @param extent Optional numeric vector \code{c(xmin, ymin, xmax, ymax)}.
#'   Clips the VRT to this bounding box before conversion. Must be in the
#'   same CRS as the input rasters.
#' @param zoom_level Optional integer. Maximum zoom level written to the
#'   MBTiles. If \code{NULL}, GDAL determines this automatically from the
#'   input resolution.
#' @param overviews Logical (default \code{TRUE}). If \code{TRUE}, runs
#'   \code{gdaladdo} after translation to build zoom-level overviews inside
#'   the MBTiles (powers of 2 up to level 11).
#' @param format Character. Tile image format: \code{"PNG"} (lossless,
#'   default) or \code{"JPEG"} (lossy, smaller file).
#' @param pattern Character. Regex pattern for selecting files in
#'   \code{input} (default \code{"\\\\.tif$"}).
#' @param recursive Logical. Search for TIFFs recursively? (default
#'   \code{FALSE}).
#' @keywords experimental
#'
build.mbtiles <- function(input       = '~/GIS/GeoTiff/dgk5',
                          mbtiles     = '~/GIS/GeoTiff/dgk5.mbtiles',
                          extent      = NULL,
                          zoom_level  = NULL,
                          overviews   = TRUE,
                          format = "PNG",
                          pattern     = "\\.tif$",
                          recursive   = FALSE) {

  ## set paramameters
  if (is.null(mbtiles)) stop('Set output for mbtiles')
  # Expand ~ so GDAL CLI receives absolute paths on Windows
  mbtiles <- path.expand(mbtiles)
  input   <- path.expand(input)
  vrt = stringr::str_replace(mbtiles, 'mbtiles', 'vrt')

  ## Discover TIFFs
  tifs <- list.files(input, pattern = pattern, full.names = TRUE, recursive = recursive)
  if (length(tifs) == 0) stop("No TIFF files found in: ", input)
  message("Found ", length(tifs), " TIFF file(s).")

  ## Build VRT (optionally clipped to extent)
  ## Delete existing VRT first; -overwrite is not supported by the GDAL API
  if (file.exists(vrt)) file.remove(vrt)
  vrt_args <- list(gdalfile   = tifs,
                   output.vrt = vrt)
  if (!is.null(extent)) {
    if (length(extent) != 4) {
      stop("`extent` must be a numeric vector of length 4: c(xmin, ymin, xmax, ymax)")
    }
    vrt_args$te <- extent  # gdalbuildvrt -te xmin ymin xmax ymax
    message("Clipping VRT to extent: xmin=", extent[1], " ymin=", extent[2],
            " xmax=", extent[3], " ymax=", extent[4])
  }
  message("Building VRT...")
  do.call(gdalUtilities::gdalbuildvrt, vrt_args)

  ## Translate VRT -> MBTiles
  co <- paste0("TILE_FORMAT=", toupper(format))
  if (!is.null(zoom_level)) {
    co <- c(co, paste0("ZOOM_LEVEL=", as.integer(zoom_level)))
  }

  message("Converting VRT to MBTiles (format: ", format, ")...")
  gdalUtilities::gdal_translate(
    src_dataset = vrt,
    dst_dataset = mbtiles,
    of          = "MBTiles",
    co          = co
  )

  ## Build zoom-level overviews inside MBTiles
  if (overviews) {
    message("Building overviews (zoom pyramid)...")
    ov_levels <- as.character(2^(1:11))  # "2" "4" "8" ... "2048"
    sf::gdal_utils(
      util    = "addo",
      source  = mbtiles,
      options = c("-r", "average", ov_levels)
    )
  }

  message("Done! MBTiles written to: ", mbtiles)
  invisible(mbtiles)
}

