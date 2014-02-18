# Image optimization script

Optimizes JPEG and PNG images for use in web projects

Optimization can be either lossless only (`optipng` and `pngout` for PNG, `jpegtran` for JPEG) or additionally lossy.
PNG images will be processed by `pngquant` for lossy optimizations, JPEG images will be converted with imagemagick's `convert` and reducing quality.

Be sure to have these tools installed and available at your path

Be sure to use a recent version of `pngquant` (>= 2.0).

This script is written for bash. Not tested in any other shells.

`jpegtran` can be installed via `apt-get` on debian-based systems or zou can look [here](http://jpegclub.org/jpegtran/)

`optipng` can be installed via `apt-get` on debian-based systems or you can look [here](http://optipng.sourceforge.net/)

`pngout` is available for Linux for download [here](http://www.jonof.id.au/kenutils)

A recent version of `pngquant` is available on github: [pngquant](https://github.com/pornel/pngquant)

To get `convert` you need the ImageMagick tools installed. Use `apt-get` on your debian box or search [here](http://www.imagemagick.org/)

## Installation

Copy the shell script somewhere in your `PATH`

## Usage

See `optimize-image -h` for help

~~~

Usage: $0 [OPTIONS] infile
Available options:
-o FILE   Sepcify outfile. If not set the infile will be overwritten (see --force)
-l        Enable lossy optimizations
-f        Force overwriting existing file (If no outfile is given and --lossy is set)
-s        Single lossless. Just run pngout, don't run optipng (affects PNG only)
-v        Be verbose
-h        Show this help

~~~