local MockInstanceFactory = {}

local Mock = {}
Mock.__index = Mock

function Mock:IsA(className)
    return self.ClassName == className or (className == "Instance")
end

function Mock:IsDescendantOf(parent)
    if self == parent then return true end
    local current = self.Parent
    while current do
        if current == parent then return true end
        current = current.Parent
    end
    return false
end

function Mock:GetAttribute(name)
    return self.Attributes[name]
end

function Mock:SetAttribute(name, value)
    self.Attributes[name] = value
end

function Mock:GetPivot()
    return { Position = self.Position or { X = 0, Y = 0, Z = 0 } }
end

function Mock:GetDebugId()
    return self.DebugId or self.Name
end

function MockInstanceFactory.create(className, name, attributes)
    return setmetatable({
        ClassName = className or "Part",
        Name = name or "MockInstance",
        Attributes = attributes or {},
        Parent = nil,
        Transparency = 0,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
    }, Mock)
end

return MockInstanceFactory
