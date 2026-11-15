import bpy
import os

GLB_PATH = r"C:\Users\quant\Downloads\royal_treasure_chest.glb"
TEX_OUT = r"D:\MAIN\Programming\Projects\Galarang\roblox\assets\models\textures\royal_chest_atlas.png"
TEMP_OBJ = r"D:\MAIN\Programming\Projects\Galarang\roblox\assets\models\temp_royal_chest.obj"

print("--- [BLENDER HIGH-TO-LOW BAKE] Starting ---")
bpy.ops.wm.read_factory_settings(use_empty=True)

# 1. Import GLTF
bpy.ops.import_scene.gltf(filepath=GLB_PATH)
print("Imported objects:", len(bpy.data.objects))

# 2. Make single-user, clear parents keeping world transform, and apply transforms
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.make_single_user(object=True, obdata=True)
bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# 3. Hook correct diffuse textures to Base Color (bypassing glTF multiply node)
for m in bpy.data.materials:
    if m.node_tree:
        for n in m.node_tree.nodes:
            if n.type == 'TEX_IMAGE' and n.image and n.image.colorspace_settings.name == 'sRGB':
                bsdf = m.node_tree.nodes.get('Principled BSDF')
                if bsdf:
                    m.node_tree.links.new(n.outputs['Color'], bsdf.inputs['Base Color'])
                    print(f"Hooked {n.image.name} -> Base Color in {m.name}")

# 4. Remove all internal coins and invisible interior clutter
removed_count = 0
for o in list(bpy.data.objects):
    name = (o.name or '').lower()
    if any(k in name for k in ['coin', 'octagonal', 'treasure_coins']):
        bpy.data.objects.remove(o, do_unlink=True)
        removed_count += 1
print(f"Removed {removed_count} internal coin objects")

# 5. Join all remaining parts into HIGH
mesh_objs = [o for o in bpy.data.objects if o.type == 'MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in mesh_objs:
    o.select_set(True)
bpy.context.view_layer.objects.active = mesh_objs[0]
bpy.ops.object.join()
high = bpy.context.view_layer.objects.active
high.name = "Chest_High"

# Clean up High geometry: unify outward normals
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode='OBJECT')

print(f"High poly object: {len(high.data.vertices):,} verts, {len(high.data.polygons):,} polys")
print(f"High poly dimensions: {high.dimensions}")

# 6. Duplicate High to create LOW
bpy.ops.object.select_all(action='DESELECT')
high.select_set(True)
bpy.context.view_layer.objects.active = high
bpy.ops.object.duplicate()
low = bpy.context.view_layer.objects.active
low.name = "Chest_Low"

# 7. Decimate LOW to game-ready polygon budget (~16,000 polygons)
target_polys = 16000
current_polys = len(low.data.polygons)
if current_polys > target_polys:
    ratio = target_polys / current_polys
    mod = low.modifiers.new(name="Decimate", type='DECIMATE')
    mod.ratio = ratio
    bpy.ops.object.modifier_apply(modifier="Decimate")

tri_mod = low.modifiers.new(name="Triangulate", type='TRIANGULATE')
bpy.ops.object.modifier_apply(modifier="Triangulate")

print(f"Low poly object: {len(low.data.vertices):,} verts, {len(low.data.polygons):,} polys")

# 8. Clear old materials and UV maps on LOW
low.data.materials.clear()
while low.data.uv_layers:
    low.data.uv_layers.remove(low.data.uv_layers[0])

# 9. Smart UV project and pack islands on LOW
uv_layer = low.data.uv_layers.new(name="UVMap")
uv_layer.active = True
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.008, area_weight=0.0, correct_aspect=True, scale_to_bounds=True)
bpy.ops.uv.pack_islands(margin=0.008)
bpy.ops.object.mode_set(mode='OBJECT')

# 10. Create Target Material & Texture Image on LOW (2048x2048)
low_mat = bpy.data.materials.new("RoyalChestAtlas_Mat")
low_mat.use_nodes = True
bake_img = bpy.data.images.new("RoyalChestAtlas", width=2048, height=2048, alpha=False)
bake_node = low_mat.node_tree.nodes.new('ShaderNodeTexImage')
bake_node.image = bake_img
low_mat.node_tree.nodes.active = bake_node
low.data.materials.append(low_mat)

# 11. Configure Cycles Bake (Selected to Active, Diffuse Color only)
bpy.context.scene.render.engine = 'CYCLES'
bpy.context.scene.cycles.bake_type = 'DIFFUSE'
bpy.context.scene.render.bake.use_pass_direct = False
bpy.context.scene.render.bake.use_pass_indirect = False
bpy.context.scene.render.bake.use_pass_color = True
bpy.context.scene.render.bake.use_selected_to_active = True
bpy.context.scene.render.bake.cage_extrusion = 0.02
bpy.context.scene.render.bake.margin = 16

# Select High then Low (Active)
bpy.ops.object.select_all(action='DESELECT')
high.select_set(True)
low.select_set(True)
bpy.context.view_layer.objects.active = low

print("--- Running Cycles Selected-to-Active Diffuse Color Bake (2048x2048)... ---")
bpy.ops.object.bake(type='DIFFUSE')
print("--- Bake Completed! ---")

# Save baked texture
os.makedirs(os.path.dirname(TEX_OUT), exist_ok=True)
bake_img.filepath_raw = TEX_OUT
bake_img.file_format = 'PNG'
bake_img.save()
print(f"Saved baked texture to: {TEX_OUT}")

# 12. Export LOW to OBJ
os.makedirs(os.path.dirname(TEMP_OBJ), exist_ok=True)
bpy.ops.object.select_all(action='DESELECT')
low.select_set(True)
bpy.context.view_layer.objects.active = low

bpy.ops.wm.obj_export(
    filepath=TEMP_OBJ,
    export_selected_objects=True,
    export_uv=True,
    export_normals=True,
    export_materials=False,
    forward_axis='NEGATIVE_Z',
    up_axis='Y'
)
print("Exported OBJ to:", TEMP_OBJ)
