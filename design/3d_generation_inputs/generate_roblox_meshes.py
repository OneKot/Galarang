import struct
import numpy as np
import os
from obj_to_roblox_mesh import read_obj, write_roblox_mesh

roblox_models_dir = r"C:\Users\quant\AppData\Local\Roblox\Versions\version-63eb6055af4e4688\content\models\galarang"
os.makedirs(roblox_models_dir, exist_ok=True)

# 1. Base
base_obj = 'roblox/assets/models/royal_chest_base_clean.obj'
print(f"Reading {base_obj}...")
base_v, base_f = read_obj(base_obj)
base_mesh_out = os.path.join(roblox_models_dir, 'royal_chest_base.mesh')
write_roblox_mesh(base_v, base_f, base_mesh_out)

# 2. Lid
lid_obj = 'roblox/assets/models/royal_chest_lid_clean.obj'
print(f"Reading {lid_obj}...")
lid_v, lid_f = read_obj(lid_obj)
lid_mesh_out = os.path.join(roblox_models_dir, 'royal_chest_lid.mesh')
write_roblox_mesh(lid_v, lid_f, lid_mesh_out)

# Also copy to roblox/assets/models/
write_roblox_mesh(base_v, base_f, 'roblox/assets/models/royal_chest_base.mesh')
write_roblox_mesh(lid_v, lid_f, 'roblox/assets/models/royal_chest_lid.mesh')

print("Successfully generated Roblox .mesh files!")
