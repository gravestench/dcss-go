local actors = require("policy.combat.monster_area.actors")
local boons = require("policy.combat.monster_area.chaos_boons")
local catalog = require("policy.catalog")
local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local duration = require("policy.combat.monster_support.duration")
local flags = require("constants.monster_flags")
local flavours = require("constants.beam_flavours")
local groups = require("constants.monster_groups")
local inner_flame = require("policy.magic.effects.zaps.inner_flame")
local polymorph = require("policy.combat.monster_hexes.polymorph")
local self_target = require("policy.combat.monster_support.self_target")
local stasis = require("policy.magic.effects.statuses.monster_stasis")
local streams = require("constants.rng_streams")
local strip = require("policy.combat.monster_hexes.strip_willpower")
local targets = require("policy.ai.targets")

local effect = {}
local choices = {
    flavours.BEAM_HASTE,
    flavours.BEAM_MIGHT,
    flavours.BEAM_AGILITY,
    flavours.BEAM_RESISTANCE,
    flavours.BEAM_VULNERABILITY,
    flavours.BEAM_BERSERK,
    flavours.BEAM_POLYMORPH,
    flavours.BEAM_INNER_FLAME,
}

local function firewood(definition)
    local found = {}

    for _, flag in ipairs(definition.flags or {}) do
        found[flag] = true
    end

    return found[flags.STATIONARY] and found[flags.NO_THREAT] and
        not groups.tentacles[definition.id] and
        not groups.test_monsters[definition.id]
end

local function allies(ctx, caster)
    local result = {}

    for _, ally in ipairs(actors.los(ctx, caster, 7)) do
        local actor = ctx:get(ally, component.ACTOR)
        local definition = catalog.get("monsters", actor.kind_id)

        if targets.aligned(ctx, caster, ally) and not firewood(definition) then
            result[#result + 1] = ally
        end
    end

    return result
end

function effect.plan(ctx, caster, foe)
    local origin = ctx:get(caster, component.POSITION)
    local destination = foe and ctx:get(foe, component.POSITION)

    if not destination or not targets.enemy(ctx, caster, foe) or
        destination.level_id ~= origin.level_id or
        not ctx:visible_no_trans(origin.level_id, origin.x, origin.y,
            7, destination.x, destination.y) or #allies(ctx, caster) == 0 then
        return nil
    end

    return self_target.plan(caster)
end

-- mon-cast.cc weights each ordinary boon at 150 and each unusual effect
-- at 15. Enchant allies directly; do not invent a projectile or will save.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    for _, ally in ipairs(allies(ctx, caster)) do
        stasis.wake_hibernating(ctx, ally)

        local draw = ctx:random(streams.MONSTER_SPELL, 660)
        local index = draw < 600 and math.floor(draw / 150) + 1 or
            math.floor((draw - 600) / 15) + 5
        local flavour = choices[index]

        if boons.handles(flavour) then
            boons.apply(ctx, caster, ally, flavour, 100)
        elseif flavour == flavours.BEAM_RESISTANCE then
            if not ctx:has(ally, constructs.RESISTANCE) then
                ctx:add(ally, constructs.RESISTANCE, {
                    remaining_aut = duration.beneficial(ctx, ally),
                })
            end
        elseif flavour == flavours.BEAM_VULNERABILITY then
            strip.apply(ctx, caster, ally)
        elseif flavour == flavours.BEAM_POLYMORPH then
            if polymorph.viable(ctx, caster, ally) then
                polymorph.apply(ctx, caster, ally)
            end
        elseif flavour == flavours.BEAM_INNER_FLAME then
            inner_flame.mark(ctx, caster, ally)
        end
    end
end

return effect
