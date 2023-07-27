--[[
    Nview

    Nview is a class that allows for easy non-remote replication of data.
    Nview classes are created on the server and client, and are synced automatically.
]]

--[[
    Config start
]]

local DataFolderName = "NViews"
local DataFolderLocation = game.ReplicatedStorage

--[[
    Config end
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Signal = require(game.ReplicatedStorage.Packages.Signal)

local IsServer = RunService:IsServer()
local NexusInstance = require(game.ReplicatedStorage.NexusInstance.NexusInstance) --We use a modified version of NexusInstance so we can validate properties.

local NView = NexusInstance:Extend()
NView:SetClassName("NView")

--Wait for the data folder to appear if we are the client, otherwise create it as server.
local DataFolder = DataFolderLocation:FindFirstChild(DataFolderName)

if IsServer and not DataFolder then
    local DataFolder = Instance.new("Folder")
    DataFolder.Name = DataFolderName
    DataFolder.Parent = DataFolderLocation
elseif not DataFolder then
    DataFolder = DataFolderLocation:WaitForChild(DataFolderName)
end

local IgnoreIndexTypes = {
    ["_viewdata"] = true;
    ["_indexTypes"] = true;
    ["_viewInstance"] = true;
    ["_dataChangedConnection"] = true;
    ["OnViewDestroying"] = true;
    ["ValueChanged"] = true;
}

local function fromFullPath(path)
    local current = game
    for name in path:gmatch("[^%.]+") do
        current = current:WaitForChild(name)
    end
    return current
end


function NView:__new(dataInstance)
    NexusInstance.__new(self)

    self._viewdata = {}
    self._indexTypes = {}

    self.OnViewDestroying = Signal.new()
    self.ValueChanged = Signal.new()

    self._viewInstance = dataInstance

    local NViewID
    local setParent = false

    if not dataInstance then
        NViewID = HttpService:GenerateGUID(false)
        dataInstance = Instance.new("Folder")
        dataInstance.Name = NViewID
        setParent = true

        if not IsServer then
            self._locallyCreated = true
        end
        self._viewInstance = dataInstance
    else
        if IsServer then
            for name in dataInstance:GetAttributes() do
                self:__PropertyValidator(name, dataInstance:GetAttribute(name))
            end

            if not dataInstance:GetAttribute("ViewID") then
                NViewID = HttpService:GenerateGUID(false)
            end
        else
            for name in dataInstance:GetAttributes() do
                self:__AttributeChanged(name)
            end
        end
    end

    if not IsServer and not self._locallyCreated then
        self._dataChangedConnection = self._viewInstance.AttributeChanged:Connect(function(attribute)
            self:__AttributeChanged(attribute)
        end)
    end

    self:AddGenericPropertyValidator(function(...) return self:__PropertyValidator(...) end)
    self:AddGenericPropertyGetter(function(...) return self:__PropertyGetter(...) end)

    --We only parent after we do all the initialization, that way any variables are replicated on start
    if IsServer then
        self.ViewID = NViewID
        if setParent then
            dataInstance.Parent = DataFolder
        end
    end
end

function NView:__PropertyValidator(Index, Value)
    if IgnoreIndexTypes[Index] then
        return Value
    end

    assert(IsServer or self.__InternalProperties._locallyCreated, "Cannot set properties on the client.")

    local viewdata = self.__InternalProperties._viewdata

    self.__InternalProperties._indexTypes[Index] = typeof(Value)
    self.__InternalProperties._viewInstance:SetAttribute("Types", HttpService:JSONEncode(self._indexTypes))

    if typeof(Value) == "table" then
        self.__InternalProperties._viewInstance:SetAttribute(Index, HttpService:JSONEncode(Value))
    elseif typeof(Value) == "Instance" then
        self.__InternalProperties._viewInstance:SetAttribute(Index, Value:GetFullName())
    else
        self.__InternalProperties._viewInstance:SetAttribute(Index, Value)
    end

    viewdata[Index] = Value

    return Value
end

function NView:__PropertyGetter(Index, Value)
    if IgnoreIndexTypes[Index] then
        return Value
    end
    local viewdata = self.__InternalProperties._viewdata

    Value = viewdata[Index]

    return Value
end

function NView:__AttributeChanged(AttribName)
    local viewdata = self.__InternalProperties._viewdata
    if AttribName == "Types" or self.__InternalProperties._indexTypes[AttribName] == nil then
        self.__InternalProperties._indexTypes = HttpService:JSONDecode(self.__InternalProperties._viewInstance:GetAttribute("Types"))
    end

    local lastValue = viewdata[AttribName]
    
    if AttribName ~= "Types" then
        if self.__InternalProperties._indexTypes[AttribName] == "table" then
            viewdata[AttribName] = HttpService:JSONDecode(self._viewInstance:GetAttribute(AttribName))
        elseif self._indexTypes[AttribName] == "Instance" then
            viewdata[AttribName] = fromFullPath(self._viewInstance:GetAttribute(AttribName))
        else
            viewdata[AttribName] = self._viewInstance:GetAttribute(AttribName)
        end
    end
    self.__InternalProperties.ValueChanged:Fire(AttribName, viewdata[AttribName], lastValue)
end

function NView:Dispose()
    self.OnViewDestroying:Fire()

    if self._dataChangedConnection then
        self._dataChangedConnection:Disconnect()
    end

    self:Destroy()
end

return NView
