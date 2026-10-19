-- Cleansing Flame is a holy blast centered on its caster, not a projectile
-- aimed at the selected foe. Source setup uses radius two and two dice,
-- then the ordinary holy resistance rule handles each living body.
-- Source: mon-cast.cc and spl-goditem.cc:setup_cleansing_flame_beam.
local actors = require("policy.combat.monster_area.actors")
local beam_damage = require("policy.combat.monster_beams.damage")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local decision = require("policy.combat.monster_area.decision")
local direct = require("policy.combat.monster_direct")
local display = require("policy.combat.monster_support.display")
local flavours = require("constants.beam_flavours")
local holy = require("policy.clouds.effects.holy")
local monster_stats = require("policy.combat.monster_stats")
local roll = require("policy.combat.roll")
local self_target = require("policy.combat.monster_support.self_target")
local senses = require("policy.character.senses")

local effect = {}
local RADIUS = 2
local FOE_RATIO = 80
local profile = {
    flavour = flavours.BEAM_HOLY,
}

-- Immunity removes a body from source-style collateral calculation;
-- vulnerable undead or demonic actors carry extra expected weight.
local function expected_impact(ctx, target)
    if holy.immune(ctx, target) then
        return 0
    end

    return holy.adjust(ctx, target, 100)
end

-- The tracer asks whether enough vulnerable enemies stand in the blast
-- to justify striking any allies. No damage dice are spent while planning.
function effect.plan(ctx, caster)
    local origin = ctx:get(caster, component.POSITION)

    if not origin then
        return nil
    end

    local victims = actors.blast(ctx, origin.level_id,
        origin.x, origin.y, RADIUS)

    if not decision.accept(ctx, caster, victims,
        FOE_RATIO, expected_impact) then
        return nil
    end

    return self_target.plan(caster)
end

-- Source monster casting uses `5 + 5 * spell_hd / 12` sides on each of
-- two dice. Armour and holy adjustment precede attributed HP loss.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local origin = ctx:get(caster, component.POSITION)
    local state = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, state.kind_id)
    local hd = monster_stats.spell_hit_dice(ctx, caster, definition)
    local sides = 5 + math.floor(5 * hd / 12)

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL,
            "The " .. display.name(ctx, caster) ..
                " channels a blast of cleansing flame!")
    end

    for _, target in ipairs(actors.blast(ctx, origin.level_id,
        origin.x, origin.y, RADIUS)) do
        if not holy.immune(ctx, target) then
            local raw = 2 + roll.spell(ctx, sides) +
                roll.spell(ctx, sides)
            local after_ac = direct.armour(ctx, target, raw)
            local amount = beam_damage.resisted(ctx, target,
                after_ac, profile)

            if amount > 0 then
                direct.damage(ctx, caster, target, amount)
            end
        end
    end
end

return effect
