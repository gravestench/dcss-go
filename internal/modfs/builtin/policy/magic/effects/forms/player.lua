local species_ids = require("ids.species")
local component = require("constants.component")
local terrain_ids = require("constants.terrain")
local size = require("constants.size")
local catalog = require("policy.magic.effects.forms.catalog")
local character_catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local rage = require("policy.character.rage")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local player_attributes = require("policy.character.attributes")
local vampire = require("policy.character.vampire")

local forms = {}

local appendages = {
    { id = "MUT_HORNS", bit = 1, level = 2 },
    { id = "MUT_TENTACLE_SPIKE", bit = 2, level = 3 },
    { id = "MUT_TALONS", bit = 4, level = 2 },
}

local function has_bit(mask, bit)
    return math.floor(mask / bit) % 2 == 1
end

local function has_flag(species, flag)
    for _, value in ipairs(species.flags or {}) do
        if value == flag then
            return true
        end
    end

    return false
end

-- Source: transform.cc:appendages and physiology_mutation_conflict.
local function appendage_mask(ctx, player)
    local origin = ctx:get(player, component.PLAYER)
    local species = character_catalog.get("species", origin.species_id)
    local function has(id)
        return mutation_levels.base(ctx, player, id) > 0
    end

    local mask = 0

    if not has(mutations.MUT_HORNS) and not has(mutations.MUT_ANTENNAE) and
        not has_flag(species, "SPF_NO_BONES") then
        mask = mask + 1
    end

    if not has(mutations.MUT_TENTACLE_SPIKE) and
        has(mutations.MUT_TENTACLE_ARMS) then
        mask = mask + 2
    end

    if not has(mutations.MUT_TALONS) and not has(mutations.MUT_MERTAIL) and
        not has(mutations.MUT_CONSTRICTING_TAIL) and
        not has(mutations.MUT_FLOAT) and not has(mutations.MUT_PAWS) and
        not has(mutations.MUT_TENTACLE_ARMS) then
        mask = mask + 4
    end

    return mask
end

local function appendage_message(ctx, mask, ending)
    if has_bit(mask, 1) then
        ctx:emit(ending and "duration" or "spell", ending and
            "Your horns disappear." or "You grow a pair of large bovine horns.")
    end

    if has_bit(mask, 2) then
        ctx:emit(ending and "duration" or "spell", ending and
            "Your tentacle spike disappears." or
            "One of your tentacles grows a vicious spike.")
    end

    if has_bit(mask, 4) then
        ctx:emit(ending and "duration" or "spell", ending and
            "Your talons disappear." or "Your feet morph into talons.")
    end
end

local function record(ctx, player)
    local active = ctx:get(player, component.PLAYER_FORM)

    if not active or active.remaining_aut <= 0 then
        return nil, nil
    end

    for _, definition in pairs(catalog) do
        if definition.id == active.form_id then
            return active, definition
        end
    end

    error("unknown saved player form " .. active.form_id)
end

function forms.profile(spell_id)
    return catalog[spell_id]
end

