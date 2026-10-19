-- The helper rejects unsafe host globals before returning a pure increment function.

if io ~= nil or os ~= nil or package ~= nil then
    error("process libraries are exposed")
end

if dofile ~= nil or loadfile ~= nil or math.random ~= nil then
    error("unsafe file or random API is exposed")
end

-- Return a pure arithmetic helper only after forbidden process APIs are
-- checked, so the valid-mod fixture proves safe Lua modules can be required.
return function(value)
    return value + 1
end
