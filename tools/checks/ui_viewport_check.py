from pathlib import Path
import json,sys

ROOT=Path(__file__).resolve().parents[2]
model=json.loads((ROOT/'src/StarterGui/BloomUI.model.json').read_text(encoding='utf-8'))
TARGETS=['ObjectiveCard','CurrencyHUD','MenuDock','RollHUD','VerticalRoulette','RollButton','ActiveBoostsHUD']
VIEWPORTS=[(1920,1080),(1366,768),(1280,720)]
NO_OVERLAP=[('ObjectiveCard','VerticalRoulette'),('CurrencyHUD','MenuDock'),('RollHUD','RollButton'),('ActiveBoostsHUD','RollButton'),('ActiveBoostsHUD','RollHUD')]
DOCK_BUTTONS=['Dock_SeedSatchel','Dock_Index','Dock_Workshop','Dock_Trials','Dock_Settings']
MIN_HIT=44
EXPANDED_DOCK_BUTTONS=['Dock_SeedSatchel','Dock_Index','Dock_Workshop','Dock_Trials','Dock_Settings']

def children(node): return node.get('Children',[]) or []
def find(node,name):
    if node.get('Name')==name: return node
    for child in children(node):
        found=find(child,name)
        if found:return found
    return None
def udim2(props,key,default):
    value=(props.get(key) or {}).get('UDim2')
    return value if isinstance(value,list) and len(value)==2 else default
def vector2(props,key,default):
    value=(props.get(key) or {}).get('Vector2')
    return value if isinstance(value,list) and len(value)==2 else default
def axis(component,parent):
    return float(component[0])*parent+float(component[1])
def rect(node,w,h):
    p=node.get('Properties',{})
    size=udim2(p,'Size',[[0,100],[0,100]])
    pos=udim2(p,'Position',[[0,0],[0,0]])
    anchor=vector2(p,'AnchorPoint',[0,0])
    rw=max(0,axis(size[0],w));rh=max(0,axis(size[1],h))
    x=axis(pos[0],w)-float(anchor[0])*rw
    y=axis(pos[1],h)-float(anchor[1])*rh
    return x,y,rw,rh
def overflow(r,w,h):
    x,y,rw,rh=r
    return max(0,-x,-y,x+rw-w,y+rh-h)
def intersects(a,b):
    ax,ay,aw,ah=a;bx,by,bw,bh=b
    return min(ax+aw,bx+bw)>max(ax,bx) and min(ay+ah,by+bh)>max(ay,by)
def contained(inner,outer):
    ix,iy,iw,ih=inner;ox,oy,ow,oh=outer
    return ix>=ox-0.01 and iy>=oy-0.01 and ix+iw<=ox+ow+0.01 and iy+ih<=oy+oh+0.01

safe=find(model,'SafeRoot')
if not safe: raise SystemExit('FAIL SafeRoot missing')
direct={child.get('Name'):child for child in children(safe)}
failed=[]
dock_model=direct.get('MenuDock')
if dock_model:
    dp=dock_model.get('Properties',{})
    dock_w=axis(udim2(dp,'Size',[[0,0],[0,0]])[0],1920)
    by_name={c.get('Name'):c for c in children(dock_model)}
    workshop=by_name.get('Dock_Workshop')
    if workshop:
        wr=rect(workshop,dock_w,75)
        workshop_center=wr[0]+wr[2]/2
        if abs(workshop_center-dock_w/2)>.01:
            failed.append('Dock_Workshop is not centered in expanded MenuDock')
    for name in EXPANDED_DOCK_BUTTONS:
        node=by_name.get(name)
        if not node:
            failed.append(f'{name}: missing from expandable MenuDock')
        elif rect(node,dock_w,75)[2] != 75 or rect(node,dock_w,75)[3] != 75:
            failed.append(f'{name}: must match 75x75 RollButton size')
    if by_name.get('Dock_SeedSatchel') and by_name['Dock_SeedSatchel'].get('Properties',{}).get('BackgroundTransparency') != 1:
        failed.append('Dock_SeedSatchel background must be fully transparent')
for w,h in VIEWPORTS:
    print(f'VIEWPORT {w}x{h}')
    rects={}
    for name in TARGETS:
        node=direct.get(name)
        if not node:
            failed.append(f'{name}: not a direct SafeRoot child'); continue
        r=rect(node,w,h);rects[name]=r
        print(f'  {name}: x={r[0]:.1f} y={r[1]:.1f} w={r[2]:.1f} h={r[3]:.1f} overflow={overflow(r,w,h):.1f}px')
        if r[2]<=0 or r[3]<=0: failed.append(f'{w}x{h} {name}: non-positive size')
        if overflow(r,w,h)>.01: failed.append(f'{w}x{h} {name}: clips outside SafeRoot')
    for left,right in NO_OVERLAP:
        if left in rects and right in rects and intersects(rects[left],rects[right]):
            failed.append(f'{w}x{h} {left} overlaps {right}')
    roll=rects.get('RollButton')
    if roll and (roll[2]<MIN_HIT or roll[3]<MIN_HIT):
        failed.append(f'{w}x{h} RollButton hit target below {MIN_HIT}px')
    dock=direct.get('MenuDock');dock_rect=rects.get('MenuDock')
    if dock and dock_rect:
        dx,dy,dw,dh=dock_rect
        by_name={c.get('Name'):c for c in children(dock)}
        for name in DOCK_BUTTONS:
            node=by_name.get(name)
            if not node:
                failed.append(f'{w}x{h} {name}: missing'); continue
            local=rect(node,dw,dh)
            global_rect=(dx+local[0],dy+local[1],local[2],local[3])
            if local[2]<MIN_HIT or local[3]<MIN_HIT: failed.append(f'{w}x{h} {name}: hit target below {MIN_HIT}px')
            if not contained(global_rect,dock_rect): failed.append(f'{w}x{h} {name}: not fully contained by MenuDock')
if failed:
    print('\nFAILURES')
    for item in failed: print(' - '+item)
    sys.exit(1)
print('\nPASS desktop HUD is on-screen, key HUD regions do not overlap, and primary hit targets stay >=44px at all target viewports')
