#!/bin/bash

usage(){
	echo "Usage: ffmpeg_compileFrames.sh <frame directory> <file format> <framerate>"
}

cd "$1"
dirName=$(basename "$1")

echo pwd

ffmpeg -hide_banner -i $2 -framerate $3 ${dirName}.mp4
