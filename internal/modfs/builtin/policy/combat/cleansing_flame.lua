-- Cleansing Flame is one instantaneous holy explosion used by monsters and
-- the Shining One. The caller chooses dice and attribution; this owner
-- shares the source's radius, AC, holiness, and collateral handling.
local actors = require("policy.combat.monster_area.actors")
local beam_damage = require("policy.combat.monster_beams.damage")
local direct = require("policy.combat.monster_direct")
local flavours = require("constants.beam_flavours")
local holy = require("policy.clouds.effects.holy")
local roll = require("policy.combat.roll")

local flame = {}

local RADIUS = 2
local profile = {
    flavour = flavours.BEAM_HOLY,
}

-- Resolve each reached actor once. A nil source is the source game's
-- KILL_MISC divine blast, so no transient caster can leak into later state.
function flame.blast(ctx, origin, sides, source)
    if sides < 1 then
        error("cleansing flame needs a positive die")
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
                direct.damage(ctx, source, target, amount)
            end
        end
    end
end

return flame
