import bpy

print(bpy.app.version)

if (2, 78, 0) > bpy.app.version:
	print("using old version hooks")
	bpy.context.user_preferences.system.compute_device_type = 'CUDA'
	bpy.context.user_preferences.system.compute_device = 'CUDA_0'

else:
	print("using new version hooks")
	bpy.context.user_preferences.addons['cycles'].preferences.compute_device_type = 'CUDA'
	bpy.context.user_preferences.addons['cycles'].preferences.devices[0].use = True

print("cycles now using first GPU")
