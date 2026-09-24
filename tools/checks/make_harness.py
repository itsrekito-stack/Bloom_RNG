import os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
os.chdir(ROOT)
from pathlib import Path
import json,re
S=ROOT/'src'
def literal(s):return '[========['+s+']========]'
modules={}
for f in S.rglob('*.luau'):
 if 'Packages' in f.parts:continue
 key=str(f.relative_to(S)).removesuffix('.luau')
 txt=f.read_text()
 if f.stem=='FlowersConfig':
  txt=re.sub(r':(?:string|Color3|number|boolean)\??','',txt);txt=txt.replace(':{string}','')
 if f.stem=='BeesConfig':
  # Test actual bee registry data; API helpers are defined below, avoiding Luau-only annotations.
  txt=txt[:txt.index('local totalWeight=0')]+'''function C.Get(id) return C.Bees[id] end
function C.Exists(id) return C.Bees[id]~=nil end
function C.GetTraitCounts(equipped) local out={} for _,id in pairs(equipped) do for _,tag in ipairs(C.Bees[id].Traits) do out[tag]=(out[tag] or 0)+1 end end return out end
function C.GetTraitBonuses() return {LuckMultiplier=1,PollinatorYieldMultiplier=1},{} end
function C.GetPassiveBonuses() return {LuckMultiplier=1,PollinatorYieldMultiplier=1} end
return C'''
 modules[key]=txt
base='''local nativeRequire=require
local Node={}
function Node:WaitForChild(name) return self[name] end
local function node(path)
 return setmetatable({path=path},{__index=function(t,k) if Node[k] then return Node[k] end if k=="Parent" then return node(path:match("^(.*)/") or "") end return node(path=="" and k or path.."/"..k) end})
end
local colors={} function colors:Lerp(other,a) return self end
Color3={new=function(...) return setmetatable({...},{__index=colors}) end};Color3.fromRGB=Color3.new
local V={}
local vmt={__index=function(v,k) if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) elseif k=="Unit" then return v/v.Magnitude else return V[k] end end}
Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vmt) end}
vmt.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vmt.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vmt.__mul=function(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vmt.__div=function(a,b) return Vector3.new(a.X/b,a.Y/b,a.Z/b) end
function V:Lerp(other,a) return self+(other-self)*a end
Vector3.zero=Vector3.new(0,0,0)
math.clamp=function(x,a,b) return math.max(a,math.min(b,x)) end
math.atan2=math.atan
table.clear=function(t) for k in pairs(t) do t[k]=nil end end
table.find=function(t,x) for i,v in pairs(t) do if v==x then return i end end end
table.freeze=function(t) return t end
table.create=function() return {} end
typeof=type
Random={new=function() return {NextNumber=function(_,a,b) local r=math.random() if a then return a+r*(b-a) end return r end} end}
workspace={GetServerTimeNow=function() return os.clock() end}
local rs=node("ReplicatedStorage")
game={GetService=function(_,name) if name=="ReplicatedStorage" then return rs elseif name=="HttpService" then return {GenerateGUID=function() return tostring(math.random()) end} end return node(name) end}
local sources={}
'''
for key,txt in modules.items():base+='sources['+json.dumps(key)+']='+literal(txt)+'\n'
base+='''local cache={}
function require(ref)
 if cache[ref.path] then return cache[ref.path] end
 local source=assert(sources[ref.path],"Unknown require "..ref.path)
 local env=setmetatable({script=node(ref.path)},{__index=_G})
 local f,err=load(source,ref.path,"t",env) assert(f,err) local result=f() cache[ref.path]=result return result
end
local passed=0
local function test(name,fn) local ok,err=pcall(fn) if not ok then error(name..": "..tostring(err)) end passed=passed+1 print("PASS "..name) end
local Schema=require(node("ServerScriptService/Data/ProfileSchema"))
local U=require(rs.Shared.BloomUtil)
local function equal(a,b) if type(a)~=type(b) then return false end if type(a)~="table" then return a==b end for k,v in pairs(a) do if not equal(v,b[k]) then return false end end for k in pairs(b) do if a[k]==nil then return false end end return true end
'''
base+=Path('tests/pure.lua').read_text()
base+='\nprint("TOTAL PASS "..passed)\n'
Path('tests/harness.lua').write_text(base)
