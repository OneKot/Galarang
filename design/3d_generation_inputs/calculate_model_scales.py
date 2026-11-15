import numpy as np
import os

models = [
    "wooden_knight_mannequin.obj",
    "blacksmith_forge_diorama.obj",
    "merchant_trade_stall.obj",
    "royal_pavilion_tent.obj"
]

for m in models:
    p = os.path.join("roblox/assets/models", m)
    verts = []
    with open(p, 'r', encoding='utf-8') as f:
        for line in f:
            if line.startswith('v '):
                parts = line.split()
                verts.append([float(parts[1]), float(parts[2]), float(parts[3])])
    arr = np.array(verts)
    min_b = arr.min(axis=0)
    max_b = arr.max(axis=0)
    size = max_b - min_b
    center = (min_b + max_b) / 2.0
    print(f"=== {m} ===")
    print(f"  Min:    {min_b}")
    print(f"  Max:    {max_b}")
    print(f"  Size:   Width(X)={size[0]:.2f}, Height(Y)={size[1]:.2f}, Depth(Z)={size[2]:.2f}")
    print(f"  Center: {center}")
    print()
