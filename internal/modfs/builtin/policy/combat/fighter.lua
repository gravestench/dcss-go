local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local statuses = require("policy.magic.effects.statuses.player")
local forms = require("policy.magic.effects.forms.player")
local mutation_levels = require("policy.mutations.levels")
local player_attributes = require("policy.character.attributes")
local mutation_effects = require("policy.mutations.effects.registry")
local mutation_capabilities = require("constants.mutation_capabilities")
local formulas = require("policy.character.formulas")
local agility = require("policy.character.agility")
local player_slay = require("policy.combat.player_slay")
local flight = require("policy.combat.flight")
local water = require("policy.character.water")
local size = require("constants.size")
local component = require("constants.component")
local rage = require("policy.character.rage")
local ammunition = require("ids.ammunition")
local weapon_brands = require("constants.weapon_brands")
local armour_egos = require("constants.armour_egos")
local form_ids = require("constants.form_ids")
local staves = require("policy.inventory.staves")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local jewellery_capabilities = require("constants.jewellery_capabilities")
local acrobat = require("policy.jewellery.acrobat")
local corrosion = require("policy.combat.player_corrosion")
local weapon_protection = require("policy.combat.player_weapon_protection")
local artefact_properties = require("policy.item_generation.artefacts.properties")
local artefact_ids = require("ids.artefact_properties")
local skill_order = require("data.skill_order")
local okawaru_status = require("policy.religion.okawaru.status")
local okawaru = require("constants.okawaru")

local fighter = {}

-- Missing mandatory player components fail at the combat boundary instead of
-- silently producing a zeroed attack or defense.
local function required(ctx, entity, component)
    local value = ctx:get(entity, component)

    if not value then
        error("fighter lacks " .. component)
    end

    return value
end

-- Fractional skill progress uses the XP cost between adjacent levels after
-- applying species aptitude and the 9/18/26 source breakpoints.
local function cost(level, aptitude)
    local points = 25 * level * (level + 1)

    for _, breakpoint in ipairs({ 9, 18, 26 }) do
        if level > breakpoint then
            local offset = level - breakpoint
            points = points + math.floor(25 * offset * (offset + 1) / 2)
        end
    end

    return math.floor(points * 2 ^ (-aptitude / 4))
end

-- Example: with player.species_id = "SP_HUMAN", fighter.species(ctx) returns the Human catalog definition.
-- Aptitude and body-size formulas must read the same species chosen at character creation.
function fighter.species(ctx)
    local choice = required(ctx, ctx:player(), "core.player")

    return catalog.get("species", choice.species_id)
end

-- Interpolate saved XP points between adjacent aptitude-adjusted skill costs;
-- callers choose a scale to avoid premature rounding in combat formulas.
function fighter.skill(ctx, id, scale)
    local skills = required(ctx, ctx:player(), "core.skills")
    local species = fighter.species(ctx)
    local available = species.aptitudes[id]

    -- Source useless skills stay zero even under Heroism. This matters for
    -- species such as Felids, which cannot use Armour or weapon skills.
    if not available or not available.allowed then
        return 0
    end

    local aptitude = formulas.effective_skill_aptitude(ctx,
        ctx:player(), species, id)

    for _, entry in ipairs(skills.entries) do
        if entry.id == id then
            if entry.level == 27 then
                return 27 * scale
            end

            local previous = cost(entry.level, aptitude)
            local next_cost = cost(entry.level + 1, aptitude)

            local effective = entry.level * scale +
                math.floor((entry.points - previous) * scale /
                    (next_cost - previous))

            if skill_order.is_mundane(id) and
                okawaru_status.active(ctx, ctx:player(), "heroism") then
                effective = math.min(27 * scale,
                    effective + okawaru.HEROISM_SKILL_BONUS * scale)
            end

            return effective
        end
    end

    if skill_order.is_mundane(id) and
        okawaru_status.active(ctx, ctx:player(), "heroism") then
        return 5 * scale
    end

    return 0
end

