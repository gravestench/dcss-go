local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

local dragons = {}

local function dragon_type(ctx, power)
    local chance = summons.roll(ctx, math.max(1, power))

    if chance >= 80 or summons.roll(ctx, 6) == 0 then
        return summons.roll(ctx, 2) == 0 and
            monsters.MONS_GOLDEN_DRAGON or monsters.MONS_QUICKSILVER_DRAGON
    end

    if chance >= 40 or summons.roll(ctx, 6) == 0 then
        local roll = summons.roll(ctx, 3)

        if roll == 0 then
            return monsters.MONS_IRON_DRAGON
        end

        return roll == 1 and monsters.MONS_SHADOW_DRAGON or monsters.MONS_STORM_DRAGON
    end

    return summons.roll(ctx, 2) == 0 and
        monsters.MONS_FIRE_DRAGON or monsters.MONS_ICE_DRAGON
end

local function hostile_in_sight(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local visible = {}

    for _, entity in ipairs(ctx:query({ component.ACTOR, component.POSITION, component.HEALTH })) do
        if entity ~= player and not ctx:has(entity, component.SUMMON) then
            local position = ctx:get(entity, component.POSITION)
            local health = ctx:get(entity, component.HEALTH)
            local range = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if position.level_id == origin.level_id and health.current > 0 and
                range <= 7 and ctx:visible(origin.level_id, origin.x,
                    origin.y, 7, position.x, position.y) then
                visible[#visible + 1] = position
            end
        end
    end

    if #visible == 0 then
        return nil
    end

    return visible[summons.roll(ctx, #visible) + 1]
end

local function count(ctx, player)
    local total = 0

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.owner == player and state.spell_id == spells.SPELL_DRAGON_CALL then
            total = total + 1
        end
    end

    return total
end

function dragons.advance(ctx, player)
    local state = ctx:get(player, component.SUMMON_DRAGON_CALL)

    if not state then
        return
    end

    if ctx:aut() >= state.ends_aut then
        ctx:remove(player, component.SUMMON_DRAGON_CALL)

        return
    end

    if ctx:aut() < state.next_aut then
        return
    end

    local anchor = hostile_in_sight(ctx, player)

    if anchor then
        local magic = ctx:get(player, component.MAGIC)
        local cost = 2 + summons.roll(ctx, 2)

        if magic.current < cost then
            ctx:emit("spell", "A dragon cannot answer without enough magical power!")
        else
            local creature = summons.spawn(ctx, player,
                spells.SPELL_DRAGON_CALL, dragon_type(ctx, state.power),
                2, 999, { anchor = anchor })

            if creature then
                magic.current = magic.current - cost
                ctx:set(player, component.MAGIC, magic)
                ctx:emit("spell", "A dragon arrives to answer your call!")
            end
        end
    end

    state.next_aut = ctx:aut() +
        (3 + summons.roll(ctx, 5) + count(ctx, player) * 5) * 10
    ctx:set(player, component.SUMMON_DRAGON_CALL, state)
end

-- Source: spl-summoning.cc:cast_dragon_call and do_dragon_call.
function dragons.resolve(ctx, player, _, _, power)
    local duration = (15 + math.floor(power / 5) +
        summons.roll(ctx, 15)) * 10
    local state = {
        ends_aut = ctx:aut() + duration,
        next_aut = ctx:aut() + (3 + summons.roll(ctx, 5)) * 10,
        power = power,
    }

    if ctx:has(player, component.SUMMON_DRAGON_CALL) then
        ctx:set(player, component.SUMMON_DRAGON_CALL, state)
    else
        ctx:add(player, component.SUMMON_DRAGON_CALL, state)
    end

    ctx:emit("spell", "You call out to the draconic realm!")
end

registry.add(spells.SPELL_DRAGON_CALL, {
    resolve = dragons.resolve,
})

return dragons
