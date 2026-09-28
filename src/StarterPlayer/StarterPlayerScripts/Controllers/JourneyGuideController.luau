local S={}

function S:Init(ui,visualGuide)
 self.UI=ui
 self.Visual=visualGuide
end

function S:IsSolarBloomStep()
 return false
end

function S:SolarBloomTarget()
 return nil,nil,nil
end

function S:RenderObjective()
 return false
end

function S:Update()
 return false
end

return S
