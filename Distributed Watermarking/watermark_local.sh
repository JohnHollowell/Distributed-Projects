for f in videos/*.towatermark; do
	ffmpeg -i "$f" -i "1920x1080 Watermark.png" -c:a copy -filter_complex "[0:v][1:v] overlay=0:0" "${f/.mp4.towatermark/.mp4}"

done
