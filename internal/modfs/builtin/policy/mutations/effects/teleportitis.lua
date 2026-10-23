-- Source: player.cc:get_teleportitis_level, player-reacts.cc:player_reacts,
-- and spl-transloc.cc:_teleport_player. A failed landing or quiet landing
-- consumes the trigger without relocating the player.
local capabilities = require("constants.mutation_capabilities")
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")
local teleport = require("policy.magic.player_teleport")
local traits = require("policy.character.traits")

local teleportitis = {}

-- Convert mutation level to the per-turn teleportitis rate consumed by the
-- timer, leaving the scheduling decision in one tick handler.
function teleportitis.rate(level)
    return level * 6
end

-- Advance the saved chance on elapsed aut and draw only when the mutation is
-- active. A failed destination search still respects the source draw budget.
function teleportitis.tick(ctx, player, aut)
    if aut <= 0 then
        return
    end

    local position = ctx:get(player, component.POSITION)

    -- Source teleportitis is disabled in the Gauntlet, even though a
    -- manually requested blink is still legal there.
    if position and ctx:level_branch(position.level_id) ==
        branches.BRANCH_GAUNTLET then
        return
    end

    local level = effects.sum(ctx, player,
        capabilities.TELEPORTITIS_RATE)

    if level <= 0 then
        return
    end

    local choice = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", choice.species_id)

    local forms = require("policy.magic.effects.forms.player")

    if traits.stasis(species) or forms.stasis(ctx, player) or
        ctx:random("mutation", 100) >= math.min(100, aut) or
        ctx:random("mutation", math.floor(100 / level)) ~= 0 then
        return
    end

    -- Lugonu and Teleportitis use the same first-safe-cell and nearby
    -- hostile test. The mutation owns only its trigger rate and message.
    teleport.now(ctx, player, {
        near_monsters = true,
        channel = "mutation",
        reason = "You feel strangely unstable.",
    })
end

effects.add(mutations.MUT_TELEPORT, {
    [capabilities.TELEPORTITIS_RATE] = teleportitis.rate,
})

return teleportitis
