--!strict
local NumberFormatter = {}
function NumberFormatter.Compact(
value: number
): string
if typeof(value) ~= "number" then
return "0"
end
if value ~= value
or value == math.huge
or value == -math.huge
then
return "0"
end
local negative =
value < 0
local absolute =
math.abs(value)
local suffix = ""
local divisor = 1
if absolute >= 1_000_000_000 then
suffix = "B"
divisor = 1_000_000_000
elseif absolute >= 1_000_000 then
suffix = "M"
divisor = 1_000_000
elseif absolute >= 1_000 then
suffix = "K"
divisor = 1_000
end
if divisor == 1 then
local rounded =
math.floor(
absolute
)
return (
negative
and "-"
or ""
)
.. tostring(
rounded
)
end
local compact =
absolute / divisor
local text
if compact >= 100 then
text =
string.format(
"%.0f",
compact
)
elseif compact >= 10 then
text =
string.format(
"%.1f",
compact
)
else
text =
string.format(
"%.2f",
compact
)
end
text =
string.gsub(
text,
"(%..-)0+$",
"%1"
)
text =
string.gsub(
text,
"%.$",
""
)
return (
negative
and "-"
or ""
)
.. text
.. suffix
end
return NumberFormatter
