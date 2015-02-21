os.loadAPI("api/ipc/FolderIPC")
os.loadAPI("api/util/config")

local RemoteArmory = {}
RemoteArmory.__index = RemoteArmory

setmetatable(RemoteArmory, {
  __call = function(cls, ...)
    return cls.new(...)
  end
})

function RemoteArmory.new()
  local self = setmetatable({}, RemoteArmory)
  self.config = config.new("remoteArmory.config", {
    modemSide = "top",
    hostName = "zz_proxy-armory_" .. os.getComputerID(),
    armoryId = 5,
  }):load()

  rednet.open(self.config.modemSide)
  rednet.host( "armory", self.config.hostName)
  return self;
end

function RemoteArmory:armoryLoop()
  local ipc = FolderIPC.new("/disk/ipc")
  while true do
    local senderId, messageText, protocol = rednet.receive("armory")
    print("Got a message:", messageText)
    local message = textutils.unserialize(messageText)
    ipc:sendMessage(self.config.armoryId, textutils.serialize({sender=os.getComputerID(), type="armory", data=message}))
    print("relayed message")
    local gotReply = false
    while not gotReply do
      os.sleep(0.2)
      ipc:readMessages(os.getComputerID(), function (messageText)
        local message = textutils.unserialize(messageText)
        if not message.type == "armory" then print("unhandle message: ", messageText); return false end
        print("got a reply")
        rednet.send(senderId, textutils.serialize(message.data), "armoryResponse")
        print("relayed reply")
        gotReply=true
        return true
      end)

    end
  end
end

local RemoteArmory = RemoteArmory.new()

parallel.waitForAny(function() RemoteArmory:armoryLoop() end, relay)
