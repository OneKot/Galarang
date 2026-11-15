import pygltflib
import numpy as np
import struct
import os
import shutil
from PIL import Image
import io

COMPONENT_TYPE_TO_DTYPE = {
    5120: np.int8,
    5121: np.uint8,
    5122: np.int16,
    5123: np.uint16,
    5125: np.uint32,
    5126: np.float32,
}

TYPE_TO_COUNT = {
    'SCALAR': 1,
    'VEC2': 2,
    'VEC3': 3,
    'VEC4': 4,
    'MAT4': 16,
}

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
        return np.array(node.matrix, dtype=np.float32).reshape((4, 4), order='F')
    
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

def get_accessor_data(gltf, blob, accessor_idx):
    acc = gltf.accessors[accessor_idx]
    bv = gltf.bufferViews[acc.bufferView]
    dtype = COMPONENT_TYPE_TO_DTYPE[acc.componentType]
    count_per_element = TYPE_TO_COUNT[acc.type]
    
    start = (bv.byteOffset or 0) + (acc.byteOffset or 0)
    stride = bv.byteStride
    element_bytes = np.dtype(dtype).itemsize * count_per_element
    
    if stride is None or stride == element_bytes:
        total_bytes = acc.count * element_bytes
        data = np.frombuffer(blob[start:start+total_bytes], dtype=dtype)
        if count_per_element > 1:
            data = data.reshape((acc.count, count_per_element))
        return data
    else:
        items = []
        for i in range(acc.count):
            offset = start + i * stride
            item = np.frombuffer(blob[offset:offset+element_bytes], dtype=dtype)
            items.append(item)
        data = np.array(items)
        if count_per_element == 1:
            data = data.flatten()
        return data

