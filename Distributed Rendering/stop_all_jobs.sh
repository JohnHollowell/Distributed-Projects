
hostGroup="koala"
hostMaxNum=22


for i in `seq 1 $hostMaxNum`; do
	ssh -q $hostGroup$(( $i )) "killall -u hollowe> /dev/null"  2> /dev/null
done

echo "Forced all jobs to exit"
