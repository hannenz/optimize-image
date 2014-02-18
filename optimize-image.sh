#!/bin/bash
#
# Image optimization script
# Optimizes JPEG and PNG images for use in web projects
# Optimization can be either lossless only 
# (optipng and pngout for PNG, jpegtran for JPEG)
# or additionally lossy. PNG images will be processed by 
# pngquant for lossy optimizations, JPEG images will be
# converted with imagemagick convert and reducing quality.
#
# Be sure to have these tools installed and available at your
# path
#
# Be sure to use a recent version of pngquant (>= 2.0)
#
# @author Johannes Braun <j.braun@agentur-halma.de>
# @version 2014-02-18
#

LOSSY=0
FORCE=0
VERBOSE=0
JPEG_QUALITY=80

# Print usage
usage() {
	echo "Usage: $0 [OPTIONS] infile";
	echo ""
	echo "Available options:"
	echo "-o FILE   Sepcify outfile. If not set the infile will be overwritten (see --force)"
	echo "-l        Enable lossy optimizations"
	echo "-f        Force overwriting existing file (If no outfile is given and --lossy is set)"
	echo "-v        Be verbose"
	echo "-h        Show this help"
}

# Output error message 
reqnotmet(){
	echo "$1 could not be found." >&2
	echo "Requirements not met. For basic usage pngout, optipng and jpegtran are required." >&2
	echo "For lossy optimizations pngquant and imagemagick are required additionally." >&2
	exit;
}

# Check if all requirements are met
check_requirements() {
	PNGOUT=$(which pngout) || reqnotmet "pngout"
	OPTIPNG=$(which optipng) || reqnotmet "optipng"
	JPEGTRAN=$(which jpegtran) || reqnotmet "jpegtran"

	if [ $LOSSY -eq 1 ] ; then
		PNGQUANT=$(which pngquant) || reqnotmet "pngquant"
		PNGQUANT_VERSION=`${PNGQUANT} --version`
		if [[ "${PNGQUANT_VERSION}" != 2.* ]] ; then
			echo "Your version of pngquant is too old. pngquant >= 2.x is required." >&2
			exit;
		fi
		CONVERT=$(which convert) || reqnotmet "convert"
	fi
}

# Abort: Print error message to stderr and terminate execution.
abort(){
	echo "Aborting due to an internal error."
	if [ ! -z $1 ] ; then
		echo "$1 returned the error code $2" >&2
	fi
	exit 1
}

while getopts ":lfvo:" OPT ; do
	case $OPT in
		l)
			LOSSY=1
			;;
		f)
			FORCE=1
			;;
		v)
			VERBOSE=1
			;;
		o)
			OUTFILE=$OPTARG
			;;
		h)
			usage
			exit;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			usage
			exit
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			usage
			exit
			;;
	esac
done
shift $((OPTIND-1))

# 
check_requirements

if [ $# -ne 1 ] ; then
	echo "Too few arguments" >&2 
	usage
	exit
fi

INFILE=$1
if [ -z $OUTFILE ] ; then
	if [ $LOSSY -eq 1 ] && [ $FORCE -eq 0 ] ; then
		echo "Won't overwrite input file with lossy output. Use -f to force override this behavior" >&2
		exit;
	fi
	OUTFILE=$INFILE
fi

# Determine file type (jpg or png)
# Use MIME-type and if this fails guess by reading the filename's extension

MIME=$(file -ib "${INFILE}")
MIMETYPE=${MIME%%;*}

case $MIMETYPE in
	"image/jpeg")
		TYPE="jpg"
		;;
	"image/png")
		TYPE="png"
		;;
	*)
		FILENAME=$(basename "$INFILE")
		EXT="${FILENAME##*.}"
		EXT="${EXT,,}"
		case EXT in
			"jpg")
				;&
			"jpeg")
				TYPE="jpg"
				;;
			"png")
				TYPE="png"
				;;
			*)
				echo "No optimizations available for file ${INFILE} of type $MIMETYPE ($EXT)" >& 2
				exit
				;;
		esac
esac

[ $VERBOSE -eq 1 ] && echo -n  "Processing ${INFILE}: "
[ $VERBOSE -eq 1 ] && [ $LOSSY -eq 1 ] && echo -n  "Lossy" || echo -n "Lossless"
[ $VERBOSE -eq 1 ] && echo " $TYPE optimization, output to ${OUTFILE}"

case $TYPE in
	"jpg")
		TMPFILE="/tmp/$(basename $0).$$.jpg"
		$JPEGTRAN -copy none -optimize -outfile "${TMPFILE}" "${INFILE}" || abort $JPEGTRAN $?
		if [ $LOSSY -eq 1 ] ; then 
			$CONVERT "${TMPFILE}" -quality ${JPEG_QUALITY} "${OUTFILE}" || abort $CONVERT $?
		else
			mv "${TMPFILE}" "${OUTFILE}" || abort $(which mv) $?
		fi
		;;

	"png")
		TMPFILE1="/tmp/$(basename $0).$$.optipng.png"
		$OPTIPNG -quiet -o7 -out "${TMPFILE1}" "${INFILE}" || abort $OPTIPNG $?

		TMPFILE2="/tmp/$(basename $0).$$.pngout.png"
		$PNGOUT -q "${TMPFILE1}" "${TMPFILE2}"
		if [ $LOSSY -eq 1 ] ; then
			cat "${TMPFILE2}" | $PNGQUANT --speed 1 - > "${OUTFILE}" || abort $PNGQUANT_VERSION $?
		else
			mv "${TMPFILE2}" "${OUTFILE}" || abort $(which mv) $?
		fi
		;;
esac
exit 0
