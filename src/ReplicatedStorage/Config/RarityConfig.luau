local C={Order={"Common","Uncommon","Rare","Epic","Legendary","Mythic","Celestial"},Rank={},Colors={}}
local colors={Color3.fromRGB(210,215,225),Color3.fromRGB(92,220,133),Color3.fromRGB(90,165,255),Color3.fromRGB(190,110,255),Color3.fromRGB(255,190,75),Color3.fromRGB(255,95,150),Color3.fromRGB(100,245,255)}
for i,id in ipairs(C.Order) do C.Rank[id]=i C.Colors[id]=colors[i] end
return C
