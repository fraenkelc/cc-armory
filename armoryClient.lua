os.loadAPI('api/ui/bpanel')
os.loadAPI("api/util/config")

local cfg = config.new("armoryClient.config", {
  modemSide = "back"
}).load()

local choices = {}
rednet.open(cfg.modemSide)
local host = rednet.lookup("armory")

if not host then error("No host found") end

local fn = function (choice)
  rednet.send(host, textutils.serialize({type="selectArmor", choice=choice.id}), "armory")
  local senderId, message, protocol = rednet.receive("armoryResponse");
end

rednet.send(host, textutils.serialize({type="listChoices"}), "armory")
local senderId, message, protocol = rednet.receive("armoryResponse");
choices = textutils.unserialize(message).choices

-- put in the name as the button text
for i, v in ipairs(choices) do v.text = v.name end

local panel = bpanel.new("Armory Interface", fn, choices)
while true do
  panel.handleClicks()
end


































