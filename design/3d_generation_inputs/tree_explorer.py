import pygltflib

gltf = pygltflib.GLTF2().load('roblox/assets/models/royal_treasure_chest.glb')

def print_tree(node_idx, indent=0):
    node = gltf.nodes[node_idx]
    mesh_info = f", mesh={node.mesh}" if node.mesh is not None else ""
    print("  " * indent + f"Node {node_idx}: '{node.name}'{mesh_info}")
    if node.children:
        if len(node.children) > 10:
            print("  " * (indent + 1) + f"[{len(node.children)} children: sample {node.children[:5]}]")
            for c in node.children[:5]:
                print_tree(c, indent + 2)
        else:
            for c in node.children:
                print_tree(c, indent + 1)

print_tree(2148)
