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
        # Strided buffer
        items = []
        for i in range(acc.count):
            offset = start + i * stride
            item = np.frombuffer(blob[offset:offset+element_bytes], dtype=dtype)
            items.append(item)
        data = np.array(items)
        if count_per_element == 1:
            data = data.flatten()
        return data

# Test reading first accessor
gltf = pygltflib.GLTF2().load('roblox/assets/models/royal_treasure_chest.glb')
blob = gltf.binary_blob()
mesh0_prim0 = gltf.meshes[0].primitives[0]
pos_data = get_accessor_data(gltf, blob, mesh0_prim0.attributes.POSITION)
idx_data = get_accessor_data(gltf, blob, mesh0_prim0.indices)
print('Mesh 0 Prim 0 Position shape:', pos_data.shape, 'min:', pos_data.min(axis=0), 'max:', pos_data.max(axis=0))
print('Mesh 0 Prim 0 Indices shape:', idx_data.shape, 'max index:', idx_data.max())
