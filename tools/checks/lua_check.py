import os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
os.chdir(ROOT)
import ctypes as ct,json,re
from pathlib import Path
lib=ct.CDLL('/usr/lib/x86_64-linux-gnu/liblua5.4.so.0')
lib.luaL_newstate.restype=ct.c_void_p
lib.luaL_openlibs.argtypes=[ct.c_void_p]
lib.luaL_loadbufferx.argtypes=[ct.c_void_p,ct.c_char_p,ct.c_size_t,ct.c_char_p,ct.c_char_p];lib.luaL_loadbufferx.restype=ct.c_int
lib.lua_pcallk.argtypes=[ct.c_void_p,ct.c_int,ct.c_int,ct.c_int,ct.c_longlong,ct.c_void_p];lib.lua_pcallk.restype=ct.c_int
lib.lua_tolstring.argtypes=[ct.c_void_p,ct.c_int,ct.POINTER(ct.c_size_t)];lib.lua_tolstring.restype=ct.c_char_p
lib.lua_settop.argtypes=[ct.c_void_p,ct.c_int]
state=lib.luaL_newstate();lib.luaL_openlibs(state)
def execute(text,name='test',run=True):
 raw=text.encode();rc=lib.luaL_loadbufferx(state,raw,len(raw),name.encode(),None)
 if rc==0 and run:rc=lib.lua_pcallk(state,0,0,0,0,None)
 if rc: raise RuntimeError(name+': '+lib.lua_tolstring(state,-1,None).decode())
 lib.lua_settop(state,0)
p=ROOT/'src'; skip={'DataConfig','DataService','ServerBootstrap.server','FlowerService','BeesConfig','FlowersConfig','IconsConfig','TableUtil','ReactPackages','NumberFormatter'}
checked=[]
for f in p.rglob('*.luau'):
 if 'Packages' in f.parts or f.stem in skip: continue
 execute(f.read_text(),str(f),False);checked.append(str(f.relative_to(p)))
print('Lua 5.4-compatible source syntax checks:',len(checked),'(not a Luau typecheck)')
Path('tests/syntax_results.json').write_text(json.dumps(checked,indent=2))
if __name__=='__main__' and Path('tests/harness.lua').exists():execute(Path('tests/harness.lua').read_text(),'headless harness')
