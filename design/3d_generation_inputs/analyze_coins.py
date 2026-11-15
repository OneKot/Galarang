import pygltflib
import numpy as np

gltf = pygltflib.GLTF2().load('roblox/assets/models/royal_treasure_chest.glb')

coin_nodes = 0
coin_verts = 0
other_nodes = 0
other_verts = 0

for node in gltf.nodes:
    if node.mesh is not None:
        mesh = gltf.meshes[node.mesh]
        v_count = sum(gltf.accessors[prim.attributes.POSITION].count for prim in mesh.primitives)
        name = node.name or ''
        if 'coin' in name.lower() or 'octagonal' in name.lower():
            coin_nodes += 1
            coin_verts += v_count
        else:
            other_nodes += 1
            other_verts += v_count

print(f"Coin parts: {coin_nodes} nodes, {coin_verts:,} vertices")
print(f"Chest structure parts: {other_nodes} nodes, {other_verts:,} vertices")
