import pygltflib
from PIL import Image
import os

gltf = pygltflib.GLTF2().load('roblox/assets/models/royal_treasure_chest.glb')

print("Materials and their textures:")
for i, m in enumerate(gltf.materials):
    pbr = m.pbrMetallicRoughness
    tex = pbr.baseColorTexture if pbr else None
    tex_idx = tex.index if tex else None
    print(f"Mat {i} '{m.name}': baseColor={pbr.baseColorFactor if pbr else None}, tex_index={tex_idx}")

# Check texture dimensions
for i in range(len(gltf.images)):
    p = f"roblox/assets/models/textures/texture_{i:02d}.png"
    if os.path.exists(p):
        im = Image.open(p)
        print(f"Texture {i:02d}: {im.size}, mode={im.mode}")
