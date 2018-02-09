#!/bin/bash
echo "controller started" > ./Logs/controller_log.txt

hostGroup="koala"
hostMaxNum=22

startFrame=0
endFrame=1
numMachines=0
blendFile=""
preCommand=""
postCommand=""
blenderArgs=""

echoAndLog (){
	echo $1
	echo $1 >> ./Logs/controller_log.txt
}

usage(){
	echo "Usage: controller.sh <numMachines> <blendfile> [OPTION]..."
	echo "Distribute a blender render job across multiple hosts"
	echo
	echo "  -pre		a quote enclosed command to run before the render is distributed"
	echo "  -e, -end	the frame to render to"
	echo "  -s, -start	the frame start rendering from"
	echo "  -h, -help	display this help and exit"
	exit 0
}

#Print Usage ans exit if there are no arguments
if [ $# -eq 0 ]; then
	usage
fi

#Injest commandline arguments
while [ $# -gt 0 ]; do
	case "$1" in
		-h|-help|-?)
			usage $0
			exit 0
			;;

		-n|-num)
			shift
			#Check to make sure there are enough host to meet the request
			if [[ $1 -gt $hostMaxNum ]]; then
				echoAndLog "Host group \"$hostGroup\" only has $hostMaxNum hosts. $1 hosts requested."
			else
				numMachines=$1
			fi
			shift
			;;

		-b|-blend)
			shift
			blendFile="$1"
			shift
			;;

		-a|-arg*)
			shift
			blenderArgs="$1"
			shift
			;;

		-s|-start)
			shift
			startFrame=$1
			shift
			;;

		-e|-end)
			shift
			endFrame=$1
			shift
			;;

		-pre)
			shift
			preCommand="$1"
			shift
			;;

		-post)
			shift
			postCommand="$1"
			shift
			;;

		*)
			usage
			break
			;;


	esac
done





# remnants of old code
if false; then




#Argument Check
if [ "$1" = "help" ] || [ "$#" -lt 2 ]; then
	usage

else
	#pre-command
	if [ "$5" != "" ]; then
		sh "$5"
	fi

	#Clear old logs
	rm -f Logs/*



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

fi
