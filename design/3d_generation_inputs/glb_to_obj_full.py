import pygltflib
import numpy as np
import os

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
        # GLTF matrices are stored column-major
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

def export_obj(nodes_to_export, output_obj_path, output_mtl_path, gltf, blob):
    v_list = []
    vn_list = []
    vt_list = []
    f_list = []
    
    v_offset = 0
    vt_offset = 0
    vn_offset = 0
    
    current_mat = None
    
    for node_idx, world_mat in nodes_to_export:
        node = gltf.nodes[node_idx]
        if node.mesh is None:
            continue
        
        mesh = gltf.meshes[node.mesh]
        normal_mat = np.linalg.inv(world_mat[:3, :3]).T
        
        for prim in mesh.primitives:
            pos_acc = prim.attributes.POSITION
            norm_acc = prim.attributes.NORMAL
            uv_acc = prim.attributes.TEXCOORD_0
            idx_acc = prim.indices
            mat_idx = prim.material
            
            # Positions
            positions = get_accessor_data(gltf, blob, pos_acc)
            # transform positions to world space
            ones = np.ones((len(positions), 1), dtype=np.float32)
            pos_h = np.hstack([positions, ones])
            world_pos = (world_mat @ pos_h.T).T[:, :3]
            
            # Normals
            if norm_acc is not None:
                normals = get_accessor_data(gltf, blob, norm_acc)
                world_normals = (normal_mat @ normals.T).T
                norms = np.linalg.norm(world_normals, axis=1, keepdims=True)
                norms[norms == 0] = 1.0
                world_normals = world_normals / norms
            else:
                world_normals = None
                
            # UVs
            if uv_acc is not None:
                uvs = get_accessor_data(gltf, blob, uv_acc).copy()
                uvs[:, 1] = 1.0 - uvs[:, 1] # Flip V for OBJ standard
            else:
                uvs = None
                
            # Indices
            if idx_acc is not None:
                indices = get_accessor_data(gltf, blob, idx_acc).astype(np.int64)
            else:
                indices = np.arange(len(positions), dtype=np.int64)
                
            # Append vertex data
            v_list.append(world_pos)
            if world_normals is not None:
                vn_list.append(world_normals)
            if uvs is not None:
                vt_list.append(uvs)
                
            mat_name = f"Material_{mat_idx}" if mat_idx is not None else "DefaultMaterial"
            
            # Format faces
            f_block = []
            has_uv = uvs is not None
            has_norm = world_normals is not None
            
            for i in range(0, len(indices), 3):
                idx0 = indices[i] + v_offset + 1
                idx1 = indices[i+1] + v_offset + 1
                idx2 = indices[i+2] + v_offset + 1
                
                if has_uv and has_norm:
                    vt0 = indices[i] + vt_offset + 1
                    vt1 = indices[i+1] + vt_offset + 1
                    vt2 = indices[i+2] + vt_offset + 1
                    vn0 = indices[i] + vn_offset + 1
                    vn1 = indices[i+1] + vn_offset + 1
                    vn2 = indices[i+2] + vn_offset + 1
                    f_block.append(f"f {idx0}/{vt0}/{vn0} {idx1}/{vt1}/{vn1} {idx2}/{vt2}/{vn2}")
                elif has_norm:
                    vn0 = indices[i] + vn_offset + 1
                    vn1 = indices[i+1] + vn_offset + 1
                    vn2 = indices[i+2] + vn_offset + 1
                    f_block.append(f"f {idx0}//{vn0} {idx1}//{vn1} {idx2}//{vn2}")
                elif has_uv:
                    vt0 = indices[i] + vt_offset + 1
                    vt1 = indices[i+1] + vt_offset + 1
                    vt2 = indices[i+2] + vt_offset + 1
                    f_block.append(f"f {idx0}/{vt0} {idx1}/{vt1} {idx2}/{vt2}")
                else:
                    f_block.append(f"f {idx0} {idx1} {idx2}")
                    
            f_list.append((mat_name, f_block))
            
            v_offset += len(positions)
            if has_uv:
                vt_offset += len(uvs)
            if has_norm:
                vn_offset += len(world_normals)

    print(f"Writing {output_obj_path} (Vertices: {v_offset:,})...")
    with open(output_obj_path, 'w', encoding='utf-8') as f:
        mtl_filename = os.path.basename(output_mtl_path)
        f.write(f"# Exported Royal Treasure Chest\nmtllib {mtl_filename}\n")
        
        # Vertices
        all_v = np.vstack(v_list)
        for v in all_v:
            f.write(f"v {v[0]:.6f} {v[1]:.6f} {v[2]:.6f}\n")
            
        # UVs
        if vt_list:
            all_vt = np.vstack(vt_list)
            for vt in all_vt:
                f.write(f"vt {vt[0]:.6f} {vt[1]:.6f}\n")
                
        # Normals
        if vn_list:
            all_vn = np.vstack(vn_list)
            for vn in all_vn:
                f.write(f"vn {vn[0]:.6f} {vn[1]:.6f} {vn[2]:.6f}\n")
                
        # Faces grouped by material
        last_mat = None
        for mat_name, faces in f_list:
            if mat_name != last_mat:
                f.write(f"usemtl {mat_name}\n")
                last_mat = mat_name
            f.write("\n".join(faces) + "\n")

    print(f"Done writing {output_obj_path} ({os.path.getsize(output_obj_path):,} bytes)")

