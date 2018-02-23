#!/bin/bash

#===Settings===#
#The location of the blender executable
blenderLoc="~/Software/blender-2.79/blender"

#The render Engine to use  <BLENDER_RENDER|BLENDER_GAME|CYCLES>
engine="BLENDER_RENDER"

#Number of threads to use (0 for all)
threadCount=0

#Allow embeded Python to auto-execute <disable|enable>
allowPython="disable"

#===OUTPUT===#
# "filename" will be replaced with the name of the blend file; "rendername" will be replaced with the "render" and the render iteration number; "#" indicates a digit of the frame number

#The directory where output will be placed
outputDir="Renders/filename/rendername/"

#The filename of the output files; The file extension is handled by Blender (see option below)
outputFilename="####"

#Rendered file format <TGA|RAWTGA|JPEG|IRIS|IRIZ|AVIRAW|AVIJPEG|PNG|BMP>
fileFormat="PNG"

#the file extension of the file created by Blender. Automatically set from fileFormat
fileExtension=""

usage(){
	echo "Usage: compute.sh <-b blendfile> <-s startframe> <-e endframe> [OPTIONS]..."
	echo
	echo "  -b, -blend	the location of the blend file to render"
	echo "  -comp		boolean of whether the frames should be compiled into a video automatically after rendering"
	echo "  		(requires FFmpeg to compile frames)"
	echo "  -s, -start	the frame start rendering from"
	echo "  -e, -end	the frame to render to"
	echo "  -a, -args 	quote enclosed additional arguments to pass to blender"
	echo "  -h, -help	display this help and exit"
	exit 0
}

blendFile=""
startFrame=-1
endFrame=-1
blenderArgs=""


#Injest commandline arguments
while [ $# -gt 0 ]; do
	case "$1" in
		-h|-help)
			usage
			;;

		-b|-blend)
			shift
			blendFile="$1"
			shift
			;;

		-a|-arg*)
			shift
			blenderArgs="$1"
			shift
			;;

		-s|-start*)
			shift
			startFrame=$1
			startDefined=1
			shift
			;;

		-e|-end*)
			shift
			endFrame=$1
			shift
			endDefined=1
			;;

		-comp)
			shift
			compileFrames=$1
			shift
			;;

		*)
			break
			;;

	esac
done

#check for all required arguments
if [ -z "${blendFile}" ] || [ $startFrame -lt 0 ] || [ $endFrame -lt 0 ] ; then
	usage
fi


# Init dynamic variables
host=$(hostname)
hostNum=$( echo "$host" | sed 's/[^0-9]//g')
blendFilename="$(basename "$blendFile")"

# Do Directory Replacements
outputDir="${outputDir/filename/"${blendFilename%.*}"}" #In $outputDir, replace "filename" with $blendFilename (without the extension)

#Set the render directory to the next highest availible directory
renderNumber=1
while [[ -d "${outputDir/rendername/"render$renderNumber"}" ]]; do
	renderNumber=$((renderNumber + 1))
done
outputDir="${outputDir/rendername/"render$renderNumber"}" #replace "rendername" with the next highest


# Do filename Replacements
outputFilename="${outputFilename/filename/"${blendFilename%.*}"}" #In $outputFormat, replace "filename" with $blendFilename (without the extension)
outputFullPath="${outputDir}${outputFilename}"

echo "$outputFullPath"
echo ""

#only write ffmpeg needed values if this is the first host
if [ $hostNum -eq 1 ];then
	case "$fileFormat" in
		*TGA)
			fileExtension="tga"
			;;

		JPEG)
			fileExtension="jpg"
			;;

		IRIS)
			fileExtension="rgb"
			;;

		PNG)
			fileExtension="png"
			;;

		BMP)
			fileExtension="bmp"
			;;

		AVI*)
			fileExtension="avi"
			;;

	esac

	#export variables necessary for ffmpeg compiling
	outputFilename_justPounds="${outputFilename//[^#]}"
	numPounds="${#outputFilename_justPounds}"
	outputFilename_onePound=$( echo "$outputFilename" | tr -s '#' )
	ffmpegFormattedFilename="${outputFilename_onePound/"#"/"%0${numPounds}d.$fileExtension"}"

	echo -e "${outputDir}\n${ffmpegFormattedFilename}" > "Logs/ffmpegComponents.txt"

fi


# see https://docs.blender.org/manual/en/dev/advanced/command_line/arguments.html
eval "${blenderLoc} --background \"${blendFile}\" --render-output \"${outputFullPath}\" --render-format ${fileFormat} --use-extension 1 --frame-start $startFrame --frame-end $endFrame --threads ${threadCount} ${blenderArgs} -a"
#eval "${blenderLoc} --background \"${blendFile}\" --render-output \"${outputFullPath}\" --render-format ${fileFormat} --use-extension 1 --frame-start $startFrame --frame-end $endFrame --engine ${engine} --threads ${threadCount} ${blenderArgs} -a"
