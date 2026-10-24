-- The source's holy word reaches undead and demonic actors in solid-line
-- sight. This shared combat policy is also available to scrolls and gods;
-- TSO's blessing calls it at power 100 after changing the weapon.
local component = require("constants.component")
local damage = require("policy.magic.damage")
local solid_area = require("policy.combat.solid_area")
local holiness = require("policy.character.holiness")
local monster_holiness = require("constants.monster_holiness")
local player_health = require("policy.combat.player_health")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local word = {}

-- A holy word checks source undead_or_demonic, not the weapon brand's
-- extra holy-resistance exception for the profane servitor.
local function susceptible(definition)
    for _, kind in ipairs(definition.holiness or {}) do
        if kind == monster_holiness.UNDEAD or
            kind == monster_holiness.DEMONIC then
            return true
        end
    end

    return false
end

-- Keep the existing Enfeeble timers while adding the source 10-19 turn
-- daze. The status owner already advances and serializes this component.
local function daze(ctx, monster)
    local status = ctx:get(monster, component.MONSTER_ENFEEBLE)
    local existed = status ~= nil

    status = status or {
        weak_aut = 0,
        antimagic_aut = 0,
        blind_aut = 0,
        dazed_aut = 0,
    }
    status.dazed_aut = math.max(status.dazed_aut,
        (10 + ctx:random(streams.RELIGION, 10)) * 10)

    if existed then
        ctx:set(monster, component.MONSTER_ENFEEBLE, status)
    else
        ctx:add(monster, component.MONSTER_ENFEEBLE, status)
    end
end

-- Three dice and one power-scaled draw are rolled per susceptible monster,
-- matching holy_word_monsters rather than a weapon brand damage formula.
local function monster_damage(ctx, power)
    local rolled = 0

    for _ = 1, 3 do
        rolled = rolled + 1 + ctx:random(streams.RELIGION, 15)
    end

    return rolled + math.floor(ctx:random(streams.RELIGION,
        math.min(300, power)) / 5)
end

-- Holy word sees a live actor and its current location. Each affected
-- survivor is dazed only after damage has resolved through monster health.
local function affect_monsters(ctx, player, origin, power)
    for _, monster in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if monster ~= player then
            local position = ctx:get(monster, component.POSITION)
            local health = ctx:get(monster, component.HEALTH)
            local definition = damage.monster(ctx, monster)

            if health.current > 0 and
                position.level_id == origin.level_id and
                solid_area.contains(ctx, origin, position, 7) and
                susceptible(definition) then
                damage.apply(ctx, monster, monster_damage(ctx, power),
                    player)

                local remaining = ctx:get(monster, component.HEALTH)

                if remaining and remaining.current > 0 then
                    daze(ctx, monster)
                end
            end
        end
    end
end

-- The source also hits an undead or demonic player at the center. This
-- nonlethal half-current-HP loss uses the existing player damage owner.
local function affect_player(ctx, player)
    if not holiness.undead_or_demonic(ctx, player) then
        return
    end

    local health = ctx:get(player, component.HEALTH)
    local loss = math.max(0, math.floor(health.current / 2) - 1)

    if loss > 0 then
        player_health.damage(ctx, player, loss, false, player)
    end
end

-- Blood cleansing is a terrain mutation, independent of actor damage.
-- Only visible cells inside the source's three-cell square are changed.
local function cleanse(ctx, origin)
    for dy = -3, 3 do
        for dx = -3, 3 do
            local x = origin.x + dx
            local y = origin.y + dy
            local point = {
                level_id = origin.level_id,
                x = x,
                y = y,
            }

            if solid_area.contains(ctx, origin, point, 3) then
                if ctx:cell_blood(origin.level_id, x, y) then
                    ctx:set_cell_blood(origin.level_id, x, y, false)
                end

                if ctx:cell(origin.level_id, x, y) ==
                    terrain.DNGN_FOUNTAIN_BLOOD then
                    ctx:set_cell(origin.level_id, x, y,
                        terrain.DNGN_FOUNTAIN_BLUE)
                end
            end
        end
    end
end

-- TSO's invocation combines the combat blast and visual cleansing at one
-- commit point. Callers need no source-specific knowledge of the grid.
function word.apply(ctx, player, power)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        error("holy word source has no position")
    end

    affect_player(ctx, player)
    affect_monsters(ctx, player, origin, power)
    cleanse(ctx, origin)
end

return word
