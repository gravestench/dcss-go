-- Theory of operation: Sporulate creates a short-lived autonomous actor.
-- Its normal turn approaches a saved foe, while contact, lethal damage,
-- and lifetime expiry all converge on one guarded radius-one explosion.
-- Source: mon-cast.cc:SPELL_SPORULATE and mon-explode.cc.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local habitat = require("policy.combat.monster_habitat")
local intent = require("constants.intent")
local monsters = require("ids.monsters")
local monster_stats = require("policy.combat.monster_stats")
local blast = require("policy.magic.effects.summons.blast")
local confusion = require("policy.magic.player_confusion")
local holiness = require("policy.character.holiness")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local targets = require("policy.ai.targets")

local spore = {}
local SHORT_LIFE_AUT = 60

-- The source permits placement in any adjacent cell that the spore can
-- inhabit. The summon owner later chooses its starting cell with RNG.
function spore.can_spawn(ctx, caster)
    local position = ctx:get(caster, component.POSITION)

    if not position then
        return false
    end

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = position.x + dx
                local y = position.y + dy

                if habitat.kind_at(ctx,
                    monsters.MONS_BALLISTOMYCETE_SPORE,
                    position.level_id, x, y) and
                    not ctx:actor_at(position.level_id, x, y) then
                    return true
                end
            end
        end
    end

    return false
end

-- Effective spell HD adds only the caster's magic bonus above its natural
-- HD. The catalog's spore HD remains the baseline for explosion damage.
function spore.spawn(ctx, caster, foe)
    if not foe or not targets.enemy(ctx, caster, foe) or
        not spore.can_spawn(ctx, caster) then
        return nil
    end

    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local source_hd = monster_stats.hit_dice(ctx, caster, definition)
    local spell_hd = monster_stats.spell_hit_dice(ctx, caster, definition)
    local profile = catalog.get(categories.MONSTERS,
        monsters.MONS_BALLISTOMYCETE_SPORE)
    local hd = profile.hd + math.max(0, spell_hd - source_hd)
    local summoned = summons.spawn(ctx, caster, spells.SPELL_SPORULATE,
        monsters.MONS_BALLISTOMYCETE_SPORE, 0, nil, {
            hd = hd,
            expires_aut = ctx:aut() + SHORT_LIFE_AUT,
        })

    if summoned then
        ctx:add(summoned, component.MONSTER_SPORE, {
            target = foe,
            exploded = false,
        })
    end

    return summoned
end

-- Record detonation before dealing damage, since another spore in the
-- blast may die and trigger nested death processing on the same turn.
-- Source BEAM_SPORE confuses a breathing, living player only after
-- positive damage has passed through their defenses.
local function after_spore_hit(ctx, victim)
    if victim == ctx:player() and holiness.natural(ctx, victim) then
        confusion.extend(ctx, victim,
            2 + ctx:random(streams.MONSTER_SPELL, 3))
    end
end

-- Mark one detonation before rolling damage, so chained explosions cannot
-- trigger a second blast from the same saved actor.
function spore.explode(ctx, entity)
    local state = ctx:get(entity, component.MONSTER_SPORE)

    if not state or state.exploded then
        return false
    end

    state.exploded = true
    ctx:set(entity, component.MONSTER_SPORE, state)

    local stats = ctx:get(entity, component.SUMMON_STATS)
    local profile = catalog.get(categories.MONSTERS,
        monsters.MONS_BALLISTOMYCETE_SPORE)
    local hd = stats and stats.hd or profile.hd

    ctx:emit("combat", "The spore explodes!")
    blast.area(ctx, entity, 1, 3, 5 + hd, nil, after_spore_hit)
    summons.expire(ctx, entity)

    return true
end

-- Spores pursue the selected foe but never choose an unrelated target.
-- Contact detonates them before generic melee can spend a separate attack.
function spore.act(ctx, entity)
    local state = ctx:get(entity, component.MONSTER_SPORE)
    local position = ctx:get(entity, component.POSITION)
    local victim = state and ctx:get(state.target, component.POSITION)
    local health = state and ctx:get(state.target, component.HEALTH)

    if not state or not position or not victim or not health or
        health.current <= 0 or victim.level_id ~= position.level_id or
        not targets.enemy(ctx, entity, state.target) then
        return { kind = intent.MONSTER_WAIT }
    end

    local distance = math.max(math.abs(victim.x - position.x),
        math.abs(victim.y - position.y))

    if distance <= 1 then
        spore.explode(ctx, entity)

        return nil
    end

    local dx, dy, found = ctx:route_step(position.level_id,
        position.x, position.y, victim.x, victim.y, state.target)

    if found and ctx:walkable(position.level_id,
        position.x + dx, position.y + dy) and
        not ctx:actor_at(position.level_id,
            position.x + dx, position.y + dy) then
        return {
            kind = intent.MONSTER_MOVE,
            dx = dx,
            dy = dy,
        }
    end

    return { kind = intent.MONSTER_WAIT }
end

return spore
