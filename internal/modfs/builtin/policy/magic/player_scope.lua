local catalog = require("policy.catalog")
local player_ids = require("data.player_spell_ids")
local scopes = require("constants.spell_scopes")

local scope = {}

function scope.of(id)
    if type(id) ~= "string" or id == "" then
        return scopes.NONE
    end

    local found, spell = pcall(catalog.get, "spells", id)

    if not found or spell.status ~= "defined" then
        return scopes.NONE
    end

    if spell.player_scope then
        return spell.player_scope
    end

    if player_ids.books[id] then
        return scopes.BOOK
    end

    if player_ids.invoked[id] then
        return scopes.INVOKED
    end

    return scopes.NONE
end

function scope.run_policy(_, input)
    return { scope = scope.of(input.spell_id) }
end

register.policy({
    id = "magic.player_scope",
    run = scope.run_policy,
})

return scope
