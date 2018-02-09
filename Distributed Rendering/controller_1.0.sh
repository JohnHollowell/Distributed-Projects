#!/bin/bash
echo "controller started" > ./Logs/controller_log.txt

hostGroup="koala"
hostMaxNum=22

echoAndLog (){
	echo $1
	echo $1 >> ./Logs/controller_log.txt
}

#TODO incorporate python file to automatically get the number of frames from the scene.
#  ~/Software/blender-2.79-linux-glibc219-x86_64/2.79/scripts/modules/blend_render_info.py


#Argument Check
if [ "$1" = "help" ] || [ "$#" -lt 2 ]; then
	echo "Usage:"
	echo "$0 <numMachines> <blendfile> [arguments] [pre-command] [post-command] [-s startframe] [-e endframe]"
	echo

else
	#pre-command
	if [ "$5" != "" ]; then
		sh "$5"
	fi

	#Clear old logs
	rm -f Logs/*

	#Check to make sure there are enough host to meet the request
	if [[ $1 -gt $hostMaxNum ]]; then
			echoAndLog "Host group \"$hostGroup\" only has $hostMaxNum hosts. $1 hosts requested."
			exit 1
	fi

	#if frames are given, use that instead of using the scene's data
	if [ -z $3 ]; then
		# sceneFrames=$3
		sceneFrames=100
	else
		sceneFrames=$(("~/Software/blender-2.79-linux-glibc219-x86_64/2.79/blender -b -P ./Utilities/getFrames.py"))
	fi

    framesPerMachine=$(($sceneFrames / $1))
    echoAndLog "$framesPerMachine frames per machine"

	#Main loop starting jobs on hosts
	for i in `seq 1 $1`;
    do
        echoAndLog "Job started on $hostGroup$i"
				logFile="./Logs/$hostGroup$(( $i ))_log.txt"
        ssh -q $hostGroup$(( $i )) "cd ~/Development/Distributed\ Rendering && ./compute.sh $((((i-1)*framesPerMachine)+1)) $((i*framesPerMachine)) $4 >> $logFile" &
        #ssh -q $hostGroup$(( $i )) "cd ~/Development/Distributed\ Rendering && echo "Established Connection. Running Command..." > $logFile && ./compute.sh $((((i-1)*framesPerMachine)+1)) $((i*framesPerMachine)) $4 >> $logFile" & > /dev/null

		#if connection to host failed, warn user
		if [ $? -ne 0 ]; then
			echoAndLog "	koala$i connection failed. Arguments were: $((((i-1)*framesPerMachine)+1)) $((i*framesPerMachine)) $4"
		fi
    done

	#post-command
	if [ "$6" != "" ]; then
		sh "$6"
	fi
fi
