import numpy as np

def check_obj_bounds(obj_path):
    verts = []
    with open(obj_path, 'r', encoding='utf-8') as f:
        for line in f:
            if line.startswith('v '):
                parts = line.split()
                verts.append([float(parts[1]), float(parts[2]), float(parts[3])])
    arr = np.array(verts)
    min_b = arr.min(axis=0)
    max_b = arr.max(axis=0)
    size = max_b - min_b
    center = (min_b + max_b) / 2.0
    print(f"{obj_path}:")
    print(f"  Min:    {min_b}")
    print(f"  Max:    {max_b}")
    print(f"  Size:   {size} (Width={size[0]:.2f}, Height={size[1]:.2f}, Depth={size[2]:.2f})")
    print(f"  Center: {center}")

check_obj_bounds('roblox/assets/models/royal_chest_base_clean.obj')
check_obj_bounds('roblox/assets/models/royal_chest_lid_clean.obj')