def convert_glb_to_obj_and_mesh(glb_path, out_obj_path, out_mesh_path, out_tex_prefix=None):
    print(f"\n--- Processing {glb_path} ---")
    gltf = pygltflib.GLTF2().load(glb_path)
    blob = gltf.binary_blob()
    
    # Collect all nodes with world matrices
    def collect_nodes(node_idx, parent_mat, out_list):
        node = gltf.nodes[node_idx]
        local_mat = get_node_matrix(node)
        world_mat = parent_mat @ local_mat
        out_list.append((node_idx, world_mat))
        if node.children:
            for child_idx in node.children:
                collect_nodes(child_idx, world_mat, out_list)

    all_nodes = []
    scene = gltf.scenes[gltf.scene or 0]
    for root_idx in scene.nodes:
        collect_nodes(root_idx, np.eye(4, dtype=np.float32), all_nodes)

    v_list = []
    vn_list = []
    vt_list = []
    f_list = []
    
    v_offset = 0
    vt_offset = 0
    vn_offset = 0
    
    # Store for direct Roblox mesh output
    roblox_vertices = []
    roblox_faces = []
    
    for node_idx, world_mat in all_nodes:
        node = gltf.nodes[node_idx]
        if node.mesh is None:
            continue
        mesh = gltf.meshes[node.mesh]
        normal_mat = np.linalg.inv(world_mat[:3, :3]).T
        
        for prim in mesh.primitives:
            positions = get_accessor_data(gltf, blob, prim.attributes.POSITION)
            ones = np.ones((len(positions), 1), dtype=np.float32)
            pos_h = np.hstack([positions, ones])
            world_pos = (world_mat @ pos_h.T).T[:, :3]
            
            if prim.attributes.NORMAL is not None:
                normals = get_accessor_data(gltf, blob, prim.attributes.NORMAL)
                world_normals = (normal_mat @ normals.T).T
                norms = np.linalg.norm(world_normals, axis=1, keepdims=True)
                norms[norms == 0] = 1.0
                world_normals = world_normals / norms
            else:
                world_normals = np.zeros_like(world_pos)
                world_normals[:, 1] = 1.0
                
            if prim.attributes.TEXCOORD_0 is not None:
                uvs = get_accessor_data(gltf, blob, prim.attributes.TEXCOORD_0).copy()
            else:
                uvs = np.zeros((len(positions), 2), dtype=np.float32)
                
            if prim.indices is not None:
                indices = get_accessor_data(gltf, blob, prim.indices).astype(np.int64)
            else:
                indices = np.arange(len(positions), dtype=np.int64)
                
            # For OBJ
            v_list.append(world_pos)
            vn_list.append(world_normals)
            vt_copy = uvs.copy()
            vt_copy[:, 1] = 1.0 - vt_copy[:, 1]
            vt_list.append(vt_copy)
            
            for i in range(0, len(indices), 3):
                idx0 = indices[i] + v_offset + 1
                idx1 = indices[i+1] + v_offset + 1
                idx2 = indices[i+2] + v_offset + 1
                f_list.append(f"f {idx0}/{idx0}/{idx0} {idx1}/{idx1}/{idx1} {idx2}/{idx2}/{idx2}")
                
            # For direct Roblox mesh v2.00
            base_idx = len(roblox_vertices)
            for p, n, u in zip(world_pos, world_normals, uvs):
                roblox_vertices.append((p, n, u))
            for i in range(0, len(indices), 3):
                roblox_faces.append((indices[i] + base_idx, indices[i+1] + base_idx, indices[i+2] + base_idx))
                
            v_offset += len(positions)
            vt_offset += len(uvs)
            vn_offset += len(world_normals)

    print(f"Total vertices: {len(roblox_vertices):,}, Total faces: {len(roblox_faces):,}")
    
    # Write OBJ
    with open(out_obj_path, 'w', encoding='utf-8') as f:
        f.write(f"# Exported from {os.path.basename(glb_path)}\n")
        all_v = np.vstack(v_list)
        for v in all_v:
            f.write(f"v {v[0]:.6f} {v[1]:.6f} {v[2]:.6f}\n")
        all_vt = np.vstack(vt_list)
        for vt in all_vt:
            f.write(f"vt {vt[0]:.6f} {vt[1]:.6f}\n")
        all_vn = np.vstack(vn_list)
        for vn in all_vn:
            f.write(f"vn {vn[0]:.6f} {vn[1]:.6f} {vn[2]:.6f}\n")
        f.write("\n".join(f_list) + "\n")
    print(f"Saved OBJ: {out_obj_path} ({os.path.getsize(out_obj_path):,} bytes)")
    
    # Write Roblox mesh v2.00
    with open(out_mesh_path, 'wb') as f:
        f.write(b"version 2.00\n")
        header = struct.pack('<HBBII', 12, 36, 12, len(roblox_vertices), len(roblox_faces))
        f.write(header)
        for pos, norm, uv in roblox_vertices:
            v_bytes = struct.pack('<fffffffff',
                float(pos[0]), float(pos[1]), float(pos[2]),
                float(norm[0]), float(norm[1]), float(norm[2]),
                float(uv[0]), float(1.0 - uv[1]), 0.0
            )
            f.write(v_bytes)
        for i0, i1, i2 in roblox_faces:
            f.write(struct.pack('<III', int(i0), int(i1), int(i2)))
    print(f"Saved Roblox Mesh: {out_mesh_path} ({os.path.getsize(out_mesh_path):,} bytes)")

    # Extract images if prefix provided
    if out_tex_prefix and gltf.images:
        for idx, img in enumerate(gltf.images):
            bv = gltf.bufferViews[img.bufferView]
            start = bv.byteOffset or 0
            end = start + bv.byteLength
            img_data = blob[start:end]
            im = Image.open(io.BytesIO(img_data))
            tex_out = f"roblox/assets/models/textures/{out_tex_prefix}_{idx}.png"
            im.save(tex_out)
            print(f"  Saved texture: {tex_out}")

# Run batch conversions
roblox_models_dir = r"C:\Users\quant\AppData\Local\Roblox\Versions\version-63eb6055af4e4688\content\models\galarang"
roblox_tex_dir = r"C:\Users\quant\AppData\Local\Roblox\Versions\version-63eb6055af4e4688\content\textures\galarang"
os.makedirs(roblox_models_dir, exist_ok=True)
os.makedirs(roblox_tex_dir, exist_ok=True)
os.makedirs("roblox/assets/models/textures", exist_ok=True)

models_to_convert = [
    ("wooden_knight_mannequin.glb", "wooden_knight_mannequin.obj", "wooden_knight_mannequin.mesh", "knight"),
    ("blacksmith_forge_diorama.glb", "blacksmith_forge_diorama.obj", "blacksmith_forge_diorama.mesh", "forge"),
    ("merchant_trade_stall.glb", "merchant_trade_stall.obj", "merchant_trade_stall.mesh", "stall"),
    ("royal_pavilion_tent.glb", "royal_pavilion_tent.obj", "royal_pavilion_tent.mesh", "tent"),
]

for glb, obj, mesh, tex_prefix in models_to_convert:
    glb_p = os.path.join("roblox/assets/models", glb)
    obj_p = os.path.join("roblox/assets/models", obj)
    mesh_p = os.path.join("roblox/assets/models", mesh)
    convert_glb_to_obj_and_mesh(glb_p, obj_p, mesh_p, tex_prefix)
    
    # Deploy mesh to Roblox Studio content
    shutil.copy(mesh_p, os.path.join(roblox_models_dir, mesh))

print("\nAll models converted and deployed to Roblox content directory successfully!")
