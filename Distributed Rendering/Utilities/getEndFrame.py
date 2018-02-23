'''  Python 3
getEndFrame (Blender Utility)
By: John Hollowell
1/31/2018

Function:
	This program is run by Blender and is used to get the end frame from a blend file.

'''

import os, sys, bpy

#put the output in the same directory as this script
outputFile = os.path.dirname(os.path.abspath(__file__)) + "/endFrame.txt"
scene = bpy.context.scene

f = open(outputFile, 'w')
f.write(str(scene.frame_end))
f.close()

#print("End Frame from File: " + str(scene.frame_end))
