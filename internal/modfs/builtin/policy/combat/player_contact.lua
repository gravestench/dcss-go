-- Theory of operation: player offensive actions report each actual monster
-- contact before hit or resistance rolls. Religious conduct observes the
-- original allegiance; then the attack can break Elyvilon's peace.
-- Melee, missiles, spells, and evokers use this same entry point so a miss
-- still counts as an attempt without repeating the rule in each resolver.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local conduct = require("policy.religion.conduct")
local gods = require("constants.gods")

local contact = {}

-- Use the caller's resolved profile when available. The conduct reader
-- needs the side as it was at contact, before the peace marker changes.
local function report_conduct(ctx, monster, definition)
    local player = ctx:player()
    local worship = player and ctx:get(player, component.RELIGION_WORSHIP)

    if not worship or worship.god_id == gods.NO_GOD then
        return
    end

    if not definition then
        local actor = ctx:get(monster, component.ACTOR)

        if not actor then
            return
        end

        definition = catalog.get(categories.MONSTERS, actor.kind_id)
    end

    -- Loading this graph at contact avoids a module registration cycle.
    local facts = require("policy.religion.conduct.monster_facts")

    for _, event in ipairs(facts.attack(ctx, monster, definition)) do
        conduct.record(ctx, event)
    end
end

-- A peaceful monster sees an attempted attack even if later accuracy,
-- armour, or resistance prevents damage. The conduct event runs first.
function contact.report(ctx, monster, definition)
    report_conduct(ctx, monster, definition)
    require("policy.religion.elyvilon.pacification").anger(ctx, monster)
end

return contact
