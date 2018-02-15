'''  Python 3
getStartFrame (Blender Utility)
By: John Hollowell
1/31/2018

Function:
	This program is run by Blender and is used to get the start frame from a blend file.

'''

import sys, bpy
import os

#put the output in the same directory as this script
outputFile = os.path.dirname(os.path.abspath(__file__)) + "/startFrame.txt"
scene = bpy.context.scene

f = open(outputFile, 'w')
f.write(str(scene.frame_start))
f.close()

#print("Start Frame from File: " + str(scene.frame_start))
