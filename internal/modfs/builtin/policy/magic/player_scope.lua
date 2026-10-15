local catalog = require("policy.catalog")
local player_ids = require("data.player_spell_ids")

local scope = {}

function scope.of(id)
    if type(id) ~= "string" or id == "" then
        return "none"
    end

    local found, spell = pcall(catalog.get, "spells", id)

    if not found or spell.status ~= "defined" then
        return "none"
    end

    if player_ids.books[id] then
        return "book"
    end

    if player_ids.invoked[id] then
        return "invoked"
    end

    return "none"
end

function scope.run_policy(_, input)
    return { scope = scope.of(input.spell_id) }
end

register.policy({
    id = "magic.player_scope",
    run = scope.run_policy,
})

return scope
