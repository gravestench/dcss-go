-- Sporulate creates one short-lived spore that pursues the selected foe.
local component = require("constants.component")
local spore = require("policy.combat.monster_plants.spore")
local targets = require("policy.ai.targets")
local target = require("policy.combat.monster_spell_target")
local target_kind = require("constants.target_kind")

local effect = {}

-- A chosen foe and one open adjacent cell are needed before casting.
function effect.plan(ctx, caster, foe)
    local origin = ctx:get(caster, component.POSITION)
    local victim = foe and ctx:get(foe, component.POSITION)

    if not origin or not victim or origin.level_id ~= victim.level_id or
        not targets.enemy(ctx, caster, foe) or
        not spore.can_spawn(ctx, caster) then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- The saved entity plan forbids a different target after preflight.
function effect.resolve(ctx, caster, foe, _, plan)
    target.require_entity(plan, foe)

    if ctx:has(caster, component.ACTOR) then
        spore.spawn(ctx, caster, foe)
    end
end

return effect
