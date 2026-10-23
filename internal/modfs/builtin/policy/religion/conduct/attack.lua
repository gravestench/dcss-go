-- Theory of operation: each offensive action reports its actual monster
-- contacts before hit or resistance rolls. Contact owners call this once
-- per attempted target; the classifier reads live allegiance, visibility,
-- holiness, and former-neutral history before combat changes the actor.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local conduct = require("policy.religion.conduct")
local gods = require("constants.gods")

local attack = {}

-- A ray or direct spell may already have resolved a live monster profile.
-- When it has not, use the same catalog entry that combat uses for damage.
function attack.report(ctx, monster, definition)
    local player = ctx:player()
    local worship = player and ctx:get(player, component.RELIGION_WORSHIP)

    -- Old combat fixtures and godless games have no listener for these
    -- facts. Avoid sight and catalog work until someone can react.
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

    -- Allegiance may itself load player status policies. Resolve that graph
    -- only at contact, after Lua has finished registering those modules.
    local facts = require("policy.religion.conduct.monster_facts")

    for _, event in ipairs(facts.attack(ctx, monster, definition)) do
        conduct.record(ctx, event)
    end
end

return attack
