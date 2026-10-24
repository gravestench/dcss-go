-- The phial fires a short water ray, pushes its first victim, and leaves a
-- temporary shallow-water splash at impact. The splash can waterlog a
-- breathing monster even when its center tile could not become water.
local catalog = require("policy.catalog")
local accuracy = require("policy.character.accuracy")
local attack_conduct = require("policy.religion.conduct.attack")
local component = require("constants.component")
local defense = require("policy.combat.monster_defense")
local displacement = require("policy.combat.monster_beams.displacement")
local drowning = require("policy.combat.monster_beams.water")
local effects = require("policy.inventory.evokers.effects")
local explosion = require("policy.combat.explosion")
local items = require("ids.items")
local noise = require("policy.world.noise")
local power = require("policy.magic.power")
local roll = require("policy.combat.roll")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local temporary = require("policy.world.temporary_terrain")
local terrain = require("constants.terrain")
local trajectory = require("policy.combat.trajectory")
local damage = require("policy.magic.damage")

local phial = {}
local RANGE = 7

-- An aimed ray can miss a quick target or meet its shield. The source
-- primal-wave zap starts at 10 accuracy and adds one per 25 power.
local function strikes(ctx, player, monster, definition, strength)
    local to_hit = accuracy.zap_to_hit(ctx, player,
        10 + math.floor(strength / 25))
    local shield = defense.shield(ctx, monster, definition)

    if shield and defense.beam_block(ctx, shield, to_hit) then
        defense.register_block(ctx, monster)

        return false
    end

    local evasion = defense.evasion(ctx, monster, definition)
    local random_ev = evasion > 1 and
        ctx:random(streams.EVOKER, evasion) or 0
    local attack = to_hit > 1 and
        ctx:random(streams.EVOKER, to_hit) or 0
    local first = random_ev > 1 and
        ctx:random(streams.EVOKER, random_ev) or 0
    local second = ctx:random(streams.EVOKER, random_ev + 1)

    return attack >= math.floor((first + second) / 2)
end

-- The source targeter accepts a direction or a visible distant cell.
-- Reject a zero vector and off-map aim before the turn can begin.
function phial.prepare(ctx, player, dx, dy)
    local origin = ctx:get(player, component.POSITION)
    local x, y = origin.x + dx, origin.y + dy

    if dx == 0 and dy == 0 or
        math.max(math.abs(dx), math.abs(dy)) > RANGE or
        not ctx:cell(origin.level_id, x, y) then
        return "There's something in the way."
    end
end

-- Source calc_dice divides the ray's maximum damage among four dice,
-- randomly rounding the die size when that division has a remainder.
local function water_damage(ctx, strength)
    local maximum = 14 + math.floor(strength * 3 / 5)
    local size = math.floor(maximum / 4)
    local remainder = maximum % 4

    if remainder > 0 and
        ctx:random(streams.EVOKER, 4) < remainder then
        size = size + 1
    end

    local rolled = 0

    for _ = 1, 4 do
        rolled = rolled + 1 + ctx:random(streams.EVOKER, size)
    end

    return rolled
end

-- Extend the distinct saved status, which the monster spell chooser uses
-- as a vocal restriction until its active-floor timer expires.
local function waterlog(ctx, monster, duration)
    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local current = ctx:get(monster, component.MONSTER_WATERLOGGED)
    local remaining = math.max(current and current.remaining_aut or 0,
        duration)
    local next_state = { remaining_aut = remaining }

    if current then
        ctx:set(monster, component.MONSTER_WATERLOGGED, next_state)
    else
        ctx:add(monster, component.MONSTER_WATERLOGGED, next_state)
    end

    ctx:emit("evoke", "The " .. definition.name ..
        " is engulfed in water.")
end

