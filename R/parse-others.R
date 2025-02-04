# Some datasets need custom processing


#' Parse a custom file from d20190527_GOULDEN
#'
#' @param path Data directory path, character
#' @return A \code{data.frame} containing extracted data.
#' @importFrom utils read.csv
#' @keywords internal
parse_d20190527_GOULDEN <- function(path) {
  files <- list.files(path, pattern = ".csv$", full.names = TRUE, recursive = TRUE)
  # File has header lines, and records time as fractional days since noon on 2001-01-01
  dat <- do.call("rbind", lapply(files, read.csv,
                                 skip = 14,
                                 na.strings = c("NA", "-999"),
                                 stringsAsFactors = FALSE,
                                 check.names = FALSE))
  dat$Timestamp <- as.POSIXct("2001-01-01 12:00", format = "%Y-%m-%d %H:%M")  + dat$Day_of_study * 24 * 60 * 60
  dat$Timestamp <- as.character(dat$Timestamp)
  dat$CSR_ERROR <- FALSE
  dat[dat$Vegetation == "forest",]
}


#' Parse a custom file from d20190504_SAVAGE_hf006-05
#'
#' @param path Data directory path, character
#' @return A \code{data.frame} containing extracted data.
#' @importFrom utils read.csv
#' @keywords internal
`parse_d20190504_SAVAGE_hf006-05` <- function(path) {
  dat <- parse_PROCESSED_CSV(path)

  dat_control <- dat[dat$treatment == "C",]
  dat_control$CSR_T10 <- dat_control$soilt.c
  dat_control$CSR_SM10 <- dat_control$vsm.c
  dat_trench <- dat[dat$treatment != "C",]
  dat_trench$CSR_T10 <- dat_trench$soilt.t
  dat_trench$CSR_SM10 <- dat_trench$vsm.t

  rbind_list(list(dat_control, dat_trench))
}


#' Parse a custom file from d20190504_SAVAGE_hf006-03.
#'
#' @param path Data directory path, character
#' @return A \code{data.frame} containing extracted data.
#' @importFrom utils read.csv
#' @keywords internal
`parse_d20190504_SAVAGE_hf006-03` <- function(path) {
  dat <- parse_PROCESSED_CSV(path)

  # Temperature and soil moisture data
  names(dat) <- gsub("^temp\\.ll", "CSR_T0", names(dat))
  names(dat) <- gsub("^temp", "CSR_T", names(dat))
  names(dat) <- gsub("^mois", "CSR_SM", names(dat))

  # Flux fields
  fluxcols <- grep("^flux", names(dat))
  x <- dat[-fluxcols]
  results <- list()
  for(i in seq_along(fluxcols)) {
    results[[i]] <- x
    results[[i]]$flux <- dat[,fluxcols[i]]
    results[[i]]$CSR_PORT <- i
  }

  rbind_list(results)
}


#' Parse a custom eofFD (forced diffusion) file from d20190430_DESAI
#'
#' @param path Data directory path, character
#' @return A \code{data.frame} containing extracted data.
#' @importFrom utils read.csv
#' @keywords internal
parse_d20190430_DESAI <- function(path) {
  dat <- parse_PROCESSED_CSV(path)

  results <- list()
  for(p in 1:4) {   # four separate ports in the file
    p_chr <- paste0("P", p)
    x <- dat[c("Time.UTC")]
    x$CSR_FLUX <- dat[,paste0("QCCombo.Flux.", p_chr)]
    x$CSR_ERROR <- x$CSR_FLUX > 50  # ad hoc
    x$CSR_PORT <- p

    # Extract port-specific temperature at various depths...
    temps <- grep(paste0("^Ts.*", p_chr), names(dat))
    x <- cbind(x, dat[temps])
    names(x) <- gsub(paste0("Ts\\.", p_chr, "\\."), "CSR_T", names(x))

    # ...and moisture
    sm <- grep(paste0("^VWC.*", p_chr), names(dat))
    x <- cbind(x, dat[sm])
    names(x) <- gsub(paste0("VWC\\.", p_chr, "\\."), "CSR_SM", names(x))

    results[[p_chr]] <- x
  }

  rbind_list(results)
}
