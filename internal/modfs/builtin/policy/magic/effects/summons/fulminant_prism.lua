local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local intent_ids = require("constants.intent")
local blast = require("policy.magic.effects.summons.blast")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

local prism = {}

-- A prism's saved charge determines both the radius and dice count.
-- Lethal damage at charge one produces the smaller source explosion;
-- its own second action produces the fully charged one.
function prism.explode(ctx, entity, death_position)
    local state = ctx:get(entity, component.SUMMON_CONSTRUCT)

    if not state or state.charge < 1 or state.charge > 2 then
        return false
    end

    local hd = math.max(1, math.floor(state.power / 10))
    local sides = 6 + math.floor(hd * 7 / 4)
    local dice = state.charge == 2 and 3 or 2

    blast.area(ctx, entity, state.charge, dice, sides,
        nil, nil, nil, death_position)
    blast.finish(ctx, entity, 3)
    ctx:emit("combat", "Your fulminant prism explodes!")

    return true
end

-- Use the same relative target coordinates during preparation and placement.
local function cell(ctx, player, dx, dy)
    local origin = ctx:get(player, component.POSITION)

    return origin, origin.x + dx, origin.y + dy
end

-- Example: A new prism first crackles, then uses its saved power for the later explosion.
-- Advance saved charge over two actions; the second action explodes and marks the prism finished.
function prism.act(ctx, entity)
    local state = ctx:get(entity, component.SUMMON_CONSTRUCT)

    if state.charge >= 3 then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    state.charge = state.charge + 1
    ctx:set(entity, component.SUMMON_CONSTRUCT, state)

    if state.charge == 1 then
        ctx:emit("combat", "Your fulminant prism crackles loudly.")
    else
        prism.explode(ctx, entity)
    end

    return { kind = intent_ids.MONSTER_ABILITY, spell_id = spells.SPELL_FULMINANT_PRISM }
end

-- Source: spl-summoning.cc:cast_fulminating_prism, including exact cell
-- placement and the no-time solid/occupied/out-of-range rejection.
function prism.prepare(ctx, player, spell, dx, dy)
    local origin, x, y = cell(ctx, player, dx, dy)
    local reach = range.for_spell(ctx, player, spell)

    if math.max(math.abs(dx), math.abs(dy)) > reach then
        return "That's too far away."
    end

    if not ctx:walkable(origin.level_id, x, y) then
        return "You can't conjure that within a solid object!"
    end

    if ctx:actor_at(origin.level_id, x, y) then
        return "You can't place the prism on a creature."
    end
end

-- Place the delayed construct at the checked cell and persist power for its timed blast.
function prism.resolve(ctx, player, intent, _, power)
    local origin, x, y = cell(ctx, player, intent.dx, intent.dy)
    local creature = summons.spawn(ctx, player,
        spells.SPELL_FULMINANT_PRISM, monsters.MONS_FULMINANT_PRISM, 0, 1, {
            anchor = origin,
            exact = { x = x, y = y },
            expires_aut = ctx:aut() + 60,
        })

    if creature then
        ctx:add(creature, component.SUMMON_CONSTRUCT, {
            power = power,
            charge = 0,
        })
        ctx:emit("spell", "You conjure a prism of explosive energy!")
    end
end

registry.add(spells.SPELL_FULMINANT_PRISM, {
    prepare = prism.prepare,
    resolve = prism.resolve,
})

return prism
