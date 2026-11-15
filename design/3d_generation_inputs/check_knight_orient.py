import numpy as np

verts = []
with open('roblox/assets/models/wooden_knight_mannequin.obj', 'r', encoding='utf-8') as f:
    for line in f:
        if line.startswith('v '):
            parts = line.split()
            verts.append([float(parts[1]), float(parts[2]), float(parts[3])])

arr = np.array(verts)
# Check points near head (Y > 0.35)
head_pts = arr[arr[:, 1] > 0.35]
print("Head points count:", len(head_pts))
print("Head min/max X:", head_pts[:, 0].min(), head_pts[:, 0].max())
print("Head min/max Z:", head_pts[:, 2].min(), head_pts[:, 2].max())

# Check points near chest (0.0 < Y < 0.3)
chest_pts = arr[(arr[:, 1] > 0.0) & (arr[:, 1] < 0.3)]
print("Chest min/max X:", chest_pts[:, 0].min(), chest_pts[:, 0].max())
print("Chest min/max Z:", chest_pts[:, 2].min(), chest_pts[:, 2].max())
