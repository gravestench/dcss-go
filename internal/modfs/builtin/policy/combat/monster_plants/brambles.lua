-- Theory of operation: a thorn hunter creates a temporary arc of real
-- briar actors. The terrain grid remains open; the summoned actors block
-- movement and their ordinary summon timers remove them after expiry.
-- Source: mon-cast.cc:_wall_of_brambles.
local component = require("constants.component")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local direct = require("policy.combat.monster_direct")
local fighter = require("policy.combat.fighter")
local habitat = require("policy.combat.monster_habitat")
local monster_defense = require("policy.combat.monster_defense")
local foe_motion = require("policy.ai.foe_motion")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local targets = require("policy.ai.targets")
local target = require("policy.combat.monster_spell_target")
local target_kind = require("constants.target_kind")

local brambles = {}
local MIN_DEFENSIVE_RADIUS = 3
local MAX_DEFENSIVE_RADIUS = 5

-- Source M_SPINY retaliates against a physical attack even if the attack
-- later misses. A shield block prevents contact, and thorn hunters are
-- immune to their own brambles. Only the first monster strike can trigger.
function brambles.thorns(ctx, attacker, defender, blocked)
    local briar = ctx:get(defender, component.ACTOR)
    local aggressor = ctx:get(attacker, component.ACTOR)
    local health = ctx:get(attacker, component.HEALTH)

    if not briar or briar.kind_id ~= monsters.MONS_BRIAR_PATCH or
        not health or health.current <= 0 or blocked or
        not targets.enemy(ctx, defender, attacker) or
        (aggressor and aggressor.kind_id == monsters.MONS_THORN_HUNTER) or
        (aggressor and aggressor.kind_id == monsters.MONS_PLAYER_SHADOW) then
        return false
    end

    if ctx:random(streams.MELEE, 3) ~= 0 then
        return false
    end

    local raw = 0

    for _ = 1, 5 do
        raw = raw + 1 + ctx:random(streams.MELEE, 4)
    end

    local ac

    if attacker == ctx:player() then
        ac = fighter.defense(ctx).ac
    else
        local definition = catalog.get(categories.MONSTERS,
            aggressor.kind_id)

        ac = monster_defense.armour(ctx, attacker, definition)
    end

    local amount = math.max(0, raw - ctx:random(streams.MELEE, ac + 1))

    if amount == 0 then
        return false
    end

    direct.damage(ctx, defender, attacker, amount)
    ctx:emit("combat", "The briar patch's thorns strike back!")

    return true
end

-- Source uses square grid distance for its discrete circular arcs.
local function distance(left, right)
    return math.max(math.abs(left.x - right.x),
        math.abs(left.y - right.y))
end

-- A defensive arc stands between close combatants. A distant foe gets
-- an arc beyond its position, limiting its escape route.
-- Move the defensive circle away from the foe before choosing the arc
-- facing back toward it, matching the source's uneven wall placement.
local function center(origin, foe, radius, guard)
    if not guard then
        return origin
    end

    local steps = 1

    if radius == MAX_DEFENSIVE_RADIUS then
        steps = steps + 1
    end

    if distance(origin, foe) == 2 then
        steps = steps + 1
    end

    local dx = origin.x > foe.x and 1 or origin.x < foe.x and -1 or 0
    local dy = origin.y > foe.y and 1 or origin.y < foe.y and -1 or 0

    return {
        x = origin.x + dx * steps,
        y = origin.y + dy * steps,
        level_id = origin.level_id,
    }
end

-- Test the arc cone by dot product; this avoids angle wraparound at the
-- negative axis and does not spend a spell RNG draw during preflight.
local function inside_cone(middle, foe, x, y, radius, guard)
    local ax = foe.x - middle.x
    local ay = foe.y - middle.y
    local bx = x - middle.x
    local by = y - middle.y
    local dot = ax * bx + ay * by

    if dot <= 0 then
        return false
    end

    local limit = guard and math.pi / 4 or
        math.pi / (4.2 + radius / 6)
    local a_length = math.sqrt(ax * ax + ay * ay)
    local b_length = math.sqrt(bx * bx + by * by)

    return dot >= a_length * b_length * math.cos(limit)
end

