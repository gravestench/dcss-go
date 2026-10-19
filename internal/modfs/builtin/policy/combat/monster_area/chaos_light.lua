-- A light-flavoured chaos cell can leave a status after the direct hit.
-- Source: beam.cc:bolt::affect_player and bolt::apply_hit.
-- Example: a player hit has a one-in-three chance of two or three turns
-- of confusion; a monster hit receives the shared HD-scaled blind status.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local monster_enchant = require("policy.combat.monster_enchant")
local player_confusion = require("policy.magic.player_confusion")
local streams = require("constants.rng_streams")

local light = {}

-- Apply the secondary effect through its existing actor-specific owner so
-- light does not create a separate blindness or confusion representation.
function light.after_hit(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        if ctx:random(streams.MONSTER_SPELL, 3) == 0 then
            local turns = 2 + ctx:random(streams.MONSTER_SPELL, 2)

            player_confusion.extend(ctx, defender, turns)
        end

        return
    end

    local actor = ctx:get(defender, component.ACTOR)

    if not actor then
        return
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    monster_enchant.blind(ctx, defender, definition)
end

return light
