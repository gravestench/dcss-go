local effects = {}
local registered = {}
local player_ids = require("data.player_spell_ids")

function effects.add(id, effect)
    if type(id) ~= "string" or id == "" or registered[id] then
        error("duplicate or invalid player spell effect " .. tostring(id))
    end

    if type(effect) ~= "table" or type(effect.resolve) ~= "function" then
        error("player spell effect " .. id .. " has no resolver")
    end

    registered[id] = effect
end

function effects.get(id)
    return registered[id]
end

function effects.missing()
    local missing = {}
    local seen = {}

    for id in pairs(player_ids.books) do
        seen[id] = true
    end

    for id in pairs(player_ids.invoked) do
        seen[id] = true
    end

    for id in pairs(seen) do
        if not registered[id] then
            missing[#missing + 1] = id
        end
    end

    table.sort(missing)

    return missing
end

function effects.run_coverage()
    return {
        missing = effects.missing(),
    }
end

register.policy({
    id = "magic.effect_coverage",
    run = effects.run_coverage,
})

return effects
