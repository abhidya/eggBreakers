local Assert = {}

local function fail(message)
    error(message or "assertion failed", 2)
end

function Assert.truthy(value, message)
    if not value then fail(message or "expected truthy value") end
end

function Assert.falsy(value, message)
    if value then fail(message or "expected falsy value") end
end

function Assert.equals(actual, expected, message)
    if actual ~= expected then
        fail((message or "values not equal") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

function Assert.notNil(value, message)
    if value == nil then fail(message or "expected non-nil value") end
end

function Assert.between(value, minValue, maxValue, message)
    if value < minValue or value > maxValue then
        fail((message or "value out of range") .. ": " .. tostring(value))
    end
end

return Assert
