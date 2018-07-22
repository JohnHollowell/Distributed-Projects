
hostGroup="babbage"
hostMaxNum=33


for i in `seq 1 $hostMaxNum`; do
	ssh -q $hostGroup$(( $i )) "killall ffmpeg 2> /dev/null"  2> /dev/null
done

echo "Forced all jobs to exit"
