return {
 Order={"SunnyOrchard","CrystalGreenhouse","TwilightGrove"},
 Sectors={
  SunnyOrchard={Name="Sunny Orchard",Hive=2,Center=Vector3.new(0,0,-170),Color=Color3.fromRGB(140,210,90),Activity="SolarBloom"},
  CrystalGreenhouse={Name="Crystal Greenhouse",Hive=4,Requires="SunnyOrchard",Center=Vector3.new(165,0,90),Color=Color3.fromRGB(90,190,235),Activity="CrystalResonance"},
  TwilightGrove={Name="Twilight Grove",Hive=6,Requires="CrystalGreenhouse",Center=Vector3.new(-165,0,90),Color=Color3.fromRGB(125,90,180),Activity="FireflyRoute"},
 }
}
