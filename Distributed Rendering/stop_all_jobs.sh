
hostGroup="koala"
hostMaxNum=22


for i in `seq 1 $hostMaxNum`; do
<<<<<<< HEAD
	ssh -q $hostGroup$(( $i )) "killall -u "$USER"> /dev/null"  2> /dev/null
=======
	ssh -q $hostGroup$(( $i )) "killall -u hollowe> /dev/null"  2> /dev/null
>>>>>>> 475b298c50695fc7aed483b080f7a721fcabf9ed
done

echo "Forced all jobs to exit"
