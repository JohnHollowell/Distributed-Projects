#!/bin/bash

#===Settings===#
#the location of the blender executable
blenderLoc="~/Software/blender-2.79-linux-glibc219-x86_64/blender"

#The format of the output files ("filename" will be replaced with the name of the blend file)
outputFormat="filename_render1_####"

#The render Engine to use  <BLENDER_RENDER|BLENDER_GAME|CYCLES>
engine=BLENDER_RENDER


echo "$0 | $1 | $2 | $3" # DEV
blendFilename="$(hostname)" #DEV
outputFilename="${outputFormat/filename/$blendFilename}" #In $outputFormat, replace "filename" with $blendFilename
echo "$outputFormat" # DEV
echo "$outputFilename" # DEV


# see https://docs.blender.org/manual/en/dev/advanced/command_line/arguments.html
# ~/Software/blender-2.79-linux-glibc219-x86_64/blender -b <file.blend> -s <startframe> -e <endframe> -o <outputfile####> -E $engine -P <pythonfile>
