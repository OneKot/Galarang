import pygltflib
import numpy as np
import io
import os
import shutil
import struct
from PIL import Image

def bake_royal_chest():
    glb_path = r'C:\Users\quant\Downloads\royal_treasure_chest.glb'
    print(f"Loading {glb_path}...")
    gltf = pygltflib.GLTF2().load(glb_path)
    blob = gltf.binary_blob()
    
    COMPONENT_TYPE_TO_DTYPE = {
        5120: np.int8,
        5121: np.uint8,
        5122: np.int16,
        5123: np.uint16,
        5125: np.uint32,
        5126: np.float32,
    }
    TYPE_TO_COUNT = {
        'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16,
    }
    
    def get_accessor_data(accessor_idx):
        acc = gltf.accessors[accessor_idx]
        bv = gltf.bufferViews[acc.bufferView]
        dtype = COMPONENT_TYPE_TO_DTYPE[acc.componentType]
        count = TYPE_TO_COUNT[acc.type]
        start = (bv.byteOffset or 0) + (acc.byteOffset or 0)
        stride = bv.byteStride
        elem_bytes = np.dtype(dtype).itemsize * count
        if stride is None or stride == elem_bytes:
            data = np.frombuffer(blob[start:start + acc.count * elem_bytes], dtype=dtype)
            if count > 1:
                data = data.reshape((acc.count, count))
            return data
        else:
            items = []
            for i in range(acc.count):
                offset = start + i * stride
                items.append(np.frombuffer(blob[offset:offset+elem_bytes], dtype=dtype))
            data = np.array(items)
            if count == 1:
                data = data.flatten()
            return data

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
        if node.translation: T[0:3, 3] = node.translation
        if node.rotation: R = quat_to_mat4(node.rotation)
        if node.scale:
            S[0, 0], S[1, 1], S[2, 2] = node.scale
        return T @ R @ S

    # 1. Build 2048x2048 Texture Atlas
    COLS = 5
    ROWS = 4
    ATLAS_W = 2048
    ATLAS_H = 2048
    TILE_W = ATLAS_W // COLS
    TILE_H = ATLAS_H // ROWS
    
    atlas = Image.new('RGBA', (ATLAS_W, ATLAS_H), (0, 0, 0, 255))
    
    # Material slot colors / textures
    # Linear to sRGB helper
    def lin2srgb(c):
        return int(max(0.0, min(1.0, c ** (1.0 / 2.2))) * 255)

    for mat_idx in range(len(gltf.materials)):
        col = mat_idx % COLS
        row = mat_idx // COLS
        x0 = col * TILE_W
        y0 = row * TILE_H
        
        m = gltf.materials[mat_idx]
        pbr = m.pbrMetallicRoughness
        tex_idx = pbr.baseColorTexture.index if pbr and pbr.baseColorTexture else None
        
        if tex_idx is not None and tex_idx < len(gltf.images):
            # Extract image from GLTF blob
            img_meta = gltf.images[tex_idx]
            bv = gltf.bufferViews[img_meta.bufferView]
            raw = blob[bv.byteOffset:bv.byteOffset+bv.byteLength]
            pil_tex = Image.open(io.BytesIO(raw)).convert('RGBA')
            pil_tex_resized = pil_tex.resize((TILE_W, TILE_H), Image.Resampling.LANCZOS)
            atlas.paste(pil_tex_resized, (x0, y0))
        else:
            # Solid color tile
            if mat_idx == 0: # slot:trim (Brass/Gold)
                tile_color = (225, 180, 55, 255)
            elif mat_idx == 1: # slot:metal (Dark iron)
                tile_color = (35, 38, 42, 255)
            elif mat_idx == 17: # royal_blue_enamel
                tile_color = (18, 52, 138, 255)
            elif mat_idx == 18: # royal_gold (Pure crown gold)
                tile_color = (255, 215, 35, 255)
            else:
                f = pbr.baseColorFactor if pbr and pbr.baseColorFactor else [0.5, 0.5, 0.5, 1.0]
                tile_color = (lin2srgb(f[0]), lin2srgb(f[1]), lin2srgb(f[2]), 255)
            
            tile = Image.new('RGBA', (TILE_W, TILE_H), tile_color)
            atlas.paste(tile, (x0, y0))
            
    atlas_out_path = 'roblox/assets/models/textures/royal_chest_atlas.png'
    os.makedirs(os.path.dirname(atlas_out_path), exist_ok=True)
    atlas.save(atlas_out_path, 'PNG')
    print(f"Saved texture atlas to {atlas_out_path} ({os.path.getsize(atlas_out_path):,} bytes)")

    # 2. Collect all nodes and primitives with atlas UVs
    def collect_nodes(node_idx, parent_mat, out_list):
        node = gltf.nodes[node_idx]
        world_mat = parent_mat @ get_node_matrix(node)
        out_list.append((node_idx, world_mat))
        if node.children:
            for c_idx in node.children:
                collect_nodes(c_idx, world_mat, out_list)

    all_nodes = []
    scene = gltf.scenes[gltf.scene or 0]
    for r_idx in scene.nodes:
        collect_nodes(r_idx, np.eye(4, dtype=np.float32), all_nodes)
        
    print(f"Total collected nodes: {len(all_nodes)}")

    vertex_list = []
    faces = []
    unique_verts = {}

    for node_idx, world_mat in all_nodes:
        node = gltf.nodes[node_idx]
        if node.mesh is None:
            continue
        mesh = gltf.meshes[node.mesh]
        norm_mat = np.linalg.inv(world_mat[:3, :3]).T

        for prim in mesh.primitives:
            mat_idx = prim.material if prim.material is not None else 0
            col = mat_idx % COLS
            row = mat_idx // COLS

            pos_data = get_accessor_data(prim.attributes.POSITION)
            norm_data = get_accessor_data(prim.attributes.NORMAL) if hasattr(prim.attributes, 'NORMAL') and prim.attributes.NORMAL is not None else None
            uv_data = get_accessor_data(prim.attributes.TEXCOORD_0) if hasattr(prim.attributes, 'TEXCOORD_0') and prim.attributes.TEXCOORD_0 is not None else None

            # Transform positions
            pos_h = np.hstack([pos_data, np.ones((len(pos_data), 1), dtype=np.float32)])
            world_pos = (world_mat @ pos_h.T).T[:, :3]

            # Transform normals
            if norm_data is not None:
                world_norms = (norm_mat @ norm_data.T).T
                lens = np.linalg.norm(world_norms, axis=1, keepdims=True)
                lens[lens == 0] = 1.0
                world_norms = world_norms / lens
            else:
                world_norms = np.zeros_like(world_pos)
                world_norms[:, 1] = 1.0

            # Remap UVs to atlas
            if uv_data is not None:
                u_orig = uv_data[:, 0]
                v_orig = uv_data[:, 1]
                u_norm = np.clip(u_orig % 1.0, 0.0, 1.0)
                v_norm = np.clip(v_orig % 1.0, 0.0, 1.0)
                atlas_u = (col + u_norm) / float(COLS)
                atlas_v = (ROWS - 1 - row + v_norm) / float(ROWS)
            else:
                # Center of tile
                atlas_u = np.full(len(world_pos), (col + 0.5) / float(COLS), dtype=np.float32)
                atlas_v = np.full(len(world_pos), (ROWS - 1 - row + 0.5) / float(ROWS), dtype=np.float32)

            indices = get_accessor_data(prim.indices) if prim.indices is not None else np.arange(len(world_pos))
            prim_vert_indices = []

            for i in range(len(world_pos)):
                p = world_pos[i]
                n = world_norms[i]
                u = atlas_u[i]
                v = atlas_v[i]

                # Key with precision rounding
                key = (round(float(p[0]), 4), round(float(p[1]), 4), round(float(p[2]), 4),
                       round(float(n[0]), 2), round(float(n[1]), 2), round(float(n[2]), 2),
                       round(float(u), 4), round(float(v), 4))

                if key not in unique_verts:
                    unique_verts[key] = len(vertex_list)
                    vertex_list.append((p, n, (u, v)))
                prim_vert_indices.append(unique_verts[key])

            # Triangles
            for i in range(0, len(indices), 3):
                if i + 2 < len(indices):
                    faces.append((
                        prim_vert_indices[indices[i]],
                        prim_vert_indices[indices[i+1]],
                        prim_vert_indices[indices[i+2]]
                    ))

    print(f"Total Vertices: {len(vertex_list):,}, Faces: {len(faces):,}")

    # Write Roblox mesh v2.00
    mesh_out_path = 'roblox/assets/models/royal_treasure_chest.mesh'
    with open(mesh_out_path, 'wb') as f:
        f.write(b"version 2.00\n")
        header = struct.pack('<HBBII', 12, 36, 12, len(vertex_list), len(faces))
        f.write(header)
        for pos, norm, uv in vertex_list:
            f.write(struct.pack('<fffffffff',
                float(pos[0]), float(pos[1]), float(pos[2]),
                float(norm[0]), float(norm[1]), float(norm[2]),
                float(uv[0]), float(1.0 - uv[1]), 0.0
            ))
        for i0, i1, i2 in faces:
            f.write(struct.pack('<III', i0, i1, i2))

    print(f"Exported Roblox mesh to {mesh_out_path} ({os.path.getsize(mesh_out_path):,} bytes)")

    # 3. Deploy directly to Roblox Studio installation
    studio_models_dir = r"C:\Users\quant\AppData\Local\Roblox\Versions\version-63eb6055af4e4688\content\models\galarang"
    studio_textures_dir = r"C:\Users\quant\AppData\Local\Roblox\Versions\version-63eb6055af4e4688\content\textures\galarang"
    os.makedirs(studio_models_dir, exist_ok=True)
    os.makedirs(studio_textures_dir, exist_ok=True)

    dest_mesh = os.path.join(studio_models_dir, 'royal_treasure_chest.mesh')
    dest_tex = os.path.join(studio_textures_dir, 'royal_chest_atlas.png')

    shutil.copy(mesh_out_path, dest_mesh)
    shutil.copy(atlas_out_path, dest_tex)
    print(f"Successfully deployed to Studio:")
    print(f"  Mesh:    {dest_mesh}")
    print(f"  Texture: {dest_tex}")

if __name__ == '__main__':
    bake_royal_chest()
