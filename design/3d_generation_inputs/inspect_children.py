import pygltflib

gltf = pygltflib.GLTF2().load('roblox/assets/models/royal_treasure_chest.glb')
root = gltf.nodes[2148]
print('Root children IDs:', root.children)
for ch_idx in root.children:
    ch = gltf.nodes[ch_idx]
    num_subchildren = len(ch.children) if ch.children else 0
    print(f'Child {ch_idx}: "{ch.name}", subchildren: {num_subchildren}')
