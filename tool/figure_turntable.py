"""Renders one of the user's 3D figures as a turntable, for the login page.

Run with Blender in the background:
  blender -b --factory-startup -P tool/figure_turntable.py -- \
      <model.glb> <out_dir> <frames> <width> <height> <font.ttf> [frame...]

The figure is centred and scaled to a fixed height, a name plate (the
Instagram mark and @jtinnnng) is set on the front of its base so it turns
with it, and it is lit like the brand: a warm gold key from the upper left,
a cool rim from behind. Background transparent, one RGBA PNG per angle,
frame 0 facing the camera. Listing frame numbers renders only those.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index('--') + 1:]
GLB, OUT, FRAMES, W, H, FONT = argv[0], argv[1], int(argv[2]), int(argv[3]), int(argv[4]), argv[5]
ONLY = [int(a) for a in argv[6:]]
HANDLE = '@jtinnnng'

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
bpy.ops.import_scene.gltf(filepath=GLB)

meshes = [o for o in scene.objects if o.type == 'MESH']
lo = Vector((1e9, 1e9, 1e9))
hi = Vector((-1e9, -1e9, -1e9))
for o in meshes:
    for c in o.bound_box:
        p = o.matrix_world @ Vector(c)
        lo = Vector(map(min, lo, p))
        hi = Vector(map(max, hi, p))
height = hi.z - lo.z
scale = 2.0 / height

# The base's own centre, from the vertices of its bottom slice: the bounding
# box is pulled sideways by a raised hand, and spinning around it made the
# base wobble and the name plate sit off centre.
import numpy as np
slice_top = lo.z + 0.03 * height
xs, ys = [], []
for o in meshes:
    n = len(o.data.vertices)
    co = np.empty(n * 3, dtype=np.float32)
    o.data.vertices.foreach_get('co', co)
    co = co.reshape(-1, 3)
    m = np.array(o.matrix_world)
    world = co @ m[:3, :3].T + m[:3, 3]
    low = world[world[:, 2] < slice_top]
    if len(low):
        xs += [low[:, 0].min(), low[:, 0].max()]
        ys += [low[:, 1].min(), low[:, 1].max()]
base_cx = (min(xs) + max(xs)) / 2 if xs else (lo.x + hi.x) / 2
base_cy = (min(ys) + max(ys)) / 2 if ys else (lo.y + hi.y) / 2
base_span = max(max(xs) - min(xs), max(ys) - min(ys)) if xs else max(hi.x - lo.x, hi.y - lo.y)

pivot = bpy.data.objects.new('pivot', None)
scene.collection.objects.link(pivot)
pivot.location = (base_cx, base_cy, lo.z)
for o in [o for o in scene.objects if o.parent is None and o is not pivot]:
    mw = o.matrix_world.copy()
    o.parent = pivot
    o.matrix_parent_inverse = pivot.matrix_world.inverted()
    o.matrix_world = mw
pivot.location = (0, 0, 0)
pivot.scale = (scale, scale, scale)
# The pivot now sits at the origin with the figure's feet on z=0; move the
# figure so its footprint centre is over the origin.
for o in pivot.children:
    o.location.x -= base_cx
    o.location.y -= base_cy
    o.location.z -= lo.z
bpy.context.view_layer.update()

# The base: the widest slice near the bottom.
base_r = base_span * scale / 2
base_top = 0.06 * 2.0


def emission_mat(name, rgba, strength=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    em = nt.nodes.new('ShaderNodeEmission')
    em.inputs['Color'].default_value = rgba
    em.inputs['Strength'].default_value = strength
    nt.links.new(em.outputs[0], out.inputs[0])
    return m


def plate_mat():
    m = bpy.data.materials.new('plate')
    m.use_nodes = True
    bsdf = m.node_tree.nodes['Principled BSDF']
    bsdf.inputs['Base Color'].default_value = (0.02, 0.02, 0.025, 1)
    bsdf.inputs['Roughness'].default_value = 0.35
    bsdf.inputs['Metallic'].default_value = 0.6
    return m


def ig_gradient_mat():
    """Instagram's diagonal gradient, yellow to violet, as emission."""
    m = bpy.data.materials.new('ig')
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    em = nt.nodes.new('ShaderNodeEmission')
    em.inputs['Strength'].default_value = 1.6
    # The icon stands in the XZ plane: run the gradient from the bottom left
    # corner (x+z small) to the top right.
    tc = nt.nodes.new('ShaderNodeTexCoord')
    sep = nt.nodes.new('ShaderNodeSeparateXYZ')
    add = nt.nodes.new('ShaderNodeMath')
    add.operation = 'ADD'
    half = nt.nodes.new('ShaderNodeMath')
    half.operation = 'MULTIPLY'
    half.inputs[1].default_value = 0.5
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    stops = [
        (0.0, (0.996, 0.855, 0.459, 1)),
        (0.3, (0.980, 0.494, 0.118, 1)),
        (0.55, (0.839, 0.161, 0.463, 1)),
        (0.8, (0.588, 0.184, 0.749, 1)),
        (1.0, (0.310, 0.357, 0.835, 1)),
    ]
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = stops[0]
    els[1].position, els[1].color = stops[-1]
    for pos, col in stops[1:-1]:
        e = els.new(pos)
        e.color = col
    nt.links.new(tc.outputs['Generated'], sep.inputs[0])
    nt.links.new(sep.outputs['X'], add.inputs[0])
    nt.links.new(sep.outputs['Z'], add.inputs[1])
    nt.links.new(add.outputs[0], half.inputs[0])
    nt.links.new(half.outputs[0], ramp.inputs['Fac'])
    nt.links.new(ramp.outputs['Color'], em.inputs['Color'])
    nt.links.new(em.outputs[0], out.inputs[0])
    return m


