import pygltflib

gltf = pygltflib.GLTF2().load('roblox/assets/models/royal_pavilion_tent.glb')
print(f"Tent Materials ({len(gltf.materials)}):")
for i, m in enumerate(gltf.materials):
    pbr = m.pbrMetallicRoughness
    col = pbr.baseColorFactor if pbr else None
    print(f"  {i}: '{m.name}' -> color={col}, metallic={pbr.metallicFactor if pbr else None}, roughness={pbr.roughnessFactor if pbr else None}")
