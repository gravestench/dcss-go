local component = require("constants.component")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local channel = require("policy.magic.channel")
local projectile = require("policy.magic.effects.zaps.projectile")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local targets = require("policy.ai.targets")

local searing_ray = {}

-- zap-data.h:ZAP_SEARING_RAY and spl-damage.cc:handle_searing_ray.
local spec = {
    name = "searing ray",
    cap = 50,
    beam = true,
    damage = {
        kind = "calcdice",
        count = 2,
        base = 9,
        numerator = 1,
        denominator = 7,
    },
    hit = {
        base = 11,
        numerator = 1,
        denominator = 8,
    },
}

-- An ally entering the continuing ray cancels the next projectile pulse
-- before it can damage that ally.
local function friendly_in_ray(ctx, player, x, y, spell)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        x, y, range.for_spell(ctx, player, spell))

    for _, contact in ipairs(ray.contacts) do
        if targets.allied(ctx, contact.actor) then
            return true
        end
    end

    return false
end

-- Example: resolve(ctx, player, intent, spell, 60) fires the first pulse and
-- saves direction so later actions can continue the same ray.
-- Fire the first pulse now, then persist aim and target identity for later channel actions.
function searing_ray.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local x = origin.x + intent.dx
    local y = origin.y + intent.dy

    projectile.fire(ctx, player, intent, spell, spec, power)

    local target = ctx:actor_at(origin.level_id, x, y)

    channel.begin(ctx, player, {
        spell_id = spells.SPELL_SEARING_RAY,
        power = power,
        stage = 0,
        aimed_at_spot = target == nil,
        target_x = x,
        target_y = y,
        target_monster = target,
    })
end

-- A continued ray checks friendly actors in its path before firing the next beam.
function searing_ray.continue(ctx, player, state)
    local origin = ctx:get(player, component.POSITION)
    local spell = catalog.get("spells", spells.SPELL_SEARING_RAY)

    if not state.aimed_at_spot and state.target_monster then
        local target = state.target_monster
        local location = ctx:get(target, component.POSITION)
        local health = ctx:get(target, component.HEALTH)
        local reach = range.for_spell(ctx, player, spell)

        if location and health and health.current > 0 and
            location.level_id == origin.level_id and
            ctx:visible(origin.level_id, origin.x, origin.y, reach,
                location.x, location.y) then
            state.target_x = location.x
            state.target_y = location.y
        else
            state.aimed_at_spot = true
            state.target_monster = nil
        end
    end

    if friendly_in_ray(ctx, player, state.target_x, state.target_y, spell) then
        ctx:emit("spell", "You stop channelling your searing ray.")
        return false, false
    end

    projectile.fire(ctx, player, {
        dx = state.target_x - origin.x,
        dy = state.target_y - origin.y,
    }, spell, spec, state.power)

    return true, state.stage < 3
end

registry.add(spells.SPELL_SEARING_RAY, searing_ray)

return searing_ray
