#!/bin/bash
echo "controller started" > ./Logs/controller_log.txt

hostGroup="koala"
hostMaxNum=29

blenderLoc="~/Software/blender-2.79/blender"

#variables filled by command line arguments
startFrame=0
endFrame=1
totalFrames=2
numHosts=0
blendFile=""
preCommand=""
postCommand=""
blenderArgs=""
compileFrames=0

#set to 1 if specified in arguments
startDefined=0
endDefined=0


echoAndLog (){
	echo $1
	echo $1 >> "./Logs/controller_log.txt"
}

usage(){
	echo "Usage: controller.sh <-n numHosts> <-b blendfile> [OPTIONS]..."
	echo "Distribute a blender render job across multiple hosts"
	echo
	echo "  -b, -blend	the location of the blend file to render"
	echo "  -n		the number of hosts to use to render"
	echo "  -pre		a quote enclosed command to run before the render is distributed"
	echo "  -post		a quote enclosed command to run after the render is distributed"
	echo "  -comp		boolean of whether the frames should be compiled into a video automatically after rendering"
	echo "  		(requires FFmpeg to compile frames)"
	echo "  -s, -start	the frame start rendering from"
	echo "  -e, -end	the frame to render to"
	echo "  -a, -args 	quote enclosed additional arguments to pass to blender"
	echo "  -hosts 	the prefix for the host (default is ${hostGroup})"
	echo "  -host-max	the maximum number of hosts for the group of hosts (default is ${hostMaxNum})"
	echo "  -h, -help	display this help and exit"
	exit 0
}

#Print Usage and exit if there are no arguments
if [[ $# -eq 0 ]]; then
	usage
fi

#Injest commandline arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
		-h|-help)
			usage
			;;

		-n|-num*)
			shift
			#Check to make sure there are enough host to meet the request
			if [[ $1 -gt $hostMaxNum ]]; then
				echoAndLog "Host group \"$hostGroup\" only has $hostMaxNum hosts. $1 hosts requested."
			else
				numHosts=$1
			fi
			shift
			;;

		-b|-blend*)
			shift
			blendFile="$1"
			shift
			;;

		-a|-arg*)
			shift
			blenderArgs="$1"
			shift
			;;

		-s|-start*)
			shift
			startFrame=$1
			startDefined=1
			shift
			;;

		-e|-end*)
			shift
			endFrame=$1
			shift
			endDefined=1
			;;

		-pre*)
			shift
			preCommand="$1"
			shift
			;;

		-post*)
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

		-comp*|-vid*)
			shift
			compileFrames=$1
			shift
			;;

		*)
			break
			;;

	esac
done

#Validate required Arguments
if [[ $numHosts -lt 1 ]] || [[ -z "${blendFile}" ]]; then
	echo "Number of machines and blend file must be specified (non zero/empty)"
	echo ""
	usage
fi

#Make sure blend file exists
if [[ ! -f "$blendFile" ]]; then
	echo "blend file \"$blendFile\" not found"
	echo ""
	usage
fi

#pre-command
if [[ ! -z "$preCommand" ]]; then
	$preCommand
fi


#Clear old logs
rm -f Logs/*


echo "getting render settings from blend file..."
#Get frames from blend files if not specified in arguments
if [[ $startDefined -eq 0 ]]; then
	eval "${blenderLoc} -b \"${blendFile}\" -P ./Utilities/getStartFrame.py" > /dev/null
	startFrame=$( cat ./Utilities/startFrame.txt )
fi

if [[ $endDefined -eq 0 ]]; then
	eval "${blenderLoc} -b \"${blendFile}\" -P ./Utilities/getEndFrame.py" > /dev/null
	endFrame=$( cat ./Utilities/endFrame.txt )
fi

totalFrames=$(( (endFrame-startFrame) + 1 ))
framesPerMachine=$(( $totalFrames/($numHosts) ))
lastBlock=$(( $totalFrames-($framesPerMachine*($numHosts)) ))

#output values for the user to check
echo "start:			$startFrame"
echo "end:			$endFrame"
echo "totalFrames:		$totalFrames"
echo "frames per machine:	$framesPerMachine"
echo "last machine frames:	$lastBlock"


#Main loop starting jobs on hosts
for hostNum in $( seq 1 $numHosts ); do

 	#frame range setup for each host
	#if it is the last machine, request the remainder of frames
	if [[ $hostNum -eq $numHosts ]]; then
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
	renderCommand="./compute.sh -b \"${blendFile}\" -s ${startFrame_host} -e ${endFrame_host} -a ${blenderArgs}"


	ssh -q $hostGroup$hostNum "${cdCommand} && ${renderCommand} >> $logFile" &



done


outputDir=""
while [[ -z "$outputDir" ]]; do
	if [[  -f "Logs/ffmpegComponents.txt" ]]; then
		outputDir=$( head -n 1 "Logs/ffmpegComponents.txt" )
		ffmpegFormattedFilename=$( tail -n 1 "Logs/ffmpegComponents.txt" )
		sleep .5
	fi
done

#wait for hosts to complete rendering
count=0
while [[ $count -lt ${totalFrames} ]]; do
	count=$(ls -b "$outputDir" 2>/dev/null | wc -l )
	echo -ne "${count} / ${totalFrames} Frames Rendered"'\r'
	sleep .5
done

echo "${count} / ${totalFrames} Frames Rendered"
echo "All Hosts Finished Rendering"

if [[ $compileFrames -gt 0 ]];then
	eval "${blenderLoc} -b \"${blendFile}\" -P ./Utilities/getFramerate.py" > /dev/null
	framerate=$( cat ./Utilities/framerate.txt )

	echo ""
	echo "Compiling frames into video"
	eval "Utilities/ffmpeg_compileFrames.sh \"${outputDir}\" \"${ffmpegFormattedFilename}\" ${framerate}" > /dev/null
fi

#post-command
if [[ ! -z "$postCommand" ]]; then
	$postCommand
fi
