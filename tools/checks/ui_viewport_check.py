from pathlib import Path
import json,sys

ROOT=Path(__file__).resolve().parents[2]
model=json.loads((ROOT/'src/StarterGui/BloomUI.model.json').read_text(encoding='utf-8'))
TARGETS=['ObjectiveCard','CurrencyHUD','MenuDock','RollHUD','VerticalRoulette','RollButton']
VIEWPORTS=[(1920,1080),(1366,768),(1280,720)]
MAX_OVERFLOW={'MenuDock':32}

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
def visible_fraction(r,w,h):
    x,y,rw,rh=r
    if rw<=0 or rh<=0:return 0
    ix=max(0,min(x+rw,w)-max(x,0))
    iy=max(0,min(y+rh,h)-max(y,0))
    return (ix*iy)/(rw*rh)

safe=find(model,'SafeRoot')
if not safe:
    raise SystemExit('FAIL SafeRoot missing')

direct={child.get('Name'):child for child in children(safe)}
failed=[]
for w,h in VIEWPORTS:
    print(f'VIEWPORT {w}x{h}')
    for name in TARGETS:
        node=direct.get(name)
        if not node:
            failed.append(f'{name}: not a direct SafeRoot child')
            print(f'  FAIL {name}: missing')
            continue
        r=rect(node,w,h)
        fraction=visible_fraction(r,w,h)
        print(f'  {name}: x={r[0]:.1f} y={r[1]:.1f} w={r[2]:.1f} h={r[3]:.1f} visible={fraction*100:.1f}%')
        if r[2]<=0 or r[3]<=0:
            failed.append(f'{w}x{h} {name}: non-positive size')
        else:
            allowed=MAX_OVERFLOW.get(name,8)
            x,y,rw,rh=r
            overflow=max(0,-x,-y,x+rw-w,y+rh-h)
            if overflow>allowed:
                failed.append(f'{w}x{h} {name}: {overflow:.1f}px overflow exceeds {allowed}px allowance')

if failed:
    print('\nFAILURES')
    for item in failed:print(' - '+item)
    sys.exit(1)
print('\nPASS authored desktop HUD geometry stays within edge-overflow allowances at all target viewports')
