local effects = {}
local registered = {}
local player_ids = require("data.player_spell_ids")
local catalog = require("policy.catalog")
local scopes = require("constants.spell_scopes")

-- Register one resolver per spell id so invoke can dispatch by learned spell without a Go switch.
function effects.add(id, effect)
    if type(id) ~= "string" or id == "" or registered[id] then
        error("duplicate or invalid player spell effect " .. tostring(id))
    end

    if type(effect) ~= "table" or type(effect.resolve) ~= "function" then
        error("player spell effect " .. id .. " has no resolver")
    end

    registered[id] = effect
end

-- Example: A registered spell ID returns its resolver for casting; an absent ID returns nil.
-- Return the registered resolver by spell ID so cast and channel paths use the same effect.
function effects.get(id)
    return registered[id]
end

-- Compare all learnable catalog spells with registered resolvers to catch content added without an effect.
function effects.missing()
    local missing = {}
    local seen = {}

    for id in pairs(player_ids.books) do
        seen[id] = true
    end

    for id in pairs(player_ids.invoked) do
        seen[id] = true
    end

    for _, spell in ipairs(catalog.all("spells")) do
        if spell.status == "defined" and
            (spell.player_scope == scopes.BOOK or
                spell.player_scope == scopes.INVOKED) then
            seen[spell.id] = true
        end
    end

    for id in pairs(seen) do
        if not registered[id] then
            missing[#missing + 1] = id
        end
    end

    table.sort(missing)

    return missing
end

-- Coverage checks the spell catalog against resolver registrations after all modules load.
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
