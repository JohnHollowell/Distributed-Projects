#!/bin/bash

#===Settings===#
#The location of the completion log
completionLog="Logs/jobscompleted.txt"

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

usage(){
	echo "Usage: compute.sh <blend file> <start frame> <end frame> [render name] [additional arguments]"
}

# Init dynamic variables
host=$(hostname)
blendFilename="$(basename $1)"


# Do Directory Replacements
outputDir="${outputDir/filename/"${blendFilename%.*}"}" #In $outputDir, replace "filename" with $blendFilename (without the extension)

renderNumber=1
while [[ -d "${outputDir/rendername/"render$renderNumber"}" ]]; do
	renderNumber=$((renderNumber + 1))
done
outputDir="${outputDir/rendername/"render$renderNumber"}" #replace "rendername" with the next highest


# Do filename Replacements
outputFilename="${outputFilename/filename/"${blendFilename%.*}"}" #In $outputFormat, replace "filename" with $blendFilename (without the extension)

outputFullPath="${outputDir}${outputFilename}"

echo "$outputDir" # DEV
echo "$outputFilename" # DEV
echo "$outputFullPath" # DEV

# see https://docs.blender.org/manual/en/dev/advanced/command_line/arguments.html
eval "${blenderLoc} --background ${1} --render-output ${outputFullPath} --render-format ${fileFormat} --use-extension 1 --frame-start $2 --frame-end $3 --engine ${engine} --threads ${threadCount} ${4} -a"

echo "$host	completed render of frames $2-$3" >> "${completionLog}"

#FFmpeg compile script call
if [ 0 -gt 1 ]; then
	framerate=60

	numPounds=${#${var//[^#]}}
	ffmpegFormattedFilename=${$(echo "$outputFilename" | tr -s '#')/"#"/"%0${numPounds}d"}
	$( Utilities/ffmpeg_compileFrames.sh ${outputDir} ${ffmpegFormattedFilename} ${framerate} )
fi
