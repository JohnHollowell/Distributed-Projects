'''  Python 3
getStartFrame (Blender Utility)
By: John Hollowell
1/31/2018

Function:
	This program is run by Blender and is used to get the start frame from a blend file.

'''

import sys, bpy

outputFile = "startFrame.txt"
scene = bpy.context.scene

f = open(outputFile, 'w')
f.write(scene.frame_start)
f.close()

print(scene.frame_start)
