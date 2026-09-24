-- Shared visual language for Bloom RNG.
local T={}

T.Colors={
 Background=Color3.fromRGB(13,18,24),
 Panel=Color3.fromRGB(20,27,36),
 PanelSoft=Color3.fromRGB(27,36,47),
 PanelRaised=Color3.fromRGB(34,45,58),
 PanelHover=Color3.fromRGB(42,56,72),
 BorderDark=Color3.fromRGB(7,10,14),
 Border=Color3.fromRGB(74,96,118),
 BorderSoft=Color3.fromRGB(55,72,89),
 Text=Color3.fromRGB(245,248,252),
 Muted=Color3.fromRGB(166,184,202),
 Faint=Color3.fromRGB(116,136,156),
 Blue=Color3.fromRGB(84,174,255),
 BlueDeep=Color3.fromRGB(37,116,198),
 BlueSoft=Color3.fromRGB(31,67,101),
 Green=Color3.fromRGB(102,224,166),
 GreenDeep=Color3.fromRGB(34,130,91),
 Gold=Color3.fromRGB(255,205,91),
 Honey=Color3.fromRGB(255,176,72),
 Dust=Color3.fromRGB(187,139,255),
 Nectar=Color3.fromRGB(98,231,214),
 Danger=Color3.fromRGB(255,111,128),
 Overlay=Color3.fromRGB(5,8,12),
 White=Color3.fromRGB(255,255,255),
 Black=Color3.fromRGB(0,0,0),
}

T.Radius={Small=8,Medium=12,Large=16,Window=20,Pill=999}
T.Stroke={Window=3,Panel=2,Control=2,Subtle=1,DarkTransparency=.08,SoftTransparency=.28}
T.Spacing={XS=5,S=8,M=12,L=16,XL=22}
T.Layout={
 Edge=16,
 ObjectiveWidth=680,
 CurrencyWidth=236,
 DockButton=52,
 DockGap=8,
 RollWidth=330,
 RollHeight=124,
 PanelMaxWidth=1040,
 PanelMaxHeight=700,
 PanelMinWidth=420,
 PanelMinHeight=360,
}
T.Motion={Fast=.10,Normal=.18,Slow=.32}

return table.freeze(T)
