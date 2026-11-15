import struct
import numpy as np
import os

def read_obj(obj_path):
    verts = []
    uvs = []
    norms = []
    
    unique_vertices = {}
    vertex_list = []
    faces = []
    
    with open(obj_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split()
            cmd = parts[0]
            
            if cmd == 'v':
                verts.append([float(parts[1]), float(parts[2]), float(parts[3])])
            elif cmd == 'vt':
                uvs.append([float(parts[1]), float(parts[2])])
            elif cmd == 'vn':
                norms.append([float(parts[1]), float(parts[2]), float(parts[3])])
            elif cmd == 'f':
                # Triangulate face if quad or n-gon
                face_verts = []
                for p in parts[1:]:
                    vals = p.split('/')
                    v_idx = int(vals[0]) - 1
                    vt_idx = int(vals[1]) - 1 if len(vals) > 1 and vals[1] else -1
                    vn_idx = int(vals[2]) - 1 if len(vals) > 2 and vals[2] else -1
                    
                    key = (v_idx, vt_idx, vn_idx)
                    if key not in unique_vertices:
                        unique_vertices[key] = len(vertex_list)
                        pos = verts[v_idx]
                        uv = uvs[vt_idx] if vt_idx >= 0 and vt_idx < len(uvs) else [0.0, 0.0]
                        norm = norms[vn_idx] if vn_idx >= 0 and vn_idx < len(norms) else [0.0, 1.0, 0.0]
                        vertex_list.append((pos, norm, uv))
                    face_verts.append(unique_vertices[key])
                
                # Fan triangulation
                for i in range(1, len(face_verts) - 1):
                    faces.append((face_verts[0], face_verts[i], face_verts[i+1]))
                    
    return vertex_list, faces

def write_roblox_mesh(vertex_list, faces, out_mesh_path):
    n_verts = len(vertex_list)
    n_faces = len(faces)
    
    with open(out_mesh_path, 'wb') as f:
        # Header line
        f.write(b"version 2.00\n")
        # Binary header: h_size (12), sizeof_v (36), sizeof_f (12), n_verts, n_faces
        header = struct.pack('<HBBII', 12, 36, 12, n_verts, n_faces)
        f.write(header)
        
        # Vertices: 36 bytes each (px, py, pz, nx, ny, nz, u, v, rgba)
        # Note: in Roblox mesh v2, UV v is usually 1 - v or standard
        for pos, norm, uv in vertex_list:
            v_bytes = struct.pack('<fffffffff',
                pos[0], pos[1], pos[2],
                norm[0], norm[1], norm[2],
                uv[0], 1.0 - uv[1], 0.0 # 9 floats = 36 bytes! Wait, let's verify if UV is 3 floats (u, v, w) or 2 floats + 4 bytes!
            )
            f.write(v_bytes)
            
        # Faces: 12 bytes each (3 uint32 indices)
        for i0, i1, i2 in faces:
            f_bytes = struct.pack('<III', i0, i1, i2)
            f.write(f_bytes)
            
    print(f"Exported {out_mesh_path}: {n_verts} verts, {n_faces} faces, size={os.path.getsize(out_mesh_path):,} bytes")

# Let's verify CompositExtraSlot0.mesh vertex floats to check if it's 9 floats (pos 3, norm 3, uv 3)
with open(r'C:\Users\quant\AppData\Local\Roblox\Versions\version-63eb6055af4e4688\content\avatar\compositing\CompositExtraSlot0.mesh', 'rb') as f:
    f.readline()
    f.read(12)
    first_v = f.read(36)
    floats = struct.unpack('<fffffffff', first_v)
    print("CompositExtraSlot0 first vertex 9 floats:", floats)