def rounded_rect_curve(name, w, h, r, thick):
    cu = bpy.data.curves.new(name, 'CURVE')
    cu.dimensions = '3D'
    cu.bevel_depth = thick
    cu.bevel_resolution = 3
    sp = cu.splines.new('POLY')
    pts = []
    for cx, cy, a0 in ((w / 2 - r, h / 2 - r, 0), (-w / 2 + r, h / 2 - r, 90),
                       (-w / 2 + r, -h / 2 + r, 180), (w / 2 - r, -h / 2 + r, 270)):
        for k in range(9):
            a = math.radians(a0 + k * 90 / 8)
            pts.append((cx + r * math.cos(a), 0, cy + r * math.sin(a)))
    sp.points.add(len(pts) - 1)
    for p, xyz in zip(sp.points, pts):
        p.co = (*xyz, 1)
    sp.use_cyclic_u = True
    ob = bpy.data.objects.new(name, cu)
    scene.collection.objects.link(ob)
    return ob


def circle_curve(name, r, thick):
    cu = bpy.data.curves.new(name, 'CURVE')
    cu.dimensions = '3D'
    cu.bevel_depth = thick
    cu.bevel_resolution = 3
    sp = cu.splines.new('POLY')
    n = 40
    sp.points.add(n - 1)
    for i, p in enumerate(sp.points):
        a = 2 * math.pi * i / n
        p.co = (r * math.cos(a), 0, r * math.sin(a), 1)
    sp.use_cyclic_u = True
    ob = bpy.data.objects.new(name, cu)
    scene.collection.objects.link(ob)
    return ob


# The name plate, standing on the front of the base, leaning back a little.
plate_w, plate_h = 0.95, 0.2
bpy.ops.mesh.primitive_cube_add(size=1)
plate = bpy.context.active_object
plate.name = 'nameplate'
plate.scale = (plate_w, 0.04, plate_h)
bevel = plate.modifiers.new('bevel', 'BEVEL')
bevel.width = 0.03
bevel.segments = 6
plate.data.materials.append(plate_mat())
plate_y = -base_r - 0.02
plate.location = (0, plate_y, base_top * 0.5 + plate_h / 2)
plate.rotation_euler = (math.radians(-12), 0, 0)

