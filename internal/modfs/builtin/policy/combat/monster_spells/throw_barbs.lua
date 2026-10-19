-- Manticore-like monsters use Throw Barbs only while their foe stands
-- beyond melee reach. The projectile itself uses the ordinary beam owner.
-- Source: mon-cast.cc:SPELL_THROW_BARBS and zap-data.h.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local spells = require("ids.spells")
local barbs = require("policy.combat.barbs")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_THROW_BARBS)
local MELEE_REACH = 1

-- The three source book casters use ordinary adjacent natural attacks.
-- Spending a cast beside a foe would replace their stronger melee action.
function effect.plan(ctx, caster, foe)
    local source = ctx:get(caster, component.POSITION)
    local destination = foe and ctx:get(foe, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id then
        return nil
    end

    local distance = math.max(math.abs(source.x - destination.x),
        math.abs(source.y - destination.y))

    if distance <= MELEE_REACH then
        return nil
    end

    return beam.plan(ctx, caster, foe, profile)
end

-- A damaging impact embeds spikes in the target after the shared beam has
-- applied HP loss; movement and duration are owned by the barbs policy.
function effect.after_hit(ctx, caster, defender, _, outcome)
    barbs.lodge(ctx, caster, defender, outcome.damage)
end

-- The fixed volley damage and hit chance come from its catalog profile.
function effect.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, effect)
end

return effect
