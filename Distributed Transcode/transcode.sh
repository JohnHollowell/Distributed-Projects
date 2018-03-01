
hostGroup="koala"
hostMaxNum=22
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

#reset log file
rm log.txt
touch log.txt

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
	ssh -q $hostGroup$(( $hostIndex )) "cd \"$(pwd)\" && ffmpeg -hide_banner -loglevel panic -y -i \"$filename\" $3 \"${filename/$1$transcodingExtension/$2}\" && echo \"$hostGroup$(( $hostIndex ))	Completed ${filename/$1$transcodingExtension/$2}\">>log.txt" &
	echo "Host: $hostGroup$(( $hostIndex ))	File Index: ${fileIndex}	   File:${files[fileIndex]}"
	((hostIndex++))
	((fileIndex++))
	if [ ${hostIndex} -gt ${hostMaxNum} ]; then
		hostIndex=1
	fi

done

echo "waiting for jobs to complete..."

#Display count of completed jobs until all completed
while [ $(wc -l < log.txt) -lt ${fileCount} ]; do
	echo -ne "$(wc -l < log.txt) / ${fileCount} Jobs Completed"'\r'
	sleep .5
done

endTime=`date +%s`

echo "All jobs completed. Time: $((endTime-startTime)) seconds"


read -t 60 -n 1 -p "Remove originals [Y/n]? " response
response=${response,,}
response=${response:0:1}

if [ -z "$response" ] || [ "$response" == "y" ]; then
	for f in "${files[@]}"; do
		rm "$f"
	done
	echo
	echo "Removed original files"
fi
