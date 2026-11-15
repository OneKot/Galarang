import pygltflib
from PIL import Image
import os
import io

gltf = pygltflib.GLTF2().load('roblox/assets/models/wooden_knight_mannequin.glb')
blob = gltf.binary_blob()

print(f"Knight Images: {len(gltf.images)}")
for i, img in enumerate(gltf.images):
    bv = gltf.bufferViews[img.bufferView]
    start = bv.byteOffset or 0
    end = start + bv.byteLength
    img_bytes = blob[start:end]
    im = Image.open(io.BytesIO(img_bytes))
    print(f"  Img {i}: name={img.name}, size={im.size}, format={im.format}, mode={im.mode}")
    # save texture
    out_p = f"roblox/assets/models/textures/knight_texture_{i}.png"
    im.save(out_p)
    print(f"  Saved {out_p}")

print("\nKnight Materials:")
for m in gltf.materials:
    pbr = m.pbrMetallicRoughness
    print(f"  Material: {m.name}")
    if pbr:
        print(f"    baseColorTexture: {pbr.baseColorTexture}")
        print(f"    metallicRoughnessTexture: {pbr.metallicRoughnessTexture}")
    print(f"    normalTexture: {m.normalTexture}")