group = bpy.data.objects.new('plate_face', None)
scene.collection.objects.link(group)
group.parent = plate
group.location = (0, -0.53, 0)
group.scale = (1 / plate_w, 1 / 0.04, 1 / plate_h)

ig_mat = ig_gradient_mat()
icon_size = 0.12
icon = [
    rounded_rect_curve('ig_frame', icon_size, icon_size, icon_size * 0.28, 0.006),
    circle_curve('ig_lens', icon_size * 0.22, 0.006),
]
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.009, location=(0, 0, 0))
dot = bpy.context.active_object
dot.location = (icon_size * 0.27, 0, icon_size * 0.27)
icon.append(dot)
for ob in icon:
    ob.data.materials.append(ig_mat)
    ob.parent = group

txt_cu = bpy.data.curves.new('handle', 'FONT')
txt_cu.body = HANDLE
txt_cu.font = bpy.data.fonts.load(FONT)
txt_cu.size = 0.105
txt_cu.extrude = 0.003
txt_cu.align_x = 'LEFT'
txt_cu.align_y = 'CENTER'
txt = bpy.data.objects.new('handle', txt_cu)
scene.collection.objects.link(txt)
txt.data.materials.append(emission_mat('white', (0.96, 0.95, 0.92, 1), 1.2))
txt.parent = group
txt.rotation_euler = (math.radians(90), 0, 0)

# Icon and handle as one centred row, the plate sized to it.
bpy.context.view_layer.update()
gap = icon_size * 0.4
text_w = txt.dimensions.x
row_w = icon_size + gap + text_w
start = -row_w / 2
icon_x = start + icon_size / 2
for ob in icon:
    ob.location = (icon_x + (icon_size * 0.27 if ob is dot else 0), 0,
                   icon_size * 0.27 if ob is dot else 0)
txt.location = (start + icon_size + gap, 0, 0)
plate_w = row_w + 0.16
plate.scale.x = plate_w
group.scale.x = 1 / plate_w

plate.parent = pivot
plate.matrix_parent_inverse = pivot.matrix_world.inverted()

# Lights: the brand's light and shadow.
def area(name, loc, rot, power, color, size):
    d = bpy.data.lights.new(name, 'AREA')
    d.energy = power
    d.color = color
    d.size = size
    ob = bpy.data.objects.new(name, d)
    ob.location = loc
    ob.rotation_euler = [math.radians(a) for a in rot]
    scene.collection.objects.link(ob)


area('key', (-2.6, -2.8, 3.4), (55, 0, -40), 1100, (1.0, 0.78, 0.45), 2.0)
area('fill', (2.8, -2.4, 1.4), (75, 0, 50), 180, (0.85, 0.9, 1.0), 3.0)
area('rim', (1.8, 2.8, 3.0), (-55, 0, 145), 700, (0.62, 0.72, 1.0), 1.5)

world = bpy.data.worlds.new('world')
world.use_nodes = True
world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.15
scene.world = world

cam_d = bpy.data.cameras.new('cam')
cam_d.lens = 70
cam = bpy.data.objects.new('cam', cam_d)
scene.collection.objects.link(cam)
cam.location = (0, -5.0, 1.35)
cam.rotation_euler = (math.radians(86), 0, 0)
scene.camera = cam

engines = {e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items}
scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in engines else 'BLENDER_EEVEE'
scene.render.resolution_x = W
scene.render.resolution_y = H
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
try:
    scene.view_settings.view_transform = 'AgX'
    scene.view_settings.look = 'AgX - Medium High Contrast'
except Exception:
    pass

os.makedirs(OUT, exist_ok=True)
for i in (ONLY or range(FRAMES)):
    pivot.rotation_euler = (0, 0, 2 * math.pi * i / FRAMES)
    scene.render.filepath = os.path.join(OUT, f'{i:03d}.png')
    bpy.ops.render.render(write_still=True)
    print('frame', i)
