import pygltflib
import os

gltf = pygltflib.GLTF2().load('roblox/assets/models/royal_treasure_chest.glb')
os.makedirs('roblox/assets/models/textures', exist_ok=True)

blob = gltf.binary_blob()
print(f'Total images in GLB: {len(gltf.images)}')

for idx, img in enumerate(gltf.images):
    bv = gltf.bufferViews[img.bufferView]
    start = bv.byteOffset or 0
    end = start + bv.byteLength
    img_data = blob[start:end]
    
    ext = 'png' if img.mimeType == 'image/png' else 'jpg'
    filename = f'roblox/assets/models/textures/texture_{idx:02d}.{ext}'
    with open(filename, 'wb') as f:
        f.write(img_data)
    print(f'Saved {filename} ({len(img_data)} bytes)')