-- The source avoids piling a second distant wall in the same corridor.
-- Sample the straight ray beyond the foe for two live briar patches.
local function existing_wall(ctx, origin, foe)
    local dx = foe.x - origin.x
    local dy = foe.y - origin.y
    local steps = distance(origin, foe)
    local count = 0

    if steps == 0 then
        return false
    end

    for index = steps, 12 do
        local x = origin.x + math.floor(dx * index / steps + 0.5)
        local y = origin.y + math.floor(dy * index / steps + 0.5)
        local occupant = ctx:actor_at(origin.level_id, x, y)
        local actor = occupant and ctx:get(occupant, component.ACTOR)

        if actor and actor.kind_id == monsters.MONS_BRIAR_PATCH then
            count = count + 1

            if count > 1 then
                return true
            end
        end
    end

    return false
end

-- Return actual open arc cells, rather than a drawing that later has to
-- be interpreted again by the grid. Each cell will hold one summoned actor.
local function arc(ctx, origin, foe, radius, guard)
    local middle = center(origin, foe, radius, guard)
    local points = {}

    for y = middle.y - radius, middle.y + radius do
        for x = middle.x - radius, middle.x + radius do
            local shell = math.max(math.abs(x - middle.x),
                math.abs(y - middle.y))

            if (shell == radius or shell == radius - 1) and
                inside_cone(middle, foe, x, y, radius, guard) and
                habitat.kind_at(ctx, monsters.MONS_BRIAR_PATCH,
                    origin.level_id, x, y) and
                not ctx:actor_at(origin.level_id, x, y) then
                points[#points + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return points
end

-- Planning checks all possible defensive radii without RNG. This keeps
-- an impossible wall out of the monster's action selection altogether.
function brambles.plan(ctx, caster, foe)
    local origin = ctx:get(caster, component.POSITION)
    local victim = foe and ctx:get(foe, component.POSITION)

    if not origin or not victim or origin.level_id ~= victim.level_id or
        not targets.enemy(ctx, caster, foe) then
        return nil
    end

    local guard = foe_motion.approaching(ctx, caster, foe)

    if guard and distance(origin, victim) <= 1 then
        return nil
    end

    if not guard and existing_wall(ctx, origin, victim) then
        return nil
    end

    local radii = {}
    local first = guard and MIN_DEFENSIVE_RADIUS or
        math.min(11, distance(origin, victim) + 6)
    local last = guard and MAX_DEFENSIVE_RADIUS or first

    for radius = first, last do
        if #arc(ctx, origin, victim, radius, guard) > 0 then
            radii[#radii + 1] = radius
        end
    end

    if #radii == 0 then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- Resolve the saved foe and legal radius set; no new target may replace
-- the one the caster chose during planning.
function brambles.raise(ctx, caster, foe, plan)
    target.require_entity(plan, foe)

    local current = brambles.plan(ctx, caster, foe)

    if not current then
        return false
    end

    local origin = ctx:get(caster, component.POSITION)
    local victim = ctx:get(foe, component.POSITION)

    if not origin or not victim or origin.level_id ~= victim.level_id then
        return false
    end

    local guard = foe_motion.approaching(ctx, caster, foe)
    local first = guard and MIN_DEFENSIVE_RADIUS or
        math.min(11, distance(origin, victim) + 6)
    local last = guard and MAX_DEFENSIVE_RADIUS or first
    local choices = {}

    for radius = first, last do
        local points = arc(ctx, origin, victim, radius, guard)

        if #points > 0 then
            choices[#choices + 1] = points
        end
    end

    if #choices == 0 then
        return false
    end

    local choice = 1

    if #choices > 1 then
        choice = ctx:random(streams.MONSTER_SPELL, #choices) + 1
    end

    local points = choices[choice]
    local count = 0

    for _, point in ipairs(points) do
        local duration = 80 + ctx:random(streams.MONSTER_SPELL, 100)
        local briar = summons.spawn(ctx, caster,
            spells.SPELL_WALL_OF_BRAMBLES,
            monsters.MONS_BRIAR_PATCH, 0, nil, {
                exact = {
                    x = point.x,
                    y = point.y,
                },
                expires_aut = ctx:aut() + duration,
                passive = true,
            })

        if briar then
            count = count + 1
        end
    end

    if count > 0 then
        ctx:emit("spell", "Thorny briars emerge from the ground!")
    end

    return count > 0
end

return brambles
