local TestUtils = {}

function TestUtils.safeRequire(moduleScript)
    local ok, result = pcall(require, moduleScript)
    return ok, result
end

function TestUtils.countKeys(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

function TestUtils.hasValue(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then return true end
    end
    return false
end

function TestUtils.timestamp()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

return TestUtils