def export_mtl(output_mtl_path, gltf):
    with open(output_mtl_path, 'w', encoding='utf-8') as f:
        f.write("# MTL file for Royal Treasure Chest\n\n")
        for idx, m in enumerate(gltf.materials):
            mat_name = f"Material_{idx}"
            f.write(f"newmtl {mat_name}\n")
            pbr = m.pbrMetallicRoughness
            if pbr:
                color = pbr.baseColorFactor or [1.0, 1.0, 1.0, 1.0]
                f.write(f"Kd {color[0]:.4f} {color[1]:.4f} {color[2]:.4f}\n")
                f.write(f"d {color[3]:.4f}\n")
                if pbr.baseColorTexture:
                    tex_idx = pbr.baseColorTexture.index
                    f.write(f"map_Kd textures/texture_{tex_idx:02d}.png\n")
            f.write("illum 2\n\n")
    print(f"Done writing {output_mtl_path}")

# Load GLTF
glb_path = 'roblox/assets/models/royal_treasure_chest.glb'
gltf = pygltflib.GLTF2().load(glb_path)
blob = gltf.binary_blob()

# Build hierarchy with world matrices
def collect_nodes(node_idx, parent_mat, out_list):
    node = gltf.nodes[node_idx]
    local_mat = get_node_matrix(node)
    world_mat = parent_mat @ local_mat
    out_list.append((node_idx, world_mat))
    if node.children:
        for child_idx in node.children:
            collect_nodes(child_idx, world_mat, out_list)

all_nodes = []
root_idx = gltf.scenes[0].nodes[0]
collect_nodes(root_idx, np.eye(4, dtype=np.float32), all_nodes)

# Carcass nodes vs Lid nodes
carcass_nodes = []
lid_nodes = []
crown_nodes = []

# Node 2065 is carcass, Node 2136 is lid_hinge, Node 2147 is royal_crown_emblem
carcass_root = 2065
lid_root = 2136
crown_root = 2147

# Find world mat for carcass_root and its children
def find_node_world(target_root, current_idx, current_mat):
    node = gltf.nodes[current_idx]
    local_mat = get_node_matrix(node)
    world_mat = current_mat @ local_mat
    if current_idx == target_root:
        res = []
        def sub_collect(n_idx, w_mat):
            n = gltf.nodes[n_idx]
            res.append((n_idx, w_mat))
            if n.children:
                for c in n.children:
                    sub_collect(c, w_mat @ get_node_matrix(gltf.nodes[c]))
        sub_collect(current_idx, world_mat)
        return res
    if node.children:
        for c in node.children:
            found = find_node_world(target_root, c, world_mat)
            if found:
                return found
    return None

carcass_nodes = find_node_world(carcass_root, root_idx, np.eye(4, dtype=np.float32)) or []
lid_nodes = find_node_world(lid_root, root_idx, np.eye(4, dtype=np.float32)) or []
crown_nodes = find_node_world(crown_root, root_idx, np.eye(4, dtype=np.float32)) or []

print(f"Total nodes: {len(all_nodes)}, Carcass nodes: {len(carcass_nodes)}, Lid nodes: {len(lid_nodes)}, Crown nodes: {len(crown_nodes)}")

# Export MTL
mtl_path = 'roblox/assets/models/royal_treasure_chest.mtl'
export_mtl(mtl_path, gltf)

# 1. Full Chest
export_obj(all_nodes, 'roblox/assets/models/royal_treasure_chest.obj', mtl_path, gltf, blob)

# 2. Base (Carcass)
if carcass_nodes:
    export_obj(carcass_nodes, 'roblox/assets/models/royal_chest_base.obj', mtl_path, gltf, blob)

# 3. Lid (Lid + Crown)
combined_lid = (lid_nodes or []) + (crown_nodes or [])
if combined_lid:
    export_obj(combined_lid, 'roblox/assets/models/royal_chest_lid.obj', mtl_path, gltf, blob)
