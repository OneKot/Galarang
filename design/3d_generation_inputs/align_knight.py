import struct
import numpy as np
import shutil
import os

# Rotate knight mesh 90 deg around Y so it faces forward (-Z in Roblox)
obj_in = 'roblox/assets/models/wooden_knight_mannequin.obj'
verts = []
uvs = []
normals = []
faces = []

with open(obj_in, 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        parts = line.split()
        if parts[0] == 'v':
            x, y, z = float(parts[1]), float(parts[2]), float(parts[3])
            # Rotate 90 deg around Y: new_x = -z, new_z = x (or new_x = z, new_z = -x)
            verts.append([-z, y, x])
        elif parts[0] == 'vn':
            nx, ny, nz = float(parts[1]), float(parts[2]), float(parts[3])
            normals.append([-nz, ny, nx])
        elif parts[0] == 'vt':
            uvs.append([float(parts[1]), float(parts[2])])
        elif parts[0] == 'f':
            # f v1/vt1/vn1 v2/vt2/vn2 v3/vt3/vn3
            faces.append(line)

# Check bounds
arr = np.array(verts)
print("Aligned Knight bounds:")
print("  Min:", arr.min(axis=0))
print("  Max:", arr.max(axis=0))
print("  Size:", arr.max(axis=0) - arr.min(axis=0))

# Save aligned OBJ
with open('roblox/assets/models/wooden_knight_mannequin_aligned.obj', 'w', encoding='utf-8') as f:
    f.write("# Aligned Wooden Knight Mannequin\n")
    for v in verts:
        f.write(f"v {v[0]:.6f} {v[1]:.6f} {v[2]:.6f}\n")
    for vt in uvs:
        f.write(f"vt {vt[0]:.6f} {vt[1]:.6f}\n")
    for vn in normals:
        f.write(f"vn {vn[0]:.6f} {vn[1]:.6f} {vn[2]:.6f}\n")
    f.write("\n".join(faces) + "\n")

# Write Roblox mesh v2.00
mesh_out = 'roblox/assets/models/wooden_knight_mannequin.mesh'
n_verts = len(verts)
n_faces = len(faces)

with open(mesh_out, 'wb') as f:
    f.write(b"version 2.00\n")
    header = struct.pack('<HBBII', 12, 36, 12, n_verts, n_faces)
    f.write(header)
    for pos, norm, uv in zip(verts, normals, uvs):
        f.write(struct.pack('<fffffffff',
            float(pos[0]), float(pos[1]), float(pos[2]),
            float(norm[0]), float(norm[1]), float(norm[2]),
            float(uv[0]), float(1.0 - uv[1]), 0.0
        ))
    for f_line in faces:
        p = f_line.split()
        i0 = int(p[1].split('/')[0]) - 1
        i1 = int(p[2].split('/')[0]) - 1
        i2 = int(p[3].split('/')[0]) - 1
        f.write(struct.pack('<III', i0, i1, i2))

roblox_models_dir = r"C:\Users\quant\AppData\Local\Roblox\Versions\version-63eb6055af4e4688\content\models\galarang"
shutil.copy(mesh_out, os.path.join(roblox_models_dir, 'wooden_knight_mannequin.mesh'))
print("Successfully saved aligned wooden_knight_mannequin.mesh and deployed to Roblox!")
