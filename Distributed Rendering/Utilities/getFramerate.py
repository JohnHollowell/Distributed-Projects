'''  Python 3
getFramerate (Blender Utility)
By: John Hollowell
1/31/2018

Function:
	This program is run by Blender and is used to get the framerate from a blend file.

'''

import os, sys, bpy

#put the output in the same directory as this script
outputFile = os.path.dirname(os.path.abspath(__file__)) + "/framerate.txt"
scene = bpy.context.scene

f = open(outputFile, 'w')
f.write(str(scene.render.fps))
f.close()
