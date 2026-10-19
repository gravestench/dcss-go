local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local habitat = require("policy.combat.monster_habitat")
local monsters = require("ids.monsters")
local self_target = require("policy.combat.monster_support.self_target")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")

local effect = {}
local kinds = {
    [monsters.MONS_KRAKEN] = {
        child = monsters.MONS_KRAKEN_TENTACLE,
        maximum = 4,
    },
    [monsters.MONS_TENTACLED_STARSPAWN] = {
        child = monsters.MONS_STARSPAWN_TENTACLE,
        maximum = 2,
    },
}

local function available(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)
    local rule = kinds[actor.kind_id]

    if not rule then
        return nil
    end

    local count = 0

    for _, child in ipairs(ctx:query({ constructs.TENTACLE })) do
        local state = ctx:get(child, constructs.TENTACLE)
        local health = ctx:get(child, component.HEALTH)

        if state.parent == caster and health and health.current > 0 then
            count = count + 1
        end
    end

    return rule, math.max(0, rule.maximum - count)
end

local function cells(ctx, caster, kind)
    local origin = ctx:get(caster, component.POSITION)
    local result = {}

    for dy = -1, 1 do
        for dx = -1, 1 do
            local x = origin.x + dx
            local y = origin.y + dy

            if (dx ~= 0 or dy ~= 0) and
                not ctx:actor_at(origin.level_id, x, y) and
                habitat.kind_at(ctx, kind, origin.level_id, x, y) then
                result[#result + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return result
end

function effect.plan(ctx, caster)
    local rule, remaining = available(ctx, caster)

    if rule and remaining > 0 and #cells(ctx, caster, rule.child) > 0 then
        return self_target.plan(caster)
    end
end

-- mon-tentacle.cc creates permanent attached children, filling the parent's
-- quota. Only excess candidate cells are shuffled; full rings need no roll.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local rule, remaining = available(ctx, caster)
    local choices = cells(ctx, caster, rule.child)

    if #choices > remaining then
        for index = #choices, 2, -1 do
            local other = 1 + ctx:random(streams.MONSTER_SPELL, index)

            choices[index], choices[other] = choices[other], choices[index]
        end
    end

    for index = 1, math.min(remaining, #choices) do
        local child = summons.spawn(ctx, caster, spells.SPELL_CREATE_TENTACLES,
            rule.child, 0, nil, { exact = choices[index] })

        if child then
            ctx:add(child, constructs.TENTACLE, { parent = caster })
        end
    end

    ctx:emit("spell", "Tentacles burst from the monster's body!")
end

return effect
