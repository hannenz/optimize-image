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

lossy=0
force=0
verbose=0
jpeg_quality=80

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

	pngout=$(which pngout) || reqnotmet "pngout"
	optipng=$(which optipng) || reqnotmet "optipng"
	jpegtran=$(which jpegtran) || reqnotmet "jpegtran"

	if [ $lossy -eq 1 ] ; then
		pngquant=$(which pngquant) || reqnotmet "pngquant"
		pngquant_version=`$pngquant --version`
		if [[ "$pngquant_version" != 2.* ]] ; then
			echo "Your version of pngquant is too old. pngquant >= 2.x is required." >&2
			exit;
		fi
		convert=$(which convert) || reqnotmet "convert"
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
			lossy=1
			;;
		f)
			force=1
			;;
		v)
			verbose=1
			;;
		o)
			outfile=$OPTARG
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

# Check if the requirements are met
check_requirements

if [ $# -ne 1 ] ; then
	echo "Too few arguments" >&2 
	usage
	exit
fi

infile=$1
if [ -z $outfile ] ; then
	if [ $lossy -eq 1 ] && [ $force -eq 0 ] ; then
		echo "Won't overwrite input file with lossy output. Use -f to force override this behavior" >&2
		exit;
	fi
	outfile=$infile
fi

# Determine file type (jpg or png)
# Use MIME-type and if this fails guess by reading the filename's extension

mime=$(file -ib "$infile")
mime_type=${mime%%;*}

case $mime_type in
	"image/jpeg")
		opt_type="jpg"
		;;
	"image/png")
		opt_type="png"
		;;
	*)
		filename=$(basename "$infile")
		ext="${filename##*.}"
		ext="${ext,,}"
		case $ext in
			"jpg")
				;&
			"jpeg")
				opt_type="jpg"
				;;
			"png")
				opt_type="png"
				;;
			*)
				echo "No optimizations available for file $infile of type $mime_type ($ext)" >& 2
				exit
				;;
		esac
esac

[ $verbose -eq 1 ] && echo -n  "Processing $infile: "
[ $verbose -eq 1 ] && [ $lossy -eq 1 ] && echo -n  "Lossy" || echo -n "Lossless"
[ $verbose -eq 1 ] && echo " $opt_type optimization, output to ${outfile}"

case $opt_type in
	"jpg")
		tmpfile="/tmp/$(basename $0).$$.jpg"
		$jpegtran -copy none -optimize -outfile "$tmpfile" "$infile" || abort $jpegtran $?
		if [ $lossy -eq 1 ] ; then 
			$convert "$tmpfile" -quality $jpeg_quality "$outfile" || abort $convert $?
		else
			mv "$tmpfile" "$outfile" || abort $(which mv) $?
		fi
		;;

	"png")
		# Double lossless optimization with optipng and pngout
		tmpfile1="/tmp/$(basename $0).$$.optipng.png"
		$optipng -quiet -o7 -out "$tmpfile1" "$infile" || abort $optipng $?

		tmpfile2="/tmp/$(basename $0).$$.pngout.png"
		$pngout -q "${tmpfile1}" "$tmpfile2"

		if [ $lossy -eq 1 ] ; then
			# Lossy optimization with pngquant
			cat "$tmpfile2" | $pngquant --speed 1 - > "$outfile" || abort $pngquant $?
		else
			mv "$tmpfile2" "$outfile" || abort $(which mv) $?
		fi
		# Cleanup
		[ -e "$tmpfile1" ] && rm "$tmpfile1"
		[ -e "$tmpfile2" ] && rm "$tmpfile2"

		;;
esac
exit 0
