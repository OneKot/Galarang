import pygltflib
import numpy as np
import os

models = [
    "blacksmith_forge_diorama.glb",
    "wooden_knight_mannequin.glb",
    "merchant_trade_stall.glb",
    "royal_pavilion_tent.glb"
]

for m in models:
    path = os.path.join("roblox/assets/models", m)
    gltf = pygltflib.GLTF2().load(path)
    blob = gltf.binary_blob()
    
    total_verts = sum(gltf.accessors[prim.attributes.POSITION].count for mesh in gltf.meshes for prim in mesh.primitives)
    print(f"=== {m} ===")
    print(f"  Meshes: {len(gltf.meshes)}, Nodes: {len(gltf.nodes)}, Materials: {len(gltf.materials)}, Images: {len(gltf.images)}, Vertices: {total_verts:,}")
    
    # Root nodes
    scene = gltf.scenes[gltf.scene or 0]
    print(f"  Root nodes: {[gltf.nodes[i].name for i in scene.nodes]}")
    
    # Check top-level or interesting node names
    named_nodes = [n.name for n in gltf.nodes if n.name]
    print(f"  Named nodes sample ({min(10, len(named_nodes))}): {named_nodes[:10]}")
    
    # Compute bounds
    min_b = [float('inf')]*3
    max_b = [float('-inf')]*3
    for mesh in gltf.meshes:
        for prim in mesh.primitives:
            acc = gltf.accessors[prim.attributes.POSITION]
            if acc.min:
                for i in range(3):
                    min_b[i] = min(min_b[i], acc.min[i])
            if acc.max:
                for i in range(3):
                    max_b[i] = max(max_b[i], acc.max[i])
    print(f"  Raw Bounds: Min={min_b}, Max={max_b}")
    size = [max_b[i] - min_b[i] for i in range(3)]
    print(f"  Raw Size: {size}")
    print()