-- Source: transform.cc:transform dry run and lifeless_prevents_form.
-- Terrain is a typed feature ID returned by the generic grid context.
function forms.rejection(ctx, player, spell_id)
    local destination = catalog[spell_id]

    if not destination then
        error("unknown player form spell " .. tostring(spell_id))
    end

    local active, previous = record(ctx, player)

    if active and active.form_id == destination.id then
        return nil
    end

    if destination.id == "appendage" and appendage_mask(ctx, player) == 0 then
        return "You have no appropriate body parts free."
    end

    local origin = ctx:get(player, component.PLAYER)
    local attributes = player_attributes.current(ctx, player)
    local species = character_catalog.get("species", origin.species_id)

    if species.undead_type == "US_UNDEAD" or
        (species.id == species_ids.SP_VAMPIRE and destination.id == "lich") then
        return "Your unliving flesh cannot be transformed in this way."
    end

    if mutation_levels.base(ctx, player, mutations.MUT_VAMPIRISM) > 0 and
        ((vampire.bloodless(ctx, player) and destination.id ~= "bat") or
            (vampire.alive(ctx, player) and destination.id == "bat")) then
        return "Your blood state cannot sustain that transformation."
    end

    local statuses = ctx:get(player, component.PLAYER_STATUS)

    if destination.id == "lich" and statuses and
        statuses.death_door_aut > 0 then
        return "You cannot become a lich while in death's door."
    end

    local old_strength = previous and previous.strength or 0
    local old_dexterity = previous and previous.dexterity or 0

    if attributes.strength + destination.strength - old_strength <= 0 then
        return "Transforming would reduce your strength to zero."
    end

    if attributes.dexterity + destination.dexterity - old_dexterity <= 0 then
        return "Transforming would reduce your dexterity to zero."
    end

    local position = ctx:get(player, component.POSITION)
    local terrain = ctx:cell(position.level_id, position.x, position.y)
    -- Flight imports this module, so load the shared projection only after
    -- the form module has finished loading.
    local flight = require("policy.combat.flight")
    local wind = ctx:get(player, component.ZAP_FLIGHT)
    local spell_flight = wind and wind.remaining_aut > 0
    local old_form_flight = previous and previous.flight == "enable"
    local keeps_flight = flight.active(ctx, player) and
        (not old_form_flight or spell_flight)
    local safe_flight = destination.flight == "enable" or
        (destination.flight ~= "forbid" and keeps_flight)

    if terrain == terrain_ids.DNGN_LAVA and not safe_flight then
        return "You would burn in your new form."
    end

    local likes_water = destination.swim == "enable" or
        destination.size == size.GIANT or
        (species.habitat == "HT_WATER" or
            species.habitat == "HT_AMPHIBIOUS") and
        (destination.id == "statue" or destination.swim ~= "forbid")

    if terrain == terrain_ids.DNGN_DEEP_WATER and not safe_flight and
        not likes_water then
        return "You would drown in your new form."
    end

    return nil
end

local function base_hp(ctx, player)
    local origin = ctx:get(player, component.PLAYER)
    local progress = ctx:get(player, component.PROGRESSION)
    local skills = ctx:get(player, component.SKILLS)

    if not origin or not progress or not skills then
        error("player form requires origin, progression, and skills")
    end

    local species = character_catalog.get("species", origin.species_id)
    local drain = ctx:get(player, "status.drain")
    local permanent = ctx:get(player, component.PERMANENT_HP_LOSS)
    local loss = (drain and drain.amount or 0) +
        (permanent and permanent.amount or 0)

    return math.max(1,
        formulas.max_hp(ctx, player, progress.level, species, skills.entries) - loss)
end

-- Source: player.cc:get_real_hp multiplies the untransformed maximum after
-- permanent sources and drain have been accounted for.
function forms.max_hp(ctx, player)
    return forms.scale_hp(ctx, player, base_hp(ctx, player))
end

function forms.scale_hp(ctx, player, untransformed_max)
    local _, profile = record(ctx, player)
    local multiplier = profile and profile.hp_tenths or 10

    return math.max(1, math.floor(untransformed_max * multiplier / 10))
end

-- next_max is the final, already transformed maximum. Call after changing
-- permanent HP loss or another source of the player's maximum HP.
function forms.rescale_health(ctx, player, next_max)
    local health = ctx:get(player, component.HEALTH)
    local regeneration = ctx:get(player, component.REGENERATION)

    if not health or not regeneration or health.max <= 0 then
        error("player form requires live health and regeneration")
    end

    -- Source: player.cc:calc_hp(scale=true,set=false) carries the fractional
    -- regeneration amount through each change and floors current HP.
    formulas.rescale_health(health, regeneration,
        rage.scale_hp(ctx, player, next_max))
    ctx:set(player, component.HEALTH, health)
    ctx:set(player, component.REGENERATION, regeneration)
end

local function duration(ctx, profile, power)
    local turns = profile.base_turns

    if power > 0 then
        turns = turns + ctx:random("spell", power)

        if profile.scale == "double" then
            turns = turns + ctx:random("spell", power)
        end
    end

    return math.min(turns, profile.max_turns) * 10
end

