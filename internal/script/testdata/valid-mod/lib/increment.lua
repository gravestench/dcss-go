if io ~= nil or os ~= nil or package ~= nil then
    error("process libraries are exposed")
end

if dofile ~= nil or loadfile ~= nil or math.random ~= nil then
    error("unsafe file or random API is exposed")
end

return function(value)
    return value + 1
end