-- Some source armour and shield formulas use whole skill levels rather than
-- the fractional progress returned by fighter.skill.
function fighter.skill_level(ctx, id)
    local skills = required(ctx, ctx:player(), "core.skills")
    local species = fighter.species(ctx)
    local available = species.aptitudes[id]

    if not available or not available.allowed then
        return 0
    end

    for _, entry in ipairs(skills.entries) do
        if entry.id == id then
            if skill_order.is_mundane(id) and
                okawaru_status.active(ctx, ctx:player(), "heroism") then
                return math.min(27,
                    entry.level + okawaru.HEROISM_SKILL_BONUS)
            end

            return entry.level
        end
    end

    if skill_order.is_mundane(id) and
        okawaru_status.active(ctx, ctx:player(), "heroism") then
        return 5
    end

    return 0
end

-- Combat reads effective levels after species and form activity gates.
function fighter.mutation(ctx, id)
    return mutation_levels.effective(ctx, ctx:player(), id)
end

-- Build the live attack snapshot from form, skills, and worn weapon; a held
-- launcher contributes Fighting but no melee weapon damage or brand.
function fighter.attack(ctx, defender)
    local player = ctx:player()
    local attributes = player_attributes.current(ctx, player)
    local form = forms.modifiers(ctx, player)
    local worn = equipment.worn(ctx, player, { weapon = true })
    local weapon = worn.weapon
    local input = {
        strength = attributes.strength + form.strength,
        dexterity = attributes.dexterity + form.dexterity,
        fighting100 = fighter.skill(ctx, "SK_FIGHTING", 100),
        stealth50 = fighter.skill(ctx, "SK_STEALTH", 50),
        stealth100 = fighter.skill(ctx, "SK_STEALTH", 100),
        defender_ev = defender.ev or 0,
        defender_ac = defender.ac or 0,
        mighty = false,
        slay = player_slay.total(ctx, player),
    }

    local durations = ctx:get(player, "core.durations")
    input.mighty = (durations and durations.might_aut > 0 or false) or
        rage.active(ctx, player)

    if weapon then
        local definition = weapon.definition
        local profile = staves.weapon(definition)

        if not profile then
            error("equipped weapon lacks melee properties")
        end

        local launcher = profile.ammo_id ~= nil and
            profile.ammo_id ~= ammunition.NONE
        input.held_non_melee = launcher
        input.using_weapon = not launcher
        input.weapon_skill = launcher and "SK_FIGHTING" or
            profile.skill_id
        input.weapon_damage = launcher and 0 or
            profile.damage + artefact_properties.value(ctx,
                weapon.entity, artefact_ids.BASE_DAMAGE)
        input.weapon_hit = launcher and 0 or
            profile.hit + artefact_properties.value(ctx,
                weapon.entity, artefact_ids.BASE_ACCURACY)
        input.weapon_speed = profile.speed +
            artefact_properties.value(ctx, weapon.entity,
                artefact_ids.BASE_DELAY)
        input.weapon_plus = launcher and 0 or weapon.item.plus
        input.weapon100 = fighter.skill(ctx, input.weapon_skill, 100)
        input.weapon50 = fighter.skill(ctx, input.weapon_skill, 50)
        input.weapon_id = definition.id
        input.weapon_entity = weapon.entity
        input.weapon_brand = launcher and weapon_brands.NORMAL or
            weapon.ego
    else
        input.unarmed = true
        input.using_weapon = false
        input.weapon_skill = "SK_UNARMED_COMBAT"
        input.weapon_damage = 0
        input.weapon_hit = 0
        input.weapon_plus = 0
        input.weapon100 = fighter.skill(ctx, input.weapon_skill, 100)
        input.weapon50 = fighter.skill(ctx, input.weapon_skill, 50)
        input.unarmed256 = fighter.skill(ctx, input.weapon_skill, 256)
        input.form_uses_level = forms.uses_level(ctx, player)

        if input.form_uses_level then
            local progress = required(ctx, player, component.PROGRESSION)

            input.weapon100 = progress.level * 100
            input.unarmed_level = progress.level
        end

        local form = ctx:get(player, component.PLAYER_FORM)

        -- Fungus has no usable weapon, so its unarmed contact inherits the
        -- source form's confusing spores instead of a normal weapon brand.
        input.weapon_brand = form and form.remaining_aut > 0 and
            form.form_id == form_ids.FUNGUS and
            weapon_brands.CONFUSE or weapon_brands.NORMAL
    end

    return input