-- Each candidate pool records its original feature with the shared
-- temporary terrain owner; expiration restores it after save/load too.
local function splash(ctx, player, endpoint, strength)
    local count = 3 + roll.random_divide(ctx,
        strength * 3, 20, streams.EVOKER) +
        ctx:random(streams.EVOKER, 7)
    local duration = roll.random_divide(ctx,
        strength * 4, 3, streams.EVOKER) + 66
    local cells = explosion.cells(ctx, endpoint.level_id,
        endpoint.x, endpoint.y, 2)
    local wet = {
        [endpoint.x .. ":" .. endpoint.y] = endpoint,
    }

    local placed = 0

    for _, cell in ipairs(cells) do
        if placed >= count then
            break
        end

        local feature = ctx:cell(endpoint.level_id, cell.x, cell.y)

        if (feature == terrain.DNGN_FLOOR or
            feature == terrain.DNGN_SHALLOW_WATER) and
            ctx:visible_no_trans(endpoint.level_id,
                endpoint.x, endpoint.y, 2,
                cell.x, cell.y) then
            local distance = math.max(math.abs(cell.x - endpoint.x),
                math.abs(cell.y - endpoint.y))
            local lifetime = duration +
                ctx:random(streams.EVOKER,
                    math.floor(duration / 2) + 1) -
                20 * distance
            temporary.place(ctx, player,
                items.MISC_PHIAL_OF_FLOODS, endpoint.level_id,
                cell.x, cell.y, terrain.DNGN_SHALLOW_WATER,
                math.max(1, lifetime))

            -- Source counts an eligible square even if it was already
            -- shallow water or has a different temporary terrain mark.
            wet[cell.x .. ":" .. cell.y] = cell
            placed = placed + 1
        end
    end

    local keys = {}

    for key in pairs(wet) do
        keys[#keys + 1] = key
    end

    table.sort(keys)

    for _, key in ipairs(keys) do
        local cell = wet[key]
        local monster = ctx:actor_at(endpoint.level_id,
            cell.x, cell.y)
        if monster and monster ~= player and
            ctx:get(monster, component.ACTOR) then
            if not drowning.immune(ctx, monster) then
                local distance = math.max(math.abs(cell.x - endpoint.x),
                    math.abs(cell.y - endpoint.y))
                local lifetime = duration +
                    ctx:random(streams.EVOKER,
                        math.floor(duration / 2) + 1) -
                    20 * distance

                waterlog(ctx, monster, math.max(1, lifetime))
            end
        end
    end
end

-- Resolve the beam's first contact, then make its endpoint splash.
-- Water and noise occur even when the beam crosses empty space.
function phial.resolve(ctx, player, chosen)
    local origin = ctx:get(player, component.POSITION)
    local strength = 10 + power.training(ctx, player,
        skills.SK_EVOCATIONS, 4)
    local ray = trajectory.to_target(ctx, origin.level_id,
        origin.x, origin.y, origin.x + chosen.dx,
        origin.y + chosen.dy, RANGE)
    local contact = ray.contacts[1]
    local endpoint = {
        level_id = origin.level_id,
        x = contact and contact.x or ray.x,
        y = contact and contact.y or ray.y,
    }

    ctx:emit("evoke", "A torrent of water bursts from the phial!")

    if contact then
        local monster = contact.actor
        local actor = ctx:get(monster, component.ACTOR)

        if actor then
            local definition = catalog.get("monsters", actor.kind_id)
            local raw = water_damage(ctx, strength)

            attack_conduct.report(ctx, monster, definition)

            if strikes(ctx, player, monster, definition, strength) then
                local ac = defense.armour(ctx, monster, definition)
                local dealt = math.max(0, raw -
                    ctx:random(streams.EVOKER, ac + 1))

                -- Water resistance prevents only the asphyxiating 40
                -- percent; the remaining impact is still physical.
                dealt = drowning.damage(ctx, monster, dealt)

                damage.apply(ctx, monster, dealt, player)

                if ctx:get(monster, component.HEALTH).current > 0 then
                    displacement.wave(ctx, player, monster, origin)
                end
            end
        end
    end

    splash(ctx, player, endpoint, strength)
    noise.emit(ctx, endpoint, 6, player)
    ctx:emit("evoke", "The wave splashes down.")

    return {
        charge = true,
        practice = 3,
    }
end

effects.add(items.MISC_PHIAL_OF_FLOODS, phial)

return phial
