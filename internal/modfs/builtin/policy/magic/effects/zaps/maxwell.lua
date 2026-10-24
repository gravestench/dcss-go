local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local channel = require("policy.magic.channel")
local damage = require("policy.magic.damage")
local death_hooks = require("policy.combat.death_hooks")
local registry = require("policy.magic.effects.registry")
local targets = require("policy.ai.targets")
local player_contact = require("policy.combat.player_contact")

local maxwell = { continuation_mp = 0 }

-- Check optional flags to exclude monsters that cannot be coupled.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Coupling ignores conjured and harmless monsters; nearest ties are chosen with spell RNG.
local function nearest(ctx, player, visible)
    local origin = ctx:get(player, component.POSITION)
    local found = {}
    local closest = 8

    for _, target in ipairs(ctx:query({
        component.ACTOR, component.HEALTH, component.POSITION,
    })) do
        if targets.enemy(ctx, player, target) then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local actor = ctx:get(target, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if position.level_id == origin.level_id and
                health.current > 0 and distance <= 7 and
                not has_flag(definition, "M_CONJURED") and
                not has_flag(definition, "M_NO_THREAT") and
                (not visible or ctx:visible(origin.level_id,
                    origin.x, origin.y, 7, position.x, position.y)) then
                if distance < closest then
                    found = { target }
                    closest = distance
                elseif distance == closest then
                    found[#found + 1] = target
                end
            end
        end
    end

    if #found == 0 then
        return nil
    end

    if visible then
        return found[1]
    end

    return found[1 + ctx:random("spell", #found)]
end

-- Round the fractional charge duration with one spell draw.
local function random_round(ctx, numerator, denominator)
    local value = math.floor(numerator / denominator)

    if ctx:random("spell", denominator) < numerator % denominator then
        value = value + 1
    end

    return value
end

-- Prevent starting a charge without a nearby legal target.
function maxwell.prepare(ctx, player)
    if not nearest(ctx, player, true) then
        return "There is no target for the charge."
    end
end

-- Save a power-scaled charge timer after subtracting the cast action cost.
function maxwell.resolve(ctx, player, _, _, power, cast_aut)
    local spread = math.max(0, (200 - math.min(power, 200)) * 40)
    local rolled = spread > 0 and ctx:random("spell", spread) or 0
    local duration = 30 + random_round(ctx, rolled, 200)
    local remaining = math.max(1, duration - (cast_aut or 10))

    if ctx:has(player, zap_ids.component.MAXWELL) then
        ctx:set(player, zap_ids.component.MAXWELL, { remaining_aut = remaining })
    else
        ctx:add(player, zap_ids.component.MAXWELL, { remaining_aut = remaining })
    end

    channel.begin(ctx, player, {
        spell_id = spells.SPELL_MAXWELLS_COUPLING,
        power = power,
        stage = 0,
    })
    ctx:emit("spell", "You begin accumulating electric charge.")
end

-- Require saved charge state when computing the next channel action cost.
function maxwell.continuation_cost(ctx, player, _, normal_cost)
    local state = ctx:get(player, zap_ids.component.MAXWELL)

    if not state then
        error("Maxwell's Coupling lost its charge timer")
    end

    return math.max(1, math.min(normal_cost, state.remaining_aut))
end

-- Channel progress persists as MAXWELL component state until a target is vaporized or channeling ends.
function maxwell.continue(ctx, player, _, aut)
    local state = ctx:get(player, zap_ids.component.MAXWELL)

    if not state then
        error("Maxwell's Coupling lost its charge timer")
    end

    state.remaining_aut = state.remaining_aut - aut

    if state.remaining_aut > 0 then
        ctx:set(player, zap_ids.component.MAXWELL, state)
        ctx:emit("spell", "You feel charge building up...")
        return true, true
    end

    ctx:remove(player, zap_ids.component.MAXWELL)
    local target = nearest(ctx, player, false)

    if not target then
        ctx:emit("spell", "Your charge dissipates without a target.")
        return true, false
    end

    local definition, health = damage.monster(ctx, target)

    player_contact.report(ctx, target, definition)
    ctx:add(target, zap_ids.component.MAXWELL_VAPORIZE, { active = true })
    damage.apply(ctx, target, health.current)
    ctx:emit("spell", "The electricity discharges through the " ..
        definition.name .. "!")

    return true, false
end

-- The death hook completes the coupling effect only for a marked monster.
function maxwell.on_death(ctx, monster)
    local mark = ctx:get(monster, zap_ids.component.MAXWELL_VAPORIZE)

    return mark ~= nil and mark.active
end

-- Example: If the player stops channeling, cleanup removes the unused Maxwell charge.
-- Clear charge only after its channel component disappears, preventing a stale discharge on later turns.
function maxwell.cleanup(ctx, entity)
    if entity == ctx:player() and
        ctx:has(entity, zap_ids.component.MAXWELL) and
        not ctx:has(entity, component.CHANNEL) then
        ctx:remove(entity, zap_ids.component.MAXWELL)
        ctx:emit("spell", "The insufficient charge dissipates harmlessly.")
    end
end

registry.add(spells.SPELL_MAXWELLS_COUPLING, maxwell)
death_hooks.add("magic.maxwell", maxwell.on_death)

-- Theory of operation: After an attack, clear Maxwell charge if channel state ended before movement advances.
register.system({
    id = "zap.maxwell.cleanup",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "world.movement" },
    update = maxwell.cleanup,
})

return maxwell
