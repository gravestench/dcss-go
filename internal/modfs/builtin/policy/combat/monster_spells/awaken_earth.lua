-- Awaken Earth picks a visible wall near the foe, destroys nearby rock,
-- then tries to replace each destroyed wall with a two-degree elemental.
-- Source: mon-cast.cc:_mons_awaken_earth_target/_mons_awaken_earth.
local component = require("constants.component")
local monsters = require("ids.monsters")
local roll = require("policy.combat.roll")
local senses = require("policy.character.senses")
local strength = require("policy.combat.monster_summons.strength")
local summons = require("policy.magic.effects.summons.common")
local noise = require("policy.world.noise")
local spells = require("ids.spells")
local target_kind = require("constants.target_kind")
local terrain = require("constants.terrain")

local effect = {}
local SIGHT = 7
local offsets = {
    { -1, -1 }, { -1, 0 }, { -1, 1 },
    { 0, -1 },             { 0, 1 },
    { 1, -1 },  { 1, 0 },  { 1, 1 },
}

local function awakenable(feature)
    return feature == terrain.DNGN_ROCK_WALL or
        feature == terrain.DNGN_CLEAR_ROCK_WALL
end

local function adjacent_count(ctx, level_id, x, y)
    local count = 0

    for _, offset in ipairs(offsets) do
        if awakenable(ctx:cell(level_id, x + offset[1], y + offset[2])) then
            count = count + 1
        end
    end

    return count
end

local function plan_cell(source, x, y)
    return {
        kind = target_kind.CELL,
        level_id = source.level_id,
        x = x,
        y = y,
        dx = x - source.x,
        dy = y - source.y,
    }
end

-- The source first uses the visible foe's square if a rock wall touches it.
-- Fallback scans the caster-to-foe line and weights cells by wall count squared.
function effect.plan(ctx, caster, foe)
    local source = ctx:get(caster, component.POSITION)
    local destination = foe and ctx:get(foe, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id then
        return nil
    end

    if ctx:visible(source.level_id, source.x, source.y,
        SIGHT, destination.x, destination.y) and
        adjacent_count(ctx, source.level_id,
            destination.x, destination.y) > 0 then
        return plan_cell(source, destination.x, destination.y)
    end

    local candidates = {}
    local seen = {}
    local steps = math.max(math.abs(destination.x - source.x),
        math.abs(destination.y - source.y))

    for step = 0, steps - 1 do
        local x = math.floor(destination.x +
            (source.x - destination.x) * step / steps + 0.5)
        local y = math.floor(destination.y +
            (source.y - destination.y) * step / steps + 0.5)

        if ctx:visible(source.level_id, source.x, source.y, SIGHT, x, y) then
            for _, offset in ipairs(offsets) do
                local cx = x + offset[1]
                local cy = y + offset[2]
                local key = cx .. ":" .. cy

                if not seen[key] and ctx:cell(source.level_id, cx, cy) then
                    seen[key] = true
                    local n = adjacent_count(ctx, source.level_id, cx, cy)

                    if awakenable(ctx:cell(source.level_id, cx, cy)) then
                        n = n + 1
                    end

                    if n > 0 then
                        candidates[#candidates + 1] = {
                            x = cx,
                            y = cy,
                            weight = n * n,
                        }
                    end
                end
            end
        end
    end

    local total = 0

    for _, candidate in ipairs(candidates) do
        total = total + candidate.weight
    end

    if total == 0 then
        return nil
    end

    local chosen = roll.spell(ctx, total)

    for _, candidate in ipairs(candidates) do
        chosen = chosen - candidate.weight

        if chosen < 0 then
            return plan_cell(source, candidate.x, candidate.y)
        end
    end
end

-- A failed summon still leaves the wall destroyed; only successful summons
-- count toward the HD-based limit. This preserves source failure behavior.
function effect.resolve(ctx, caster, _, _, plan)
    if not plan or plan.kind ~= target_kind.CELL or
        not ctx:cell(plan.level_id, plan.x, plan.y) then
        return
    end

    local hd = strength.spell_hd(ctx, caster)
    local limit = 1 + (hd > 15 and 1 or 0) +
        roll.spell(ctx, math.floor(hd / 7) + 1)
    local count = 0
    local changed = 0
    local seen = false

    local function awaken(x, y)
        if awakenable(ctx:cell(plan.level_id, x, y)) then
            ctx:set_cell(plan.level_id, x, y, terrain.DNGN_FLOOR)
            changed = changed + 1
            seen = seen or senses.player_sees_cell(ctx, {
                level_id = plan.level_id,
                x = x,
                y = y,
            })

            local spawned = summons.spawn(ctx, caster,
                spells.SPELL_AWAKEN_EARTH,
                monsters.MONS_EARTH_ELEMENTAL, 2, nil, {
                    anchor = plan,
                    exact = { x = x, y = y },
                })

            if spawned then
                count = count + 1
            end
        end

        return count >= limit
    end

    -- fair_adjacent_iterator(target, false) visits its center first. It
    -- draws the neighbour angle only if the center did not meet the cap.
    if not awaken(plan.x, plan.y) then
        local first = roll.spell(ctx, #offsets) + 1

        for index = 0, #offsets - 1 do
            local offset = offsets[(first + index - 1) % #offsets + 1]

            if awaken(plan.x + offset[1], plan.y + offset[2]) then
                break
            end
        end
    end

    local _, heard = noise.emit(ctx, plan, 20, caster)

    if seen then
        ctx:emit("monster_spell", count > 0 and
            "Some walls begin to move on their own!" or
            "Some walls crumble away!")
    elseif heard then
        ctx:emit("monster_spell", "You hear rumbling.")
    end

    if changed == 0 and senses.player_sees_actor(ctx, caster) then
        ctx:emit("monster_spell", "Nothing happens.")
    end
end

return effect
