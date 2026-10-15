local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local power = require("policy.magic.power")
local traits = require("policy.character.traits")

local armour = {}

local sizes = {
    SIZE_TINY = 0,
    SIZE_LITTLE = 1,
    SIZE_SMALL = 2,
    SIZE_MEDIUM = 3,
    SIZE_LARGE = 4,
    SIZE_GIANT = 5,
}

-- Source: player.cc:player_armour_shield_spell_penalty,
-- adjusted_body_armour_penalty, and adjusted_shield_penalty.
function armour.spell_penalty(ctx, player)
    local character = ctx:get(player, "core.player")
    local attributes = ctx:get(player, "core.attributes")
    local progress = ctx:get(player, "core.progression")

    if not character or not attributes or not progress then
        error("player lacks armour penalty state")
    end

    local species = catalog.get("species", character.species_id)
    local worn = equipment.worn(ctx, player, {
        body = true,
        shield = true,
    })
    local body_penalty = 0
    local shield_penalty = 0

    if worn.body then
        local ev = worn.body.definition.armour.ev
        local sturdy = traits.mutation_level(species, "MUT_STURDY_FRAME",
            progress.level)
        local base = math.max(0, math.floor(-ev / 10) - sturdy * 2)
        local armour_skill = power.training(ctx, player, "SK_ARMOUR", 10)
        local numerator = 2 * base * base * (450 - armour_skill) * 100

        body_penalty = math.floor(numerator / (5 * (attributes.strength + 3)))
        body_penalty = math.floor(body_penalty / 450)
    end

    if worn.shield then
        local ev = worn.shield.definition.armour.ev
        local base = math.floor(-ev / 10)
        local shield_skill = power.training(ctx, player, "SK_SHIELDS", 10)
        local racial_factor = 2 * (sizes.SIZE_MEDIUM - sizes[species.size])

        if traits.mutation_level(species, "MUT_QUADRUMANOUS",
            progress.level) > 0 then
            racial_factor = -2
        end

        local numerator = 2 * base * base * (270 - shield_skill) * 100

        shield_penalty = math.floor(numerator / (5 * (20 - 3 * racial_factor)))
        shield_penalty = math.floor(shield_penalty / 270)
    end

    return math.floor((math.max(19 * body_penalty, 0) +
        19 * shield_penalty) / 100)
end

function armour.run_penalty(ctx)
    return { penalty = armour.spell_penalty(ctx, ctx:player()) }
end

register.policy({
    id = "magic.armour_penalty",
    run = armour.run_penalty,
})

return armour
