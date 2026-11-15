import pygltflib

gltf = pygltflib.GLTF2().load('roblox/assets/models/royal_treasure_chest.glb')
scenes = gltf.scenes
root_nodes = scenes[0].nodes if scenes else []
print('Root nodes count:', len(root_nodes))
for idx in root_nodes:
    node = gltf.nodes[idx]
    children_count = len(node.children) if node.children else 0
    print(f'Root Node {idx}: "{node.name}", children: {children_count}')

# Categorize nodes
categories = {}
for node in gltf.nodes:
    name = node.name or 'unnamed'
    prefix = name.split('.')[0].split('_')[0]
    categories[prefix] = categories.get(prefix, 0) + 1

print('Top node prefixes:', sorted(categories.items(), key=lambda x: x[1], reverse=True)[:15])
