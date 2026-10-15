local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local intent_ids = require("constants.intent")
local blast = require("policy.magic.effects.summons.blast")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

local foxfire = {}

local function space(ctx, player)
    local origin = ctx:get(player, component.POSITION)

    for dx = -1, 1 do
        for dy = -1, 1 do
            if (dx ~= 0 or dy ~= 0) and
                ctx:walkable(origin.level_id, origin.x + dx, origin.y + dy) and
                not ctx:actor_at(origin.level_id, origin.x + dx, origin.y + dy) then
                return true
            end
        end
    end

    return false
end

function foxfire.act(ctx, entity, origin)
    local state = ctx:get(entity, component.SUMMON_CONSTRUCT)

    if state.charge >= 1 then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    local target, distance = blast.nearest_hostile(ctx, origin, 7)

    if target and distance == 1 then
        local sides = 4 + math.floor(math.min(50, state.power) / 5)
        local raw = 1 + summons.roll(ctx, sides)

        -- Source: zap-data.h:ZAP_FOXFIRE, an automatic 1d(4 + pow/5) hit.
        blast.hit(ctx, target, raw, "MR_RES_FIRE", entity)
        blast.finish(ctx, entity, 1)
        ctx:emit("combat", "Your foxfire strikes a nearby creature.")

        return { kind = intent_ids.MONSTER_ABILITY, spell_id = spells.SPELL_FOXFIRE }
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

-- Source: spl-summoning.cc:cast_foxfire creates two adjacent, short-lived
-- foxfires and rejects a completely enclosed caster before spending time.
function foxfire.prepare(ctx, player)
    if not space(ctx, player) then
        return "There is not enough space to conjure foxfire!"
    end
end

function foxfire.resolve(ctx, player, _, _, power)
    local created = 0

    for _ = 1, 2 do
        local creature = summons.spawn(ctx, player,
            spells.SPELL_FOXFIRE, monsters.MONS_FOXFIRE, 0, 12, {
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
        ctx:emit("spell", "You conjure some foxfire!")
    end
end

registry.add(spells.SPELL_FOXFIRE, {
    prepare = foxfire.prepare,
    resolve = foxfire.resolve,
})

return foxfire
