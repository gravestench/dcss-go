local component = require("constants.component")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local habitat = require("policy.combat.monster_habitat")
local net = require("policy.combat.net")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")

local beckoning = {}

-- Treat an absent flag list as empty when checking stationary monster exceptions.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Tentacles are stationary in the source catalog, so one mobility flag covers their exception.
local function movable(definition)
    -- Every source tentacle and segment is stationary in the imported
    -- catalog, so this same flag covers the source's tentacle exception.
    return not has_flag(definition, "M_STATIONARY")
end

-- Example: Beckoning pulls a mobile rat to the first open habitable cell on the beam path.
-- Use the first ray contact, then scan from the caster for an unoccupied cell the target can inhabit.
function beckoning.resolve(ctx, player, intent, spell)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.to_target(ctx, origin.level_id,
        origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]

    if not contact then
        return
    end

    local target = contact.actor
    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not actor or not health then
        error("Beckoning struck an actor without health")
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if health.current <= 0 or not movable(definition) then
        return
    end

    local current = ctx:get(target, component.POSITION)

    -- spl-transloc.cc:_beckon_destination scans the beam path from the
    -- caster and chooses the first unoccupied, habitable square.
    for _, cell in ipairs(ray.path) do
        if (cell.x ~= current.x or cell.y ~= current.y) and
            not ctx:actor_at(origin.level_id, cell.x, cell.y) and
            habitat.at(ctx, target, origin.level_id, cell.x, cell.y) then
            net.release(ctx, target)
            ctx:move_actor(target, origin.level_id, cell.x, cell.y)
            ctx:emit("spell", "The " .. definition.name ..
                " is hurled suddenly forward!")
            return
        end
    end
end

registry.add(spells.SPELL_BECKONING, beckoning)

return beckoning
