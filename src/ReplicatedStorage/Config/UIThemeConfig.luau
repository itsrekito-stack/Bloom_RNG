-- Shared visual language for Bloom RNG.
-- Keep this file as the single source of truth for UI proportions/colors.
local T={}

T.Colors={
 Background=Color3.fromRGB(12,17,23),
 Panel=Color3.fromRGB(18,25,34),
 PanelSoft=Color3.fromRGB(24,33,44),
 PanelRaised=Color3.fromRGB(31,42,55),
 PanelHover=Color3.fromRGB(39,53,69),
 BorderDark=Color3.fromRGB(6,9,13),
 Border=Color3.fromRGB(70,91,112),
 BorderSoft=Color3.fromRGB(49,66,82),
 Text=Color3.fromRGB(245,248,252),
 Muted=Color3.fromRGB(167,183,199),
 Faint=Color3.fromRGB(112,130,148),
 Blue=Color3.fromRGB(83,173,255),
 BlueDeep=Color3.fromRGB(32,105,184),
 BlueSoft=Color3.fromRGB(28,61,92),
 Green=Color3.fromRGB(102,224,166),
 GreenDeep=Color3.fromRGB(31,122,85),
 Gold=Color3.fromRGB(255,205,91),
 Honey=Color3.fromRGB(255,176,72),
 Dust=Color3.fromRGB(187,139,255),
 Nectar=Color3.fromRGB(98,231,214),
 Danger=Color3.fromRGB(255,105,123),
 Overlay=Color3.fromRGB(4,7,10),
 White=Color3.fromRGB(255,255,255),
 Black=Color3.fromRGB(0,0,0),
}

T.Radius={Small=7,Medium=10,Large=14,Window=16,Pill=999}
T.Stroke={Window=2,Panel=2,Control=1.5,Subtle=1,DarkTransparency=.10,SoftTransparency=.34}
T.Spacing={XS=4,S=7,M=10,L=14,XL=18}
T.Typography={Caption=10,Small=11,Body=12,Button=12,Title=18,WindowTitle=20}
T.Layout={
 Edge=12,
 ObjectiveWidth=430,
 CurrencyWidth=190,
 DockButton=44,
 DockGap=6,
 RollWidth=250,
 RollHeight=44,
 PanelMaxWidth=760,
 PanelMaxHeight=560,
 PanelMinWidth=360,
 PanelMinHeight=330,
}
T.Motion={Fast=.09,Normal=.16,Slow=.28}

return table.freeze(T)
