-- Armory script
os.loadAPI("api/ipc/FolderIPC")
os.loadAPI("api/util/config")

local Armory = {}
Armory.__index = Armory

setmetatable(Armory, {
  __call = function(cls, ...)
    return cls.new(...)
  end
})

function Armory:buildChoices()
  self.choices = {}
  self.choiceToArmor = {}
  for i, v in ipairs(self.config.armor) do
    local choice = {id=v.side .. "-" .. v.color ,name = v.name}
    self.choiceToArmor[choice.id] = v
    table.insert(self.choices,choice)
  end
end

function Armory:armoryLoop()
  while true do
    local senderId, messageText, protocol = rednet.receive("armory")
    print("Got a message:", messageText)
    local message = textutils.unserialize(messageText)
    if message.type and message.type == "listChoices" then
      rednet.send(senderId, textutils.serialize({
        type="choiceList",
        choices=self.choices
      }), "armoryResponse")
    elseif message.type and message.type == "selectArmor" then
      self:selectArmor(message.choice)
      rednet.send(senderId, textutils.serialize({
        type="confirm"
      }), "armoryResponse")
    else
      print("Unknown message: " + messageText)
    end
  end
end

function Armory:selectArmor(choiceId)
  print("User selection: ", choiceId)
  local armor = self.choiceToArmor[choiceId]
  print(textutils.serialize(armor))

  -- extract current items from player
  redstone.setBundledOutput(self.config.player.side, colors[self.config.player.color])
  sleep(self.config.extractionTime)
  redstone.setBundledOutput(self.config.player.side, 0)

  -- put in the selected items
  redstone.setBundledOutput(armor.side, colors[armor.color])
  sleep(self.config.extractionTime)
  redstone.setBundledOutput(armor.side, 0)
end

function Armory.new(cfgFile)
  local self = setmetatable({}, Armory)
  self.config = config.new("armory.config", {
    modemSide = "top",
    hostName = "armory",
    extractionTime = 1,
    player = {
      side="back",
      color="red"
    },
    armor = {
      {
        name="Diamond Armor",
        side="right",
        color="orange",
      },
    }
  }):load()
  self:buildChoices()
  rednet.open(self.config.modemSide)
  rednet.host( "armory", self.config.hostName)
  return self;
end


function remoteRelay ()
  local ipc = FolderIPC.new("/disk/ipc")
  while true do
    local suc, msg = ipc:readMessages(os.getComputerID(), function (messageText)
      local message = textutils.unserialize(messageText)
      print("got a message on IPC: " .. messageText)
      if not message.type=="armory" then print("invalid message on ipc: ", messageText); return false end
      print("Starting to relay")
      rednet.send(os.getComputerID(), textutils.serialize(message.data), "armory")
      print("Sent message on local rednet")
      local senderId, rnMessageText, protocol = rednet.receive("armoryResponse")
      print ("got reply")
      ipc:sendMessage(message.sender, textutils.serialize({type="armory", data=textutils.unserialize(rnMessageText)}))
      print ("relayed reply")
      return true
    end
    )
    if not suc then error(msg) end
    os.sleep(0.2)
  end
end

local armory = Armory.new()

parallel.waitForAny(function()armory:armoryLoop() end, remoteRelay)

