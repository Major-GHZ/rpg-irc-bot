local Stage = {}
Stage.__index = Stage

function Stage.new()
    return setmetatable({ name = "Default Stage" }, Stage)
end

function Stage:setName(name)
    self.name = name
end

function Stage:getName()
    return self.name
end

return Stage

