
hostGroup="koala"
hostMaxNum=29
fileCount=0
hostIndex=1
fileIndex=0

#The image to overlay on top of the video
watermarkFile="1920x1080 Watermark.png"

rm log.txt
touch log.txt

#put all videos in an array
for f in videos/*.towatermark; do
	files[$fileCount]="$f"
	((fileCount++))

done

startTime=`date +%s`

#loop through all the files and give to the hosts
while [ ${fileIndex} -lt ${#files[@]} ]; do
	filename=${files[fileIndex]}
	ssh -q $hostGroup$(( $hostIndex )) "cd \"$(pwd)\" && ffmpeg -hide_banner -loglevel panic -y -i \"$filename\" -i \"${watermarkFile}\" -c:a copy -filter_complex \"[0:v][1:v] overlay=0:0\" \"${filename/.mp4.towatermark/.mp4}\" && echo "$hostGroup$(( $hostIndex ))	Completed ${filename/.mp4.towatermark/.mp4}">>log.txt" &
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
