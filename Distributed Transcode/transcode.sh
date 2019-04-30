
hostGroup="babbage"
hostMaxNum=33
fileCount=0
hostIndex=1
fileIndex=0
transcodingExtension=".transcoding"


usage(){
	echo "Usage: transcode <from_extension> <to_extension> [ffmpeg arguments]"
	exit 1
}

if [ $# -lt 2 ]; then
	usage
fi

#reset log files
rm -f logs/*

#rename videos and put in an array
for f in videos/*$1; do
	mv "$f" "${f/$1/${1}$transcodingExtension}"
	files[$fileCount]="${f/$1/$1$transcodingExtension}"
	((fileCount++))

done

startTime=`date +%s`

#loop through all the files and give to the hosts
while [ ${fileIndex} -lt ${#files[@]} ]; do
	filename=${files[fileIndex]}
	ssh -q $hostGroup$(( $hostIndex )) "cd \"$(pwd)\" && ffmpeg -hide_banner -loglevel panic -y -i \"$filename\" $3 \"${filename/$1$transcodingExtension/$2}\" && echo \"$hostGroup$(( $hostIndex ))	Completed ${filename/$1$transcodingExtension/$2}\">| logs/$hostGroup$(( $hostIndex )).txt" &
	echo "Host: $hostGroup$(( $hostIndex ))	File Index: ${fileIndex}	   File:${files[fileIndex]}"
	((hostIndex++))
	((fileIndex++))
	if [ ${hostIndex} -gt ${hostMaxNum} ]; then
		hostIndex=1
	fi

done

echo "waiting for jobs to complete..."

#Display count of completed jobs until all completed
while [ $(( $(ls -l logs/ | wc -l) - 1)) -lt ${fileCount} ]; do
	echo -ne "$(( $(ls -l logs/ | wc -l) - 1)) / ${fileCount} Jobs Completed"'\r'
	sleep .5
done

endTime=`date +%s`

echo "All jobs completed. Time: $((endTime-startTime)) seconds"


# Print out the size difference between the start and end files
fromFiles=$(find videos/. -type f -name "*$1")
toFiles=$(find videos/. -type f -name "*$2")

#FIXME errors out with filenames/paths with spaces
fromSize=$(du -cb videos/*$transcodingExtension | tail -1 | cut -f 1)
toSize=$(du -cb videos/*$2 | tail -1 | cut -f 1)

echo -ne "Size ratio: "
echo "scale=5 ; ${fromSize} / ${toSize}" | bc


read -t 60 -n 1 -p "Remove originals [Y/n]? " response
response=${response,,}
response=${response:0:1}

#if 'y' or enter (default response)
if [ -z "$response" ] || [ "$response" == "y" ]; then
	for f in "${files[@]}"; do
		rm "$f"
	done
	echo
	echo "Removed original files"
fi

echo ""
