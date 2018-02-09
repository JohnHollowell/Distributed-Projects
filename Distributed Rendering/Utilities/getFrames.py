'''  Python 3.6
getFrames (Blender Utility)
By: John Hollowell
1/31/2018

Function:
	This program is run by Blender and is used to export the number of frames in a scene to a text file.

'''

import sys, bpy

outputFile = "frames.txt"
scene = bpy.context.scene

frameCount = scene.frame_end - scene.frame_start + 1

f = open(outputFile, 'w')
f.write(frameCount)
f.close()

print(frameCount)
