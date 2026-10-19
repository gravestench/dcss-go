local attitudes = require("constants.attitude")
local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local health = require("policy.combat.monster_health")
local monsters = require("ids.monsters")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local terrain = require("constants.terrain")

local portal = {}

-- mon-ench.cc gives the portal a nominal thirty-turn lifetime followed by
-- its ordinary asymmetric enchantment fuzz. Pacification has a separate
-- random2avg(power, 6) timer and only changes friendly allegiance.
function portal.spawn(ctx, state)
    local head = summons.spawn(ctx, state.owner, state.source_id,
        monsters.MONS_ELDRITCH_TENTACLE, 0, nil, {
            anchor = {
                level_id = state.level_id,
                x = state.x,
                y = state.y,
            },
            exact = { x = state.x, y = state.y },
            source_category = state.source_category,
            attitude = state.attitude,
        })

    if not head then
        return nil
    end

    local actor = ctx:get(head, component.ACTOR)
    local speed = math.max(1, actor.speed)
    local centiturns = math.floor(300 / math.max(1, math.floor(100 / speed)))
    local raw = centiturns * roll.random_divide(ctx, 100, speed,
        streams.MONSTER_SPELL)
    local lower = math.floor(raw * 60 / 100)
    local upper = math.floor(raw * 40 / 100)
    local lifetime = math.max(15, raw + roll.average_two(ctx,
        streams.MONSTER_SPELL, lower + upper + 1) - lower)
    local total = 0

    for _ = 1, 6 do
        total = total + ctx:random(streams.MONSTER_SPELL, state.power)
    end

    local pacified = math.max(0, (math.floor(total / 6) -
        ctx:random(streams.MONSTER_SPELL, 4)) * 10)

    ctx:add(head, constructs.PORTAL, {
        remaining_aut = lifetime,
        pacified_aut = pacified,
        severed = false,
        anchor_x = state.x,
        anchor_y = state.y,
    })

    -- Source monster portals have a non-actor summoner. Their tentacle
    -- persists after that caster dies; its lifecycle is self-owned here.
    local summon = ctx:get(head, component.SUMMON)

    summon.owner = head
    ctx:set(head, component.SUMMON, summon)

    return head
end

-- Closing the portal changes allegiance and starts the source's 20 HP
-- severed decay. Anchor drift happens on the head's next action, because
-- mon-tentacle.cc changes BASE_POSITION during movement, not timer aging.
function portal.tick(ctx, head, aut)
    local state = ctx:get(head, constructs.PORTAL)
    local summon = ctx:get(head, component.SUMMON)

    -- Player heads use the same persistent anchor but expire through their
    -- ordinary summon timer. Only monster heads use this source lifetime.
    if summon.owner == ctx:player() then
        return
    end

    local marker

    for _, entity in ipairs(ctx:query({ component.SUMMON_GATEWAY })) do
        local gateway = ctx:get(entity, component.SUMMON_GATEWAY)

        if gateway.tentacle_id == ctx:id(head) then
            marker = gateway
            break
        end
    end

    if state.severed then
        health.damage(ctx, head, 20)

        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)
    state.pacified_aut = math.max(0, state.pacified_aut - aut)

    if state.remaining_aut == 0 then
        state.severed = true
        summon.attitude = attitudes.NEUTRAL

        if marker and ctx:cell(marker.level_id, marker.x, marker.y) ==
            terrain.DNGN_MALIGN_GATEWAY then
            ctx:set_cell(marker.level_id, marker.x, marker.y, terrain.DNGN_FLOOR)
        end

        ctx:emit("spell", "The portal closes; the tentacle is severed.")
    elseif state.pacified_aut == 0 and summon.attitude == attitudes.FRIENDLY then
        summon.attitude = attitudes.HOSTILE
        ctx:emit("spell", "The eldritch tentacle becomes enraged!")
    end

    ctx:set(head, component.SUMMON, summon)
    ctx:set(head, constructs.PORTAL, state)
end

return portal
