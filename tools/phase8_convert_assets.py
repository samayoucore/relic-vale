"""Convert the official FBX files to clean glTF while retaining authored skin animation."""
import bpy, pathlib, json, hashlib
workspace=pathlib.Path(__file__).resolve().parent.parent
root=workspace/'relic_vale/assets/3d/phase8'
report=[]
for source in sorted(root.rglob('*.fbx')):
    target=source.with_suffix('.glb')
    if target.exists(): continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(source), use_anim=True)
    for obj in list(bpy.data.objects):
        if obj.type=='MESH' and len(obj.data.polygons)==0:
            bpy.data.objects.remove(obj,do_unlink=True)
    if not any(obj.type=='MESH' for obj in bpy.data.objects):
        raise RuntimeError('No mesh: '+str(source))
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_yup=True)
    report.append({'source':str(source.relative_to(workspace)),'runtime':str(target.relative_to(workspace)),'meshes':sum(o.type=='MESH' for o in bpy.data.objects),'animations':len(bpy.data.actions),'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
    print('PHASE8_CONVERT',source.name,flush=True)
(workspace/'downloads/phase8-conversion.json').write_text(json.dumps(report,indent=2))
