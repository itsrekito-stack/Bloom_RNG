--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local function findPackage(names: {string}): Instance
for _, name in ipairs(names) do
local package = Packages:FindFirstChild(name)
if package then
return package
end
end
error("[ReactPackages] Package not found: " .. table.concat(names, " / "))
end
local React = require(findPackage({
"React",
"react",
}))
local ReactRoblox = require(findPackage({
"ReactRoblox",
"react-roblox",
}))
return {
React = React,
ReactRoblox = ReactRoblox,
}
