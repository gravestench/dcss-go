local catalog = require("policy.catalog")
local books = require("policy.magic.player_book_catalog")
local invoked = require("data.player_invoked_spells")
local categories = require("constants.catalog")
local scopes = require("constants.spell_scopes")

local scope = {}

-- Example: an unknown spell ID has scope NONE; a known book spell has scope BOOK.
-- Resolve book and invoked scopes from the catalog, returning NONE for malformed or unknown IDs.
function scope.of(id)
    if type(id) ~= "string" or id == "" then
        return scopes.NONE
    end

    local found, spell = pcall(catalog.get, categories.SPELLS, id)

    if not found or spell.status ~= "defined" then
        return scopes.NONE
    end

    if spell.player_scope then
        return spell.player_scope
    end

    if books.ids()[id] then
        return scopes.BOOK
    end

    if invoked[id] then
        return scopes.INVOKED
    end

    return scopes.NONE
end

-- The registered policy returns BOOK, INVOKED, or NONE from catalog and player spell lists.
function scope.run_policy(_, input)
    return { scope = scope.of(input.spell_id) }
end

register.policy({
    id = "magic.player_scope",
    run = scope.run_policy,
})

return scope
