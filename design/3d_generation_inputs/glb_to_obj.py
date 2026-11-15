import pygltflib
import numpy as np
import struct
import os

def quat_to_mat4(q):
    x, y, z, w = q
    return np.array([
        [1 - 2*y*y - 2*z*z, 2*x*y - 2*z*w, 2*x*z + 2*y*w, 0],
        [2*x*y + 2*z*w, 1 - 2*x*x - 2*z*z, 2*y*z - 2*x*w, 0],
        [2*x*z - 2*y*w, 2*y*z + 2*x*w, 1 - 2*x*x - 2*y*y, 0],
        [0, 0, 0, 1]
    ], dtype=np.float32)

def get_node_matrix(node):
    if node.matrix:
        return np.array(node.matrix, dtype=np.float32).reshape((4, 4)).T
    
    T = np.eye(4, dtype=np.float32)
    R = np.eye(4, dtype=np.float32)
    S = np.eye(4, dtype=np.float32)
    
    if node.translation:
        T[0:3, 3] = node.translation
    if node.rotation:
        R = quat_to_mat4(node.rotation)
    if node.scale:
        S[0, 0] = node.scale[0]
        S[1, 1] = node.scale[1]
        S[2, 2] = node.scale[2]
        
    return T @ R @ S

glb_path = 'roblox/assets/models/royal_treasure_chest.glb'
gltf = pygltflib.GLTF2().load(glb_path)
blob = gltf.binary_blob()

# Check how accessors and bufferViews are structured
print(f"Loaded GLTF: {len(gltf.meshes)} meshes, {len(gltf.accessors)} accessors")
