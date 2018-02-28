for f in videos/*.MP4; do
	mv "$f" "${f/.MP4/.mp4}"
done
