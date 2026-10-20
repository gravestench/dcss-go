local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local intent_ids = require("constants.intent")
local blast = require("policy.magic.effects.summons.blast")
local roll = require("policy.combat.roll")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")
local streams = require("constants.rng_streams")
local senses = require("policy.character.senses")

local lightning = {}

-- The owner decides which saved RNG stream governs construct behavior.
local function stream_for(ctx, owner)
    return owner == ctx:player() and streams.SPELL or
        streams.MONSTER_SPELL
end

-- Source ball_lightning_hd divides power by six before subtracting six.
-- Monster-created balls then halve that result, unlike player-created ones.
local function hit_dice(ctx, owner, power)
    local base = math.max(1,
        roll.random_divide(ctx, power, 6, stream_for(ctx, owner)) - 6)

    if owner ~= ctx:player() then
        return math.floor(base / 2)
    end

    return base
end

-- Example: An uncharged ball lightning explodes once and records charge one to prevent a repeat blast.
-- Mark the construct charged before damage rolls so later actions cannot explode it twice.
function lightning.explode(ctx, entity, death_position)
    local state = ctx:get(entity, component.SUMMON_CONSTRUCT)

    if state.charge ~= 0 then
        return
    end

    state.charge = 1
    ctx:set(entity, component.SUMMON_CONSTRUCT, state)
    local summon = ctx:get(entity, component.SUMMON)
    local stats = ctx:get(entity, component.SUMMON_STATS)
    local hd = stats and stats.hd or
        math.max(1, math.floor(state.power / 6) - 6)

    -- monster::get_hit_dice clamps a raw zero-HD ball before the explosion
    -- reads it. Keep the raw roll in SUMMON_STATS for the saved actor.
    hd = math.max(1, hd)
    local stream = stream_for(ctx, summon.owner)
    local radius = roll.draw(ctx, stream, 24) < hd and 3 or 2
    local sides = 5 + math.floor(hd * 5 / 4)

    -- Source: mon-explode.cc:ball_lightning_damage and explosion radius.
    blast.area(ctx, entity, radius, 3, sides,
        "MR_RES_ELEC", nil, stream, death_position)

    if summon.owner == ctx:player() then
        ctx:emit("combat", "Your ball lightning explodes!")
    elseif senses.player_sees_actor(ctx, entity) then
        ctx:emit("combat", "The ball lightning explodes!")
    end
end

-- Explode only once within two cells of an enemy; the charge marker stops repeat blasts before expiry.
function lightning.act(ctx, entity, origin)
    if ctx:get(entity, component.SUMMON_CONSTRUCT).charge >= 1 then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    local target, distance = blast.nearest_hostile(ctx, entity,
        origin, 7)

    if target and distance <= 2 then
        lightning.explode(ctx, entity)
        blast.finish(ctx, entity, 1)

        return { kind = intent_ids.MONSTER_ABILITY, spell_id = spells.SPELL_CONJURE_BALL_LIGHTNING }
    end

    if target then
        local destination = ctx:get(target, component.POSITION)
        local dx, dy, found = ctx:route_step(origin.level_id,
            origin.x, origin.y, destination.x, destination.y, target)

        if found and ctx:walkable(origin.level_id,
            origin.x + dx, origin.y + dy) and
            not ctx:actor_at(origin.level_id,
                origin.x + dx, origin.y + dy) then
            return { kind = intent_ids.MONSTER_MOVE, dx = dx, dy = dy }
        end
    end

    return { kind = intent_ids.MONSTER_WAIT }
end

-- Both casters create three physical, short-lived balls. Player casting rolls
-- one HD for the group; monster casting rolls HD independently per ball.
function lightning.spawn(ctx, owner, power)
    local created = 0
    local hd = owner == ctx:player() and
        hit_dice(ctx, owner, power) or nil

    for _ = 1, 3 do
        local ball_hd = hd or hit_dice(ctx, owner, power)
        local creature = summons.spawn(ctx, owner,
            spells.SPELL_CONJURE_BALL_LIGHTNING, monsters.MONS_BALL_LIGHTNING, 0, 18, {
                expires_aut = ctx:aut() + 60,
                hd = ball_hd,
            })

        if creature then
            ctx:add(creature, component.SUMMON_CONSTRUCT, {
                power = power,
                charge = 0,
            })
            created = created + 1
        end
    end

    if created > 0 and owner == ctx:player() then
        ctx:emit("spell", "You create some ball lightning!")
    elseif created > 0 and senses.player_sees_actor(ctx, owner) then
        ctx:emit("spell", "The caster conjures ball lightning!")
    end

    return created
end

-- Preserve the existing player spell registration with the shared spawn.
function lightning.resolve(ctx, player, _, _, power)
    lightning.spawn(ctx, player, power)
end

registry.add(spells.SPELL_CONJURE_BALL_LIGHTNING, {
    resolve = lightning.resolve,
})

return lightning
