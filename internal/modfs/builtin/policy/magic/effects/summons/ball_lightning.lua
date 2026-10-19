local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local intent_ids = require("constants.intent")
local blast = require("policy.magic.effects.summons.blast")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

local lightning = {}

-- Example: An uncharged ball lightning explodes once and records charge one to prevent a repeat blast.
-- Mark the construct charged before damage rolls so later actions cannot explode it twice.
function lightning.explode(ctx, entity)
    local state = ctx:get(entity, component.SUMMON_CONSTRUCT)

    if state.charge ~= 0 then
        return
    end

    state.charge = 1
    ctx:set(entity, component.SUMMON_CONSTRUCT, state)
    local hd = math.max(1, math.floor(state.power / 6) - 6)
    local radius = summons.roll(ctx, 24) < hd and 3 or 2
    local sides = 5 + math.floor(hd * 5 / 4)

    -- Source: mon-explode.cc:ball_lightning_damage and explosion radius.
    blast.area(ctx, entity, radius, 3, sides, "MR_RES_ELEC")
    ctx:emit("combat", "Your ball lightning explodes!")
end

-- Explode only once within two cells of an enemy; the charge marker stops repeat blasts before expiry.
function lightning.act(ctx, entity, origin)
    if ctx:get(entity, component.SUMMON_CONSTRUCT).charge >= 1 then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    local target, distance = blast.nearest_hostile(ctx, origin, 7)

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

-- Source: spl-summoning.cc:cast_conjure_ball_lightning creates three
-- independent short-lived balls with HD max(1, pow/6 - 6).
function lightning.resolve(ctx, player, _, _, power)
    local created = 0

    for _ = 1, 3 do
        local creature = summons.spawn(ctx, player,
            spells.SPELL_CONJURE_BALL_LIGHTNING, monsters.MONS_BALL_LIGHTNING, 0, 18, {
                expires_aut = ctx:aut() + 60,
            })

        if creature then
            ctx:add(creature, component.SUMMON_CONSTRUCT, {
                power = power,
                charge = 0,
            })
            created = created + 1
        end
    end

    if created > 0 then
        ctx:emit("spell", "You create some ball lightning!")
    end
end

registry.add(spells.SPELL_CONJURE_BALL_LIGHTNING, {
    resolve = lightning.resolve,
})

return lightning
