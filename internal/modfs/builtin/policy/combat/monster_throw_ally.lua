-- Robin, Polyphemus, and the Iron Giant throw an adjacent ally into an
-- open cell beside their foe. Source: mon-cast.cc:_maybe_throw_ally.
local catalog = require("policy.catalog")
local component = require("constants.component")
local defense = require("policy.combat.monster_defense")
local display = require("policy.combat.monster_support.display")
local fighter = require("policy.combat.fighter")
local flags = require("constants.monster_flags")
local habitat = require("policy.combat.monster_habitat")
local monster_health = require("policy.combat.monster_health")
local monsters = require("ids.monsters")
local player_health = require("policy.combat.player_health")
local relocation = require("policy.world.monster_relocation")
local stasis = require("policy.magic.effects.statuses.monster_stasis")
local stats = require("policy.combat.monster_stats")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local traps = require("policy.traps.activation")

local throwing = {}
local SIGHT = 7

-- A throw is permitted by the caster species, not by the ally's spellbook.
local function allowed(thrower_id, ally)
    if thrower_id == monsters.MONS_ROBIN then
        return ally.species_id == monsters.MONS_GOBLIN
    end

    if thrower_id == monsters.MONS_POLYPHEMUS then
        return ally.genus_id == monsters.MONS_YAK
    end

    if thrower_id == monsters.MONS_IRON_GIANT then
        for _, flag in ipairs(ally.flags or {}) do
            if flag == flags.CONJURED then
                return false
            end
        end

        return true
    end

    return false
end

-- The source's fair adjacent scan chooses the eligible ally farthest from
-- the foe. Ties use stable actor order and a named spell draw.
local function ally_to_throw(ctx, caster, foe)
    local source = ctx:get(caster, component.POSITION)
    local target = ctx:get(foe, component.POSITION)
    local actor = ctx:get(caster, component.ACTOR)

    if not source or not target or not actor or
        source.level_id ~= target.level_id then
        return nil
    end

    local furthest = -1
    local choices = {}

    for _, ally in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if ally ~= caster and ally ~= foe and
            targets.aligned(ctx, caster, ally) and
            not ctx:has(ally, component.CONSTRICTION) and
            not ctx:has(ally, component.PLAYER_CONSTRICTION) then
            local position = ctx:get(ally, component.POSITION)
            local health = ctx:get(ally, component.HEALTH)
            local definition = catalog.get("monsters",
                ctx:get(ally, component.ACTOR).kind_id)
            local adjacent = position.level_id == source.level_id and
                math.max(math.abs(position.x - source.x),
                    math.abs(position.y - source.y)) == 1

            if adjacent and health.current > 0 and
                allowed(actor.kind_id, definition) then
                local distance = math.max(math.abs(position.x - target.x),
                    math.abs(position.y - target.y))

                if distance > furthest then
                    furthest = distance
                    choices = { ally }
                elseif distance == furthest then
                    choices[#choices + 1] = ally
                end
            end
        end
    end

    return choices
end

-- A landing must be visible from the thrower, empty, habitable, adjacent
-- to the foe, and at least two cells from the thrower's starting cell.
local function landing(ctx, caster, ally, foe)
    local source = ctx:get(caster, component.POSITION)
    local target = ctx:get(foe, component.POSITION)
    local best = -1
    local cells = {}

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = target.x + dx
                local y = target.y + dy
                local distance = math.max(math.abs(x - source.x),
                    math.abs(y - source.y))

                if distance >= 2 and distance <= SIGHT and
                    not ctx:actor_at(source.level_id, x, y) and
                    habitat.at(ctx, ally, source.level_id, x, y) and
                    ctx:visible_no_trans(source.level_id,
                        source.x, source.y, SIGHT, x, y) then
                    if distance > best then
                        best = distance
                        cells = {
                            { x = x, y = y },
                        }
                    elseif distance == best then
                        cells[#cells + 1] = {
                            x = x,
                            y = y,
                        }
                    end
                end
            end
        end
    end

    return cells
end

-- A tied ally is only a cast candidate if its own habitat permits a
-- landing. Otherwise a useful plan could randomly turn into a no-op.
local function throwable(ctx, caster, foe)
    local choices = {}

    for _, ally in ipairs(ally_to_throw(ctx, caster, foe) or {}) do
        local cells = landing(ctx, caster, ally, foe)

        if #cells > 0 then
            choices[#choices + 1] = {
                ally = ally,
                cells = cells,
            }
        end
    end

    return choices
end

-- Planning is read only: a useful cast has at least one eligible adjacent
-- ally and one legal landing. The actual ally and cell are chosen on cast.
function throwing.possible(ctx, caster, foe)
    if not foe or not targets.enemy(ctx, caster, foe) then
        return false
    end

    return #throwable(ctx, caster, foe) > 0
end

-- The thrower's HD sets raw impact. Armour is rolled after the ally lands,
-- and the ordinary health owner applies the resulting damage.
local function impact(ctx, caster, foe)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local hd = stats.hit_dice(ctx, caster, definition)
    local raw = ctx:random(streams.MONSTER_SPELL, hd * 2)
    local ac

    if ctx:has(foe, component.PLAYER) then
        ac = fighter.defense(ctx).ac
    else
        local target = ctx:get(foe, component.ACTOR)
        local target_def = catalog.get("monsters", target.kind_id)

        ac = defense.armour(ctx, foe, target_def)
    end

    local damage = math.max(0,
        raw - ctx:random(streams.MONSTER_SPELL, ac + 1))

    if damage > 0 then
        if ctx:has(foe, component.PLAYER) then
            player_health.damage(ctx, foe, damage, false, caster)
        else
            monster_health.damage(ctx, foe, damage, caster)
        end
    end
end

-- Reselect after the cast is committed because a moved or dead ally can no
-- longer be thrown. The landing itself is picked among best-scoring cells.
function throwing.resolve(ctx, caster, foe)
    local choices = throwable(ctx, caster, foe)

    if #choices == 0 then
        return false
    end

    local choice = choices[ctx:random(streams.MONSTER_SPELL,
        #choices) + 1]
    local ally = choice.ally
    local cells = choice.cells

    local chosen = cells[ctx:random(streams.MONSTER_SPELL,
        #cells) + 1]
    local origin = ctx:get(ally, component.POSITION)

    ctx:emit("combat", "The " .. display.name(ctx, caster) ..
        " throws the " .. display.name(ctx, ally) .. "!")
    relocation.move(ctx, ally, origin.level_id,
        chosen.x, chosen.y)
    traps.enter(ctx, ally, origin, ctx:get(ally, component.POSITION))
    impact(ctx, caster, foe)
    stasis.wake_hibernating(ctx, ally)

    return true
end

return throwing
