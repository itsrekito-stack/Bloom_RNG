"""Deterministic Lua 5.4 mocks; NOT Roblox Studio/DataStore integration.
Uses the existing harness registry/color/vector mocks. Luau compound assignments
in tested legacy modules are lowered to equivalent assignments (simple lvalues).
Bees helpers retain the existing harness substitutions; persistence is unmodified.
"""
from pathlib import Path
import ctypes as ct
import re
ROOT = Path(__file__).resolve().parents[2]
generator = ROOT / 'tools/checks/make_harness.py'
ns = {'__file__': str(generator)}
exec(compile(generator.read_text().split("base+=Path('tests/pure.lua')")[0], str(generator), 'exec'), ns)
base = ns['base']
# Existing DataConfig has one return type annotation.
base = base.replace('GetStoreName(): string', 'GetStoreName()')
base = re.sub(r'([A-Za-z_]\w*(?:(?:\.[A-Za-z_]\w*)|(?:\[[^\]\n]+\]))*)\s*([+*/-])=',
              lambda m: f'{m[1]}={m[1]}{m[2]}', base)
static_checks = """
local syntaxPaths={
 "ServerScriptService/Services/DataService", "ServerScriptService/Services/SeasonService",
 "ServerScriptService/Services/PlayerService", "ServerScriptService/Services/WorkshopService",
 "ServerScriptService/Services/GardenPlotService", "ServerScriptService/Services/StatsService",
 "ServerScriptService/Services/UIStateService", "ServerScriptService/Services/RemoteService",
 "ServerScriptService/Services/RollService", "ServerScriptService/Services/QuestService",
 "ServerScriptService/Services/MapService", "ServerScriptService/Services/SocialService",
 "ServerScriptService/Data/ProfileDomain", "ServerScriptService/Data/ProfileSchema",
 "ServerScriptService/Data/DataConfig", "ReplicatedStorage/Shared/GardenRules"
}
for _,path in ipairs(syntaxPaths) do assert(load(sources[path],path,"t",_G)) end
print("STATIC PASS "..#syntaxPaths.." changed Luau modules through Lua 5.4 compatibility checks (not a Luau typecheck)")
"""
source = base + static_checks + (ROOT/'tests/pure.lua').read_text() + (ROOT/'tests/phase2a.lua').read_text() + '\nprint("TOTAL PASS "..passed)\n'
lib=ct.CDLL('/usr/lib/x86_64-linux-gnu/liblua5.4.so.0')
lib.luaL_newstate.restype=ct.c_void_p
lib.luaL_openlibs.argtypes=[ct.c_void_p]
lib.luaL_loadbufferx.argtypes=[ct.c_void_p,ct.c_char_p,ct.c_size_t,ct.c_char_p,ct.c_char_p]
lib.lua_pcallk.argtypes=[ct.c_void_p,ct.c_int,ct.c_int,ct.c_int,ct.c_longlong,ct.c_void_p]
lib.lua_tolstring.argtypes=[ct.c_void_p,ct.c_int,ct.c_void_p];lib.lua_tolstring.restype=ct.c_char_p
lib.lua_close.argtypes=[ct.c_void_p]
state=lib.luaL_newstate();lib.luaL_openlibs(state)
raw=source.encode()
rc=lib.luaL_loadbufferx(state,raw,len(raw),b'phase2a',None)
if rc==0:rc=lib.lua_pcallk(state,0,0,0,0,None)
if rc:raise RuntimeError(lib.lua_tolstring(state,-1,None).decode())
lib.lua_close(state)
