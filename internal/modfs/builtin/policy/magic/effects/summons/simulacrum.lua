local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local catalog = require("policy.catalog")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

-- Read the actor at the selected offset again during resolve because the grid can change after targeting.
local function target_at(ctx, player, dx, dy)
    local origin = ctx:get(player, component.POSITION)

    return ctx:actor_at(origin.level_id, origin.x + dx, origin.y + dy)
end

-- Mark only living attack-capable originals; summoned or already marked actors cannot convert twice.
local function valid_target(ctx, player, target)
    if not target or target == player or
        ctx:has(target, component.SUMMON) or
        ctx:has(target, component.SUMMON_MARK) then
        return false
    end

    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)

    local living_kind = false

    for _, holiness in ipairs(definition.holiness or {}) do
        if holiness == "MH_NATURAL" or holiness == "MH_DEMONIC" or
            holiness == "MH_HOLY" then
            living_kind = true
            break
        end
    end

    if not living_kind or actor.kind_id == monsters.MONS_PANDEMONIUM_LORD then
        return false
    end

    for _, strike in ipairs(definition.attacks or {}) do
        if strike.type_id ~= "AT_NONE" then
            return true
        end
    end

    return false
end

-- Source: spl-monench.cc:cast_simulacrum. Death conversion is a separate
-- system because the source first freezes a living soul, then raises it.
local spell_effects = {}

-- Example: Simulacrum rejects a target that cannot carry a frozen-soul death mark.
-- Require an unmarked living attacker before paying to freeze its soul for later death conversion.
function spell_effects.prepare(ctx, player, _, dx, dy)
    if not valid_target(ctx, player, target_at(ctx, player, dx, dy)) then
        return "You cannot freeze that soul."
    end
end

-- Store an expiring soul mark; the death path creates the simulacrum only if the marked actor dies.
function spell_effects.resolve(ctx, player, intent, _, power)
    local target = target_at(ctx, player, intent.dx, intent.dy)

    if not valid_target(ctx, player, target) then
        return
    end

    local duration = 20 + summons.roll(ctx,
        1 + math.floor((power + summons.roll(ctx, 10)) / 10))
    ctx:add(target, component.SUMMON_MARK, {
        owner = player,
        expires_aut = ctx:aut() + duration * 10,
        power = power,
    })
    ctx:emit("spell", "You freeze the monster's soul.")
end

registry.add(spells.SPELL_SIMULACRUM, {
    prepare = spell_effects.prepare,
    resolve = spell_effects.resolve,
})

return spell_effects
