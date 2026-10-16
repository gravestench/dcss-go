-- Source: player.cc:innate_sinv, player_monster_detect_radius, show.cc.
local capabilities = require("constants.mutation_capabilities")
local catalog = require("policy.catalog")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local flags = require("constants.monster_flags")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local jewellery_capabilities = require("constants.jewellery_capabilities")

local senses = {}

local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

function senses.see_invisible(ctx, player)
    return effects.sum(ctx, player, capabilities.SEE_INVISIBLE) > 0 or
        jewellery_effects.has(ctx, player,
            jewellery_capabilities.SEE_INVISIBLE)
end

function senses.detect_radius(ctx, player)
    return math.min(7, effects.sum(ctx, player,
        capabilities.MONSTER_DETECTION_RADIUS))
end

function senses.perceive(ctx, player, monster, cell_visible, cell_known)
    local origin = ctx:get(player, component.POSITION)
    local position = ctx:get(monster, component.POSITION)
    local distance = math.max(math.abs(origin.x - position.x),
        math.abs(origin.y - position.y))
    local detected = origin.level_id == position.level_id and
        distance <= senses.detect_radius(ctx, player)

    if not cell_visible then
        if cell_known and detected then
            return "detected"
        end

        return "unseen"
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local enchant = ctx:get(monster, component.MONSTER_ENCHANT)
    local invisible = has_flag(definition, flags.INVISIBLE) or
        (enchant and (enchant.invisible_aut or 0) > 0)

    if not invisible or senses.see_invisible(ctx, player) then
        return "visible"
    end

    if detected then
        return "detected"
    end

    return "unseen"
end

function senses.run_perception(ctx, input)
    return {
        mode = senses.perceive(ctx, ctx:player(), input.monster,
            input.cell_visible, input.cell_known),
    }
end

register.policy({
    id = "character.monster_perception",
    run = senses.run_perception,
})

return senses