-- Source: transform.cc:transform. The caller must perform its generic
-- terrain, stat-zero, undead and equipment checks before invoking this hook.
-- Equipment meld is a live projection from the blocked-slot hook below.
function forms.cast(ctx, player, spell_id, power)
    local profile = catalog[spell_id]

    if not profile then
        error("unknown player form spell " .. tostring(spell_id))
    end

    local existing, previous = record(ctx, player)
    local remaining = duration(ctx, profile, power)

    if existing and existing.form_id == profile.id then
        existing.power = power

        if existing.remaining_aut < remaining then
            existing.remaining_aut = remaining
            ctx:emit("spell", "You extend your transformation's duration.")
        else
            ctx:emit("spell", "You fail to extend your transformation any further.")
        end

        ctx:set(player, component.PLAYER_FORM, existing)
        return
    end

    if previous then
        if previous.id == "appendage" then
            appendage_message(ctx, existing.appendage_mask, true)
        else
            ctx:emit("duration", "Your transformation has ended.")
        end
        forms.rescale_health(ctx, player, base_hp(ctx, player))
    end

    if profile.id == "appendage" then
        appendage_message(ctx, appendage_mask(ctx, player), false)
    elseif profile.id == "lich" then
        ctx:emit("spell", "Your body is suffused with negative energy!")
    elseif profile.id == "blade_hands" then
        ctx:emit("spell", "Your hands turn into razor-sharp scythe blades.")
    else
        ctx:emit("spell", "You turn into " .. profile.description .. ".")
    end

    local value = {
        form_id = profile.id,
        remaining_aut = remaining,
        power = power,
        appendage_mask = profile.id == "appendage" and
            appendage_mask(ctx, player) or 0,
    }

    if existing then
        ctx:set(player, component.PLAYER_FORM, value)
    else
        ctx:add(player, component.PLAYER_FORM, value)
    end

    if not profile.keeps_mutations then
        -- Source: transform.cc:transform ends direct grips for these forms.
        require("policy.combat.player_constriction").release_all(ctx, player)
    end

    forms.rescale_health(ctx, player,
        math.max(1, math.floor(base_hp(ctx, player) * profile.hp_tenths / 10)))
end

function forms.tick(ctx, player, aut)
    local active = ctx:get(player, component.PLAYER_FORM)

    if not active or active.remaining_aut <= 0 or aut <= 0 then
        return
    end

    -- Source: player-reacts.cc keeps voluntary Vampire Bat Form until the
    -- player ends it or a blood-state change makes it impossible.
    if active.form_id == "bat" and
        mutation_levels.effective(ctx, player,
            mutations.MUT_VAMPIRISM) >= 2 then
        return
    end

    -- Source: player-reacts.cc applies random2(3) extra turns at the
    -- ten-turn warning. The warning leaves at least one aut to react.
    local before = active.remaining_aut
    local remaining = before - aut

    if before > 100 and remaining <= 100 then
        remaining = math.max(1, remaining - ctx:random("spell", 3) * 10)
        ctx:emit("duration", "Your transformation is almost over.")
    end

    active.remaining_aut = math.max(0, remaining)

    if active.remaining_aut == 0 then
        forms.finish(ctx, player)
    else
        ctx:set(player, component.PLAYER_FORM, active)
    end
end

function forms.finish(ctx, player)
    local active = ctx:get(player, component.PLAYER_FORM)

    if not active then
        return
    end

    if active.form_id == "appendage" then
        appendage_message(ctx, active.appendage_mask, true)
    elseif active.form_id == "bat" then
        ctx:emit("duration", "You feel less batty.")
    else
        ctx:emit("duration", "Your transformation has ended.")
    end

    ctx:remove(player, component.PLAYER_FORM)
    forms.rescale_health(ctx, player, base_hp(ctx, player))
end

function forms.end_rejection(ctx, player)
    if not ctx:has(player, component.PLAYER_FORM) then
        return "You are not transformed."
    end

    local position = ctx:get(player, component.POSITION)
    local feature = ctx:cell(position.level_id, position.x, position.y)
    local wind = ctx:get(player, component.ZAP_FLIGHT)
    local flight = require("policy.combat.flight")
    local airborne = flight.permanent(ctx, player) or
        (wind and wind.remaining_aut > 0)

    if feature == terrain_ids.DNGN_LAVA and not airborne then
        return "Turning back right now would cause you to burn!"
    end

    local origin = ctx:get(player, component.PLAYER)
    local species = character_catalog.get("species", origin.species_id)
    local habitats = require("constants.monster_habitats")
    local swimmer = species.habitat == habitats.WATER or
        species.habitat == habitats.AMPHIBIOUS or
        (size.rank[species.size] or 0) >= size.rank[size.GIANT]

    if feature == terrain_ids.DNGN_DEEP_WATER and
        not airborne and not swimmer then
        return "Turning back right now would cause you to drown!"
    end

    return nil
end

