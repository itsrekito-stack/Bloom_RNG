local RS=game:GetService("ReplicatedStorage") local T=require(RS.Config.TutorialConfig) local Features=require(RS.Config.FeatureUnlockConfig) local S={}
function S:Init(x) self.X=x end
function S:Refresh(player)
 local p=self.X:Profile(player) if not p then return end local t=p.Tutorial local old=t.Step
 while T.Steps[t.Step] do local e=T.Steps[t.Step].Event local complete=(t.Events[e] or 0)>0 if e=="Deliveries" then complete=(t.Events.Delivery or 0)>=3 end if not complete then break end t.Step=t.Step+1 end
 for id,rule in pairs(Features) do
  local unlocked=rule.Step and t.Step>=rule.Step or rule.Event and (t.Events[rule.Event] or 0)>0 or rule.Node and p.WorkshopV5.Nodes[rule.Node]==true
  if rule.Node then t.FeatureUnlocks[id]=unlocked==true elseif unlocked then t.FeatureUnlocks[id]=true end
 end
 if old<=#T.Steps and t.Step>#T.Steps then self.X:EmitOnce(player,"TutorialComplete") end
end
function S:Skip(player)
 local p=self.X:Profile(player) if not p then return end
 if not p.StarterBeeGranted then self.X.HiveService:Interact(player) end
 p.Tutorial.Step=#T.Steps+1 p.Tutorial.Skipped=true for id,r in pairs(Features) do if not r.Node then p.Tutorial.FeatureUnlocks[id]=true end end
end
function S:Replay(player) self.X:Send(player,"Replay",T.Steps) end
return S
