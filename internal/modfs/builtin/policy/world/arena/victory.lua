-- The authored B wall seals the exit corridor. A marked opponent's final
-- death opens it; Bennu revival and slime descendants keep the mark live.
local component = require("constants.component")
local cloud = require("policy.clouds.placement")
local death_hooks = require("policy.combat.death_hooks")
local clouds = require("ids.clouds")
local okawaru = require("constants.okawaru")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local victory = {}

-- Death hooks run after the dead actor has left grid occupancy. Earlier
-- revival hooks can create a marked successor before we count survivors.
-- A banished challenger uses this same exit rule after its mark is cleared.
local function finish_if_last(ctx, monster, position)
    local mark = ctx:get(monster, component.MONSTER_ARENA_DUEL)
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_ARENA_VISIT)

    if not mark or not visit or visit.victory or
        position.level_id ~= visit.level_id then
        return false
    end

    for _, other in ipairs(ctx:query({
        component.MONSTER_ARENA_DUEL,
        component.HEALTH,
        component.POSITION,
    })) do
        if other ~= monster then
            local state = ctx:get(other, component.MONSTER_ARENA_DUEL)
            local health = ctx:get(other, component.HEALTH)
            local site = ctx:get(other, component.POSITION)

            if state.current and health.current > 0 and
                site.level_id == visit.level_id then
                return false
            end
        end
    end

    if ctx:cell(visit.level_id, visit.target_x, visit.target_y) ~=
        terrain.DNGN_CLEAR_PERMAROCK_WALL then
        error("Arena victory barrier changed before the final death")
    end

    ctx:set_cell(visit.level_id, visit.target_x,
        visit.target_y, terrain.DNGN_FLOOR)
    -- The DES victory hook places two turns of harmless dust where its
    -- sealed B tile was. The cloud owner saves and ages that effect.
    cloud.place(ctx, clouds.CLOUD_DUST, player,
        visit.level_id, visit.target_x, visit.target_y, 20)
    visit.victory = true
    visit.return_aut = (okawaru.DUEL_RETURN_MIN_TURNS +
        ctx:random(streams.RELIGION,
            okawaru.DUEL_RETURN_SPAN_TURNS)) * 10
    ctx:set(player, component.PLAYER_ARENA_VISIT, visit)
    ctx:emit("religion", "Okawaru crowns you victorious!")
    ctx:emit("notice", "An exit appears.")

    return false
end

-- Banishment removes a living opponent from the Arena without a death
-- event. Release its current mark before checking whether B can open.
-- Its Abyss return site belongs to the outside floor, which survives
-- retirement of the temporary Arena level.
function victory.on_departure(ctx, monster, position)
    local mark = ctx:get(monster, component.MONSTER_ARENA_DUEL)

    if not mark or not mark.current then
        return nil
    end

    local visit = ctx:get(ctx:player(), component.PLAYER_ARENA_VISIT)

    if not visit or position.level_id ~= visit.level_id then
        error("Arena challenger departed without an active Duel")
    end

    mark.current = false
    mark.abandoned = true
    ctx:set(monster, component.MONSTER_ARENA_DUEL, mark)
    finish_if_last(ctx, monster, position)

    return {
        level_id = visit.origin_level_id,
        x = visit.origin_x,
        y = visit.origin_y,
    }
end

-- The shared death dispatcher calls this after Bennu and slime lineage
-- hooks have had their chance to put a living challenger on the floor.
function victory.on_death(ctx, monster, _, position)
    local mark = ctx:get(monster, component.MONSTER_ARENA_DUEL)

    if not mark or not mark.current then
        return false
    end

    return finish_if_last(ctx, monster, position)
end

-- Source gives a victor 15–25 turns to use the exit. Once the clock
-- expires, the generic post-action portal forces the same safe return.
function victory.tick(ctx, player, aut)
    local visit = ctx:get(player, component.PLAYER_ARENA_VISIT)

    if not visit or not visit.victory or aut <= 0 then
        return
    end

    visit.return_aut = math.max(0, visit.return_aut - aut)
    ctx:set(player, component.PLAYER_ARENA_VISIT, visit)
end

death_hooks.add("religion.okawaru.duel_victory", victory.on_death)

return victory
