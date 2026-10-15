local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

local function visible_enemy(ctx, player)
    local origin = ctx:get(player, component.POSITION)

    for _, entity in ipairs(ctx:query({ component.ACTOR, component.POSITION, component.HEALTH })) do
        if entity ~= player and not ctx:has(entity, component.SUMMON) then
            local position = ctx:get(entity, component.POSITION)
            local health = ctx:get(entity, component.HEALTH)
            local range = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and position.level_id == origin.level_id and
                range <= 7 and ctx:visible(origin.level_id, position.x,
                    position.y) then
                return true
            end
        end
    end

    return false
end

local function wraith(ctx)
    local roll = summons.roll(ctx, 10)

    if roll == 0 then
        return monsters.MONS_SHADOW_WRAITH
    end

    if roll < 6 then
        return monsters.MONS_WRAITH
    end

    if roll < 8 then
        return monsters.MONS_FREEZING_WRAITH
    end

    return monsters.MONS_PHANTASMAL_WARRIOR
end

-- Source: spl-summoning.cc:cast_haunt and pick_random_wraith.
local spell_effects = {}

function spell_effects.resolve(ctx, player, intent, _, power)
    local origin = ctx:get(player, component.POSITION)
    local x = origin.x + intent.dx
    local y = origin.y + intent.dy
    local target = ctx:actor_at(origin.level_id, x, y)

    if not target or target == player or
        ctx:has(target, component.SUMMON) then
        ctx:emit("spell", "An evil force gathers, but it quickly dissipates.")

        return
    end

    local count = 2 + math.floor(summons.roll(ctx,
        math.max(1, power)) / 10) +
        math.floor(summons.roll(ctx, math.max(1, power)) / 10)
    count = math.min(6, count)
    local anchor = ctx:get(target, component.POSITION)
    local appeared = 0

    for _ = 1, count do
        if summons.spawn(ctx, player, spells.SPELL_HAUNT, wraith(ctx),
            3, 8, { anchor = anchor }) then
            appeared = appeared + 1
        end
    end

    if appeared > 1 then
        ctx:emit("spell", "Insubstantial figures form in the air.")
    end
end

registry.add(spells.SPELL_HAUNT, {
    can_target = visible_enemy,
    resolve = spell_effects.resolve,
})

return spell_effects
