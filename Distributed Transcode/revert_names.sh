transcodingExtension=".transcoding"

for f in videos/*$transcodingExtension; do
	mv "$f" "videos/$(basename "$f" $transcodingExtension)"
done
