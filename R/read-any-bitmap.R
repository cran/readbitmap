# Functions to identify and read a variety of bitmap image formats.
###############################################################################

#' Identify the type of an image using the magic value at the start of the file
#'
#' Currently works for png, jpeg, BMP, and tiff images. Will seek to start of
#' file if passed a connection. For details of magic values for files, see e.g.
#' \url{http://en.wikipedia.org/wiki/Magic_number_(programming)#Magic_numbers_in_files}
#' @param source Path to file or connection
#' @param Verbose Whether to write a message to console on failure (Default
#'   \code{FALSE})
#' @return character value corresponding to standard file extension of image
#'   format (i.e. jpg, png, bmp, tif) or \code{NA_character_} on failure.
#' @export
#' @examples
#' jpegfile=system.file("img", "Rlogo.jpg", package="jpeg")
#' image_type(jpegfile)
#' jpeg_pretending_to_be_png=tempfile(fileext = '.png')
#' file.copy(jpegfile, jpeg_pretending_to_be_png)
#' image_type(jpeg_pretending_to_be_png)
#' unlink(jpeg_pretending_to_be_png)
image_type<-function(source,Verbose=FALSE){
  if (inherits(source, "connection")) 
    seek(source, 0)
  magic = readBin(source, what = 0L, n = 8, size = 1L, signed = FALSE)
  if(isTRUE(all.equal(magic[1:2], c(66, 77))))
    return('bmp')
  else if(isTRUE(all.equal(magic[1:8], 
          c(0x89,0x50,0x4E,0x47,0x0D, 0x0A, 0x1A, 0x0A))) )
    return('png')
  else if(isTRUE(all.equal(magic[1:2], c(0xFF, 0xD8))))
    return('jpg')
  else if(isTRUE(all.equal(magic[1:4], c(0x49, 0x49, 0x2A, 0x00))))
    return('tif')
  else if(isTRUE(all.equal(magic[1:4], c(0x4D, 0x4D, 0x00, 0x2A))))
    return('tif')  # otherwise we failed to identify the file
  if(Verbose) warning("Failed to identify image type of: ",source,
        ' with magic: ',format.hexmode(as.raw(magic)))
  return(NA_character_)
}

#' Read in a bitmap image in JPEG, PNG, BMP or TIFF format
#'
#' By default uses magic bytes at the start of the file to identify the image
#' type (rather than the file extension). Currently uses readers in bmp, jpeg,
#' png, and tiff packages.
#' @param f Path to image file
#' @param channel Integer identifying channel to return for an RGB image
#' @param IdentifyByExtension Identify by file extension only (Default FALSE)
#' @param ... Additional parameters passed to underlying image readers
#' @return Objects returned by \code{\link[jpeg]{readJPEG}},
#'   \code{\link[png]{readPNG}}, \code{\link[bmp]{read.bmp}}, or
#'   \code{\link[tiff]{readTIFF}}. See their documentation for details.
#' @importFrom png readPNG
#' @importFrom jpeg readJPEG
#' @importFrom bmp read.bmp
#' @importFrom tiff readTIFF
#' @export
#' @seealso \code{\link{image_type}}, \code{\link[jpeg]{readJPEG}},
#'   \code{\link[png]{readPNG}}, \code{\link[bmp]{read.bmp}},
#'   \code{\link[tiff]{readTIFF}}
#' @examples
#' img1=read.bitmap(system.file("img", "Rlogo.jpg", package="jpeg"))
#' str(img1)
#' img2 <- read.bitmap(system.file("img", "Rlogo.png", package="png"))
#' # nb the PNG image has an alpha channel
#' str(img2)
read.bitmap<-function(f,channel,IdentifyByExtension=FALSE,...){
  
  if(!file.exists(f)) stop("File: ",f," does not exist.")
  
  if(IdentifyByExtension) 
    ext=tolower(sub(".*\\.([^.]+)$","\\1",f))
  else
    ext=image_type(f)
  
  readfun=switch(ext,png=readPNG,jpeg=readJPEG,jpg=readJPEG,bmp=read.bmp,
                 tif=readTIFF,tiff=readTIFF,
                 stop("File f: ",f," does not appear to be a PNG, BMP, JPEG, or TIFF"))
  im=readfun(f,...)
  
  if(!missing(channel) && length(dim(im))==3) im=im[,,channel]
  #BMP stores the alpha channel first (ARGB order), convert to RGBA for consistency with PNG files
  if (ext=="bmp" && (length(dim(im))==3) && dim(im)[3] == 4)
  {
    att <- attributes(im)
    im <- array(c(im[,,2:4],im[,,1]),dim(im))
    attributes(im) <- att
  }
  im
}
