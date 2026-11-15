import os
import sys
import shutil
import struct
import subprocess

BLENDER_EXE = r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
SCRIPT_PATH = r"roblox\assets\models\blender_bake_job.py"
TEMP_OBJ = r"roblox\assets\models\temp_royal_chest.obj"
TEXTURE_OUT = r"roblox\assets\models\textures\royal_chest_atlas.png"
MESH_OUT = r"roblox\assets\models\royal_treasure_chest.mesh"
ROBLOX_CONTENT_MODELS = r"C:\Users\quant\AppData\Local\Roblox\Versions\version-63eb6055af4e4688\content\models\galarang"
ROBLOX_CONTENT_TEXTURES = r"C:\Users\quant\AppData\Local\Roblox\Versions\version-63eb6055af4e4688\content\textures\galarang"

def obj_to_roblox_mesh(obj_path, mesh_out_path):
    print(f"Converting {obj_path} to Roblox mesh format v2.00...")
    positions = []
    texcoords = []
    normals = []
    
    unique_verts = {}
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
                positions.append((float(parts[1]), float(parts[2]), float(parts[3])))
            elif cmd == 'vt':
                texcoords.append((float(parts[1]), float(parts[2])))
            elif cmd == 'vn':
                normals.append((float(parts[1]), float(parts[2]), float(parts[3])))
            elif cmd == 'f':
                poly_indices = []
                for p in parts[1:]:
                    vals = p.split('/')
                    v_idx = int(vals[0]) - 1
                    vt_idx = int(vals[1]) - 1 if len(vals) > 1 and vals[1] else -1
                    vn_idx = int(vals[2]) - 1 if len(vals) > 2 and vals[2] else -1
                    
                    pos = positions[v_idx]
                    norm = normals[vn_idx] if vn_idx >= 0 else (0.0, 1.0, 0.0)
                    uv = texcoords[vt_idx] if vt_idx >= 0 else (0.5, 0.5)
                    
                    key = (round(pos[0], 5), round(pos[1], 5), round(pos[2], 5),
                           round(norm[0], 3), round(norm[1], 3), round(norm[2], 3),
                           round(uv[0], 5), round(uv[1], 5))
                    
                    if key not in unique_verts:
                        unique_verts[key] = len(vertex_list)
                        vertex_list.append((pos, norm, uv))
                    poly_indices.append(unique_verts[key])
                
                # Triangulate face if quad or n-gon
                for i in range(1, len(poly_indices) - 1):
                    faces.append((poly_indices[0], poly_indices[i], poly_indices[i+1]))

    print(f"Final mesh metrics: {len(vertex_list):,} vertices, {len(faces):,} faces")
    assert len(vertex_list) < 65535, f"Vertex count {len(vertex_list)} exceeds 16-bit index limit!"

    os.makedirs(os.path.dirname(mesh_out_path), exist_ok=True)
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

    print(f"Saved Roblox mesh to {mesh_out_path} ({os.path.getsize(mesh_out_path):,} bytes)")

def run_pipeline():
    print("Running Blender bake job...")
    cmd = [BLENDER_EXE, "--background", "--python", SCRIPT_PATH]
    res = subprocess.run(cmd, capture_output=True, text=True)
    print("Blender Return Code:", res.returncode)
    for line in res.stdout.splitlines():
        if "---" in line or "verts" in line or "Saved" in line or "Error" in line or "Exported" in line or "Imported" in line:
            print("  [BLENDER]", line)

    if res.returncode != 0:
        print("Blender STDERR:", res.stderr[-1000:])
        sys.exit(1)

    obj_to_roblox_mesh(TEMP_OBJ, MESH_OUT)

    # Deploy to Studio
    os.makedirs(ROBLOX_CONTENT_MODELS, exist_ok=True)
    os.makedirs(ROBLOX_CONTENT_TEXTURES, exist_ok=True)
    dest_mesh = os.path.join(ROBLOX_CONTENT_MODELS, "royal_treasure_chest.mesh")
    dest_tex = os.path.join(ROBLOX_CONTENT_TEXTURES, "royal_chest_atlas.png")
    shutil.copy(MESH_OUT, dest_mesh)
    shutil.copy(TEXTURE_OUT, dest_tex)
    print(f"Deployed to Studio:\n  {dest_mesh}\n  {dest_tex}")

if __name__ == '__main__':
    run_pipeline()
