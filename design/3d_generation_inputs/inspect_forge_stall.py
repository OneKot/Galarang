import pygltflib

for name in ['blacksmith_forge_diorama.glb', 'merchant_trade_stall.glb']:
    gltf = pygltflib.GLTF2().load(f'roblox/assets/models/{name}')
    print(f"=== {name} ===")
    print(f"Materials: {len(gltf.materials)}, Images: {len(gltf.images)}")
    mats_sample = [m.name for m in gltf.materials[:8]]
    print(f"Sample materials: {mats_sample}")
