#!/bin/bash
echo "controller started" > ./Logs/controller_log.txt

hostGroup="koala"
hostMaxNum=22

blenderLoc="~/Software/blender-2.79/blender"
localDir="~/Development/Distributed-Projects/Distributed\ Rendering"

startFrame=0
endFrame=1
totalFrames=2
numMachines=0
blendFile=""
preCommand=""
postCommand=""
blenderArgs=""

#set to 1 if specified in arguments
startDefined=0
endDefined=0


echoAndLog (){
	echo $1
	echo $1 >> ./Logs/controller_log.txt
}

usage(){
	echo "Usage: controller.sh <-n numMachines> <-b blendfile> [OPTION]..."
	echo "Distribute a blender render job across multiple hosts"
	echo
	echo "  -pre		a quote enclosed command to run before the render is distributed"
	echo "  -post		a quote enclosed command to run after the render is distributed"
	echo "  -s, -start	the frame start rendering from"
	echo "  -e, -end	the frame to render to"
	echo "  -a, -args 	quote enclosed additional arguments to pass to blender"
	echo "  -hosts 	the prefix for the host (default is ${hostGroup})"
	echo "  -host-max	the maximum number of hosts for the group of hosts (default is ${hostMaxNum})"
	echo "  -h, -help	display this help and exit"
	exit 0
}

#Print Usage and exit if there are no arguments
if [ $# -eq 0 ]; then
	usage
fi

#Injest commandline arguments
while [ $# -gt 0 ]; do
	case "$1" in
		-h|-help)
			usage
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
			startDefined=1
			shift
			;;

		-e|-end)
			shift
			endFrame=$1
			shift
			endDefined=1
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

		-hosts)
			shift
			hostGroup="$1"
			shift
			;;

		-host-max)
			shift
			hostMaxNum="$1"
			shift
			;;


		*)
			break
			;;


	esac
done

#Validate required Arguments
if [ $numMachines -lt 1 ] && [ -f $blendFile ]; then
	echo "Number of machines and blend file must be specified"
	echo ""
	usage
fi

#pre-command
if [ ! -z "$preCommand" ]; then
	$preCommand
fi

#===Start Main functions===#

#Clear old logs
rm -f Logs/*

#Get frames from blend files if not specified
if [ $startDefined -eq 0 ]; then
	eval ${blenderLoc} -b "${blendFile} -P ./Utilities/getStartFrame.py" > /dev/null
	startFrame=$( cat ./Utilities/startFrame.txt )
fi

if [ $endDefined -eq 0 ]; then
	eval ${blenderLoc} -b "${blendFile}" -P "./Utilities/getEndFrame.py" > /dev/null
	endFrame=$( cat ./Utilities/endFrame.txt )
fi

totalFrames=$(( (endFrame-startFrame)+1 ))
framesPerMachine=$(( $totalFrames/($numMachines) ))
lastBlock=$(( $totalFrames-($framesPerMachine*($numMachines)) ))

#DEV
echo "start:			$startFrame"
echo "end:			$endFrame"
echo "totalFrames:		$totalFrames"
echo "framesPerMachine:	$framesPerMachine"
echo "last block:		$lastBlock"



#Main loop starting jobs on hosts
for hostNum in $( seq 1 $numMachines ); do

 #frame range setup for each host
	#if it is the last machine, request the remainder of frames
	if [ $hostNum -eq $numMachines ]; then
		startFrame_host=$(( (($hostNum-1)*$framesPerMachine) + $startFrame ))
		endFrame_host=$(( ($hostNum*$framesPerMachine) + $startFrame + $lastBlock - 1 ))

	#prepare frame range for this host to proccess
	else
		startFrame_host=$(( (($hostNum-1)*$framesPerMachine) + $startFrame ))
		endFrame_host=$(( ($hostNum*$framesPerMachine) + $startFrame - 1 ))

	fi

	#Host logic
	echo "$hostGroup$hostNum	rendering frames ${startFrame_host}-${endFrame_host}"

	logFile="\"$(pwd)/Logs/$hostGroup$(( $hostNum ))_log.txt\""

	#client commands
	cdCommand="cd \"$(pwd)\""
	logCommand="echo \"Rendering frames ${startFrame_host}-${endFrame_host} of ${blendFile}\" > ${logFile}"
	renderCommand="./compute.sh \"${blendFile}\" ${startFrame_host} ${endFrame_host}"


	ssh -q $hostGroup$hostNum "${cdCommand} && ${renderCommand} >> $logFile" &



done


#post-command
#TODO
