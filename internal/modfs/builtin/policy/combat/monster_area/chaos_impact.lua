-- Each Chain of Chaos ray cell draws a flavour after the jump is selected.
-- An actor standing between the arc source and a player target can receive
-- the hit first. The original caster's return arc is visual and never
-- chooses a flavour. Source: spl-damage.cc:cast_chain_spell and beam.cc.
-- Example: impact.apply(ctx, caster, source, foe, power, false) can send a
-- fire contact through the ordinary beam resistance and health owners.
local accuracy = require("constants.beam_accuracy")
local acid = require("policy.combat.monster_beams.acid")
local boons = require("policy.combat.monster_area.chaos_boons")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local contact = require("policy.combat.monster_beams.contact")
local draining = require("policy.combat.monster_beams.draining")
local ensnare = require("policy.combat.monster_area.web")
local flavours = require("constants.beam_flavours")
local hexes = require("policy.combat.monster_area.chaos_hexes")
local light = require("policy.combat.monster_area.chaos_light")
local mindburst = require("policy.combat.monster_area.chaos_mindburst")
local movement = require("policy.combat.monster_area.chaos_movement")
local poison = require("policy.combat.monster_beams.poison")
local pool = require("policy.combat.monster_area.chaos_flavours")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local trajectory = require("policy.combat.trajectory")

local impact = {}
local RANGE = 8
local base = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CHAIN_OF_CHAOS)

local plain_damage = {
    [flavours.BEAM_FIRE] = true,
    [flavours.BEAM_COLD] = true,
    [flavours.BEAM_ELECTRICITY] = true,
    [flavours.BEAM_POISON] = true,
    [flavours.BEAM_NEG] = true,
    [flavours.BEAM_HOLY] = true,
    [flavours.BEAM_ACID] = true,
    [flavours.BEAM_LIGHT] = true,
    [flavours.BEAM_DAMNATION] = true,
    [flavours.BEAM_STICKY_FLAME] = true,
    [flavours.BEAM_ENSNARE] = true,
}

-- Reuse the same secondary-effect owners as ordinary monster beams.
-- Their hooks receive the outcome after armour and resistance calculation.
local damage_hooks = {
    [flavours.BEAM_POISON] = poison,
    [flavours.BEAM_NEG] = draining,
    [flavours.BEAM_ACID] = acid,
    [flavours.BEAM_LIGHT] = light,
    [flavours.BEAM_ENSNARE] = ensnare,
}

-- Copy the immutable catalog profile because each contact has an
-- independent chaos flavour and the next arc can use another one.
local function with_flavour(flavour, enchantment)
    local profile = {}

    for key, value in pairs(base) do
        profile[key] = value
    end

    profile.flavour = flavour
    profile.is_enchantment = enchantment or false
    profile.rng_stream = streams.MONSTER_SPELL

    return profile
end

-- Chaos enchantments affect status after shield and contact resolution;
-- their beam hit itself does not roll the arc's damage dice.
function impact.skip_damage()
    return true
end

-- Bind one flavour and current jump power to a small contact hook. Status
-- owners still decide whether the target can receive their specific effect.
local function enchantment_hook(handler, flavour, power, profile)
    local hook = {
        skip_damage = impact.skip_damage,
        suppress_hit_message = true,
    }

    -- The beam owner calls this only after an unblocked actor contact.
    function hook.after_hit(ctx, caster, defender)
        handler.apply(ctx, caster, defender, flavour, power, profile)
    end

    return hook
end

-- The selected flavour decides its own effect domain. All enchantments
-- share the beam's shield contact and skip direct armour damage.
local function enchantment_policy(flavour)
    if hexes.handles(flavour) then
        return hexes
    end

    if boons.handles(flavour) then
        return boons
    end

    if movement.handles(flavour) then
        return movement
    end

    if flavour == flavours.BEAM_MINDBURST then
        return mindburst
    end

    return nil
end

-- Return a visual hit without rolling flavour or damage when the chain
-- comes back to its own caster. The source also halves visual dice, but
-- those dice cannot affect game state in this monster spell.
function impact.apply(ctx, caster, source, target, power, visual)
    if visual then
        return false
    end

    local destination = ctx:get(target, component.POSITION)

    if not destination or
        destination.level_id ~= source.level_id then
        return false
    end

    local ray = trajectory.to_target(ctx, source.level_id,
        source.x, source.y,
        destination.x, destination.y, RANGE)
    -- beam.cc:bolt::affect_cell calls fake_flavour even for empty floor.
    -- Preserve those saved RNG draws before resolving the first actor.
    for _, cell in ipairs(ray.path) do
        local flavour = pool.choose(ctx, streams.MONSTER_SPELL)
        local actor = ctx:actor_at(source.level_id, cell.x, cell.y)

        if actor then
            local policy = enchantment_policy(flavour)

            if policy then
                local profile = with_flavour(flavour, true)

                return contact.resolve(ctx, caster, actor,
                    profile, power,
                    accuracy.AUTOMATIC_HIT,
                    enchantment_hook(policy, flavour, power, profile))
            end

            if not plain_damage[flavour] then
                error("chain chaos contact has no effect policy for " ..
                    tostring(flavour))
            end

            return contact.resolve(ctx, caster, actor,
                with_flavour(flavour), power,
                accuracy.AUTOMATIC_HIT,
                damage_hooks[flavour])
        end
    end

    return false
end

return impact
