--!strict
local TableUtil = {}
function TableUtil.DeepCopy(source)
local copy = {}
for key, value in pairs(source) do
if type(value) == "table" then
copy[key] = TableUtil.DeepCopy(value)
else
copy[key] = value
end
end
return copy
end
return TableUtil