-- Source: transform.cc:_beastly_level. Temporary mutation levels are a
-- live projection of the saved appendage choices and vanish on expiry.
function forms.mutation_level(ctx, player, id)
    local active, profile = record(ctx, player)

    if not active or profile.id ~= "appendage" then
        return 0
    end

    for _, appendage in ipairs(appendages) do
        if appendage.id == id and has_bit(active.appendage_mask, appendage.bit) then
            return appendage.level
        end
    end

    return 0
end

-- Returns the temporary AuxKick level and its source attack type. Base
-- species mutations are handled by the shared melee policy separately.
function forms.kick_level(ctx, player)
    local talons = forms.mutation_level(ctx, player, "MUT_TALONS")

    if talons > 0 then
        return talons, "talons"
    end

    local spike = forms.mutation_level(ctx, player, "MUT_TENTACLE_SPIKE")

    if spike > 0 then
        return spike, "tentacle_spike"
    end

    return 0, nil
end

-- Projection hooks for shared combat, armour, stat, HP, equipment and
-- movement policies. The return is neutral if no form is active.
function forms.modifiers(ctx, player)
    local active, profile = record(ctx, player)

    if not active then
        return {
            strength = 0,
            dexterity = 0,
            hp_tenths = 10,
            ac_x100 = 0,
            res_fire = 0,
            res_cold = 0,
            unarmed_base = 3,
            spell_penalty = 0,
            blocks = "none",
            flight = "default",
            swim = "default",
            size = nil,
        }
    end

    return {
        strength = profile.strength,
        dexterity = profile.dexterity,
        hp_tenths = profile.hp_tenths,
        ac_x100 = profile.ac_flat * 100 + profile.ac_power * active.power,
        res_fire = profile.res_fire,
        res_cold = profile.res_cold,
        unarmed_base = profile.unarmed_base,
        spell_penalty = profile.spell_penalty,
        blocks = profile.blocks,
        flight = profile.flight,
        swim = profile.swim,
        size = profile.size,
    }
end

-- Source: transform.cc:FormStorm::get_base_unarmed_damage. Call this once
-- when rolling an actual unarmed attack, never for a UI projection.
function forms.unarmed_base(ctx, player)
    local active, profile = record(ctx, player)

    if not active then
        return 3
    end

    if profile.id ~= "storm" then
        return profile.unarmed_base
    end

    local quotient = math.floor(active.power / 3)
    local remainder = active.power % 3

    if remainder > 0 and ctx:random("combat", 3) < remainder then
        quotient = quotient + 1
    end

    return 2 + quotient
end

local blocked = {
    none = {},
    hands = { weapon = true, shield = true, gloves = true },
    head_foot = { head = true, boots = true },
    statue = { gloves = true, boots = true, body = true },
    physical = {
        weapon = true,
        shield = true,
        gloves = true,
        boots = true,
        body = true,
        head = true,
        cloak = true,
    },
}

-- Source: transform.cc:EQF_* slot masks. A false result means equipped
-- items in that slot are melded for live stat and attack projections.
function forms.slot_usable(ctx, player, slot)
    local _, profile = record(ctx, player)

    return not profile or not blocked[profile.blocks][slot]
end

-- Source: player.cc:player_speed. Statue Form slows every action, including
-- attacks and spells, rather than only changing movement speed.
function forms.action_delay(ctx, player, base_aut)
    local _, profile = record(ctx, player)

    if profile and profile.id == "statue" then
        return math.floor(base_aut * 15 / 10)
    end

    return base_aut
end

-- Source: transform.cc:form_base_movespeed and movement.cc minimum delay.
function forms.move_speed(ctx, player)
    local _, profile = record(ctx, player)

    if profile and profile.id == "bat" then
        return 5
    end

    return 10
end

function forms.can_drink(ctx, player)
    local _, profile = record(ctx, player)

    return not profile or profile.id ~= "lich"
end

-- Source: transform.h:Form::can_offhand_punch and the three form overrides
-- in transform.cc. Blade Hands can already wield, while Dragon and Storm
-- explicitly keep their extra offhand attack.
function forms.can_offhand_punch(ctx, player)
    local _, profile = record(ctx, player)

    return not profile or profile.blocks ~= "physical" or
        profile.id == "dragon" or profile.id == "storm"
end

-- Source: form-data.h:can_bleed and transform.cc:form_can_bleed.
function forms.can_bleed(ctx, player)
    local _, profile = record(ctx, player)

    return not profile or profile.can_bleed
end

return forms
