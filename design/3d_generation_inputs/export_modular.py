import pygltflib
import numpy as np
import os
from glb_to_obj_full import export_obj, export_mtl, get_node_matrix, gltf, blob, all_nodes

# Let's filter nodes
exterior_nodes = []
coins_nodes = []
lid_nodes = []

for node_idx, world_mat in all_nodes:
    node = gltf.nodes[node_idx]
    if node.mesh is None:
        continue
    name = (node.name or '').lower()
    
    # Is it part of lid / crown?
    is_lid = ('lid' in name) or ('strap' in name) or ('seal' in name) or ('crown' in name) or (node_idx in [2143, 2144, 2145, 2146])
    is_coin = ('coin' in name) or ('octagonal' in name)
    
    if is_lid:
        lid_nodes.append((node_idx, world_mat))
    elif is_coin:
        coins_nodes.append((node_idx, world_mat))
    else:
        exterior_nodes.append((node_idx, world_mat))

print(f"Exterior nodes: {len(exterior_nodes)}")
print(f"Coins nodes: {len(coins_nodes)}")
print(f"Lid nodes: {len(lid_nodes)}")

mtl_path = 'roblox/assets/models/royal_treasure_chest.mtl'

# 1. Clean Chest Base (Exterior Carcass)
export_obj(exterior_nodes, 'roblox/assets/models/royal_chest_base_clean.obj', mtl_path, gltf, blob)

# 2. Chest Lid
export_obj(lid_nodes, 'roblox/assets/models/royal_chest_lid_clean.obj', mtl_path, gltf, blob)

# 3. Coins Pile
export_obj(coins_nodes, 'roblox/assets/models/royal_chest_coins.obj', mtl_path, gltf, blob)
