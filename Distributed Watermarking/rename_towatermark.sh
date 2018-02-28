for f in videos/*.mp4; do
	mv "$f" "${f/.mp4/.mp4.towatermark}"
done
