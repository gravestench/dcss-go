local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local intent_ids = require("constants.intent")
local blast = require("policy.magic.effects.summons.blast")
local catalog = require("policy.catalog")
local defense = require("policy.combat.monster_defense")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")
local trajectory = require("policy.combat.trajectory")
local targets = require("policy.ai.targets")

local spire = {}

local function target(ctx, entity, origin)
    local closest = math.huge
    local chosen = nil

    for _, hostile in ipairs(ctx:query({ component.ACTOR, component.POSITION, component.HEALTH })) do
        if targets.enemy(ctx, entity, hostile) then
            local position = ctx:get(hostile, component.POSITION)
            local health = ctx:get(hostile, component.HEALTH)
            local range = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if position.level_id == origin.level_id and health.current > 0 and
                range <= 7 and range < closest and
                ctx:visible(origin.level_id, origin.x, origin.y,
                    7, position.x, position.y) and
                ctx:projectile_clear(origin.level_id, origin.x, origin.y,
                    position.x, position.y) then
                chosen = hostile
                closest = range
            end
        end
    end

    return chosen
end

-- Source: MST_ZAPPER -> SPELL_ELECTRICAL_BOLT and
-- zap-data.h:dicedef_calculator<3, 3, 1, 12>.
function spire.act(ctx, entity, origin)
    local hostile = target(ctx, entity, origin)

    if not hostile then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    local destination = ctx:get(hostile, component.POSITION)
    local hd = ctx:get(entity, component.SUMMON_STATS).hd
    local sides = 3 + hd
    local impact = trajectory.trace(ctx, origin.level_id,
        origin.x, origin.y, destination.x, destination.y, 7)
    local victim = impact.contacts[1]

    if victim and victim.actor == hostile then
        local definition = catalog.get("monsters",
            ctx:get(hostile, component.ACTOR).kind_id)
        if summons.roll(ctx, 35) >=
            summons.roll(ctx, math.max(1,
                defense.evasion(ctx, hostile, definition))) then
            local damage = 0

            for _ = 1, 3 do
                damage = damage + 1 + summons.roll(ctx, sides)
            end

            blast.hit(ctx, hostile, damage, "MR_RES_ELEC", entity)
        end

        ctx:emit("combat", "Your lightning spire zaps the " .. definition.name .. ".")
    end

    return {
        kind = intent_ids.MONSTER_ABILITY,
        spell_id = spells.SPELL_ELECTRICAL_BOLT,
    }
end

-- Source: spl-summoning.cc:cast_summon_lightning_spire.
function spire.resolve(ctx, player, _, _, power)
    local creature = summons.spawn(ctx, player,
        spells.SPELL_SUMMON_LIGHTNING_SPIRE, monsters.MONS_LIGHTNING_SPIRE, 2, 1, {
            hd = math.max(1, summons.divide(ctx, power, 10)),
        })

    if creature then
        ctx:add(creature, "magic.summon_spire", { power = power })
        ctx:emit("spell", "An electric hum fills the air.")
    end
end

registry.add(spells.SPELL_SUMMON_LIGHTNING_SPIRE, {
    resolve = spire.resolve,
})

return spire