end

-- Validate equipped armour once and normalize missing slots to zero values
-- before EV and AC formulas combine body and auxiliary pieces.
local function armour_piece(entry)
    if not entry then
        return { ac = 0, ev = 0, plus = 0 }
    end

    if not entry.definition.armour then
        error("equipped item lacks armour properties")
    end

    return {
        ac = entry.definition.armour.ac,
        ev = entry.definition.armour.ev,
        plus = entry.item.plus,
    }
end

-- Derive EV, AC, and SH from the same worn snapshot so form-disabled slots
-- cannot leak a passive bonus through another calculation.
function fighter.defense(ctx)
    local player = ctx:player()
    local attributes = player_attributes.current(ctx, player)
    local form = forms.modifiers(ctx, player)
    local state = required(ctx, player, "core.combat")
    local worn = equipment.worn(ctx, player, {
        weapon = true,
        body = true,
        shield = true,
        head = true,
        cloak = true,
        gloves = true,
        boots = true,
    })

    local body = armour_piece(worn.body)
    local shield = armour_piece(worn.shield)
    local auxiliary = {}

    for _, slot in ipairs({ "head", "cloak", "gloves", "boots" }) do
        if worn[slot] then
            auxiliary[#auxiliary + 1] = armour_piece(worn[slot])
        end
    end

    local armour_skill = fighter.skill_level(ctx, "SK_ARMOUR")
    local shields_skill = fighter.skill_level(ctx, "SK_SHIELDS")
    local dodge10 = fighter.skill(ctx, "SK_DODGING", 10)
    local strength = attributes.strength + form.strength
    local dexterity = attributes.dexterity + form.dexterity
    local sturdy_reduction = mutation_effects.sum(ctx, player,
        mutation_capabilities.BODY_ENCUMBRANCE_REDUCTION)
    local body_encumbrance = math.max(0,
        math.floor(-body.ev / 10) - sturdy_reduction)
    -- Body encumbrance penalizes dodge quadratically; auxiliary armour has a
    -- separate linear piece penalty before the final EV rounding.
    local body_penalty = math.floor(
        2 * body_encumbrance ^ 2 * (450 - armour_skill * 10) * 100 /
        (5 * (strength + 3)) / 450
    )
    local piece_penalty = math.floor(-body.ev / 3)

    for _, piece in ipairs(auxiliary) do
        piece_penalty = piece_penalty + math.floor(-piece.ev / 3)
    end

    piece_penalty = math.floor(piece_penalty * 100 / 10)

    local shield_penalty = 0

    if shield.ac > 0 then
        local base = math.floor(-shield.ev / 10)
        shield_penalty = math.floor(2 * base ^ 2 * (270 - shields_skill * 10) * 100 / 100 / 270)
    end

    local dodge_bonus = math.floor((800 + dodge10 * dexterity * 8) * 100 / 20 / 10 / 10)
    local dodge_penalty = body_encumbrance - 3

    if dodge_penalty > 0 then
        if dodge_penalty >= strength then
            dodge_bonus = math.floor(dodge_bonus * strength / (dodge_penalty * 2))
        else
            dodge_bonus = dodge_bonus - math.floor(dodge_bonus * dodge_penalty / (strength * 2))
        end
    end

    local vertigo_penalty = statuses.vertigo_active(ctx, player) and 500 or 0
    local natural_ev = math.max(100,
        1000 + dodge_bonus - piece_penalty - body_penalty -
            shield_penalty - vertigo_penalty)
    local petrification = ctx:get(player,
        component.PLAYER_PETRIFICATION)

    if petrification and petrification.petrifying_aut > 0 then
        natural_ev = math.floor(natural_ev / 2)
    end

    if water.at(ctx, player) and
        mutation_effects.sum(ctx, player,
            mutation_capabilities.SWIMMER_LEVEL) >= 2 then
        natural_ev = natural_ev + math.max(200,
            math.floor(natural_ev / 4))
    elseif flight.tengu_perk(ctx, player) then
        natural_ev = natural_ev + math.max(100,
            math.floor(natural_ev / 5))
    end

    local ev = math.floor((natural_ev + 99) / 100)
    ev = ev + mutation_effects.sum(ctx, player,
        mutation_capabilities.EVASION_BONUS)
    ev = ev + agility.evasion_bonus(ctx, player)
    ev = ev + jewellery_effects.sum(ctx, player,
        jewellery_capabilities.EV)
    ev = ev + artefact_properties.sum_worn(ctx, player,
        artefact_ids.EVASION)
    ev = ev + acrobat.bonus(ctx, player)

    if petrification and petrification.petrified_aut > 0 then
        local species = fighter.species(ctx)
        local body_size = form.size or species.size
        local size_factor = 2 * (size.rank[size.MEDIUM] -
            size.rank[body_size])

        ev = math.max(1, 2 + size_factor / 2)
    end

    local factor = 440 + armour_skill * 20
    local body_ac = math.floor(body.ac * 100 * factor / 440)

    if mutation_effects.sum(ctx, player,
        mutation_capabilities.BODY_ARMOUR_AC_PENALTY) > 0 then
        -- Source: player.cc:base_ac_from subtracts half the unscaled base
        -- AC once, even if both mutations are present.
        body_ac = body_ac - body.ac * 50
    end

    -- Keep AC in hundredths until armour skill, status, form, mutation, and
    -- jewellery terms have all been summed.
    local scaled_ac = body_ac + body.plus * 100

    for _, piece in ipairs(auxiliary) do
        scaled_ac = scaled_ac + math.floor(piece.ac * 100 * factor / 440) + piece.plus * 100
    end

    scaled_ac = scaled_ac + statuses.ice_armour_bonus_x100(ctx, player,
        body_encumbrance)
    scaled_ac = scaled_ac + form.ac_x100
    scaled_ac = scaled_ac + mutation_effects.sum(ctx, player,
        mutation_capabilities.AC_PARTIAL_X100)
    scaled_ac = scaled_ac + mutation_effects.full_sum(ctx, player,
        mutation_capabilities.AC_FULL_X100)
    scaled_ac = scaled_ac + 100 * jewellery_effects.sum(ctx, player,
        jewellery_capabilities.AC)
    scaled_ac = scaled_ac + 100 * artefact_properties.sum_worn(ctx,
        player, artefact_ids.AC)

    -- Source player::base_ac_with_specific_items grants +3 for a
    -- Protection shield even though shield base armour counts as SH.
    if worn.shield and worn.shield.ego == armour_egos.PROTECTION then
        scaled_ac = scaled_ac + 300
    end

    if weapon_protection.active(ctx, player) then
        scaled_ac = scaled_ac + 700
    end

    local ac = math.max(0, math.floor(scaled_ac / 100) -
        corrosion.penalty(ctx, player))
    local shield_class = 0

    if shield.ac > 0 then
        local base = shield.ac * 2
        local value = base * 50 + math.floor(base * (shields_skill * 5) / 2) +
            shields_skill * 38 + math.min(shields_skill * 38, 3 * 38) +
            math.floor(dexterity * 38 * (base + 13) / 26) + shield.plus * 200
        shield_class = math.max(0, math.floor((value + 50) / 100))
    end

    shield_class = shield_class + mutation_effects.sum(ctx, player,
        mutation_capabilities.SHIELD_CLASS_BONUS)
    shield_class = shield_class + 10 * jewellery_effects.sum(ctx, player,
        jewellery_capabilities.REFLECTION)
    shield_class = shield_class + 2 * artefact_properties.sum_worn(ctx,
        player, artefact_ids.SHIELDING)

    if ctx:has(player, "core.constricted") then
        ev = math.max(0, ev - 3)
    end

    return {
        ev = ev,
        ac = ac,
        shield_class = shield_class,
        gdr = math.floor(16 * math.sqrt(math.sqrt(ac))),
        shield_blocks = state.shield_blocks,
        body_ev = body.ev,
        visible_hit_modifier = mutation_effects.sum(ctx, player,
            mutation_capabilities.VISIBLE_DEFENDER_HIT_MODIFIER),
        missile_repulsion = mutation_effects.sum(ctx, player,
            mutation_capabilities.MISSILE_REPULSION) > 0,
    }
end

return fighter
