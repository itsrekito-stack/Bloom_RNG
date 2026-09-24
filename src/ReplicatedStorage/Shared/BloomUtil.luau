local U={}
function U.Copy(t) if type(t)~="table" then return t end local r={} for k,v in pairs(t) do r[k]=U.Copy(v) end return r end
function U.Count(t) local n=0 for _,v in pairs(t or {}) do if v then n=n+1 end end return n end
function U.Number(x,default,max) if type(x)~="number" or x~=x or math.abs(x)==math.huge then return default or 0 end return math.clamp(x,0,max or 1e12) end
function U.Integer(x,max) return type(x)=="number" and x==x and x>=1 and x<=max and x%1==0 end
function U.Near(player,pos,distance) local c=player.Character local r=c and c:FindFirstChild("HumanoidRootPart") local h=c and c:FindFirstChildOfClass("Humanoid") return r~=nil and h~=nil and h.Health>0 and (r.Position-pos).Magnitude<=distance end
function U.Equal(a,b) if type(a)~=type(b) then return false end if type(a)~="table" then return a==b end for k,v in pairs(a) do if not U.Equal(v,b[k]) then return false end end for k in pairs(b) do if a[k]==nil then return false end end return true end
return U
