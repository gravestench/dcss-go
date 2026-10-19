local accuracy = require("policy.character.accuracy")
local attributes = require("policy.character.attributes")
local catalog = require("policy.catalog")
local component = require("constants.component")
local combat_equipment = require("policy.combat.equipment")
local constriction = require("policy.combat.player_constriction")
local equipment_rules = require("policy.inventory.equipment")
local fighter = require("policy.combat.fighter")
local player_attack = require("policy.combat.player_attack")
local player_weakness = require("policy.combat.player_weakness")
local forms = require("policy.magic.effects.forms.player")
local mutations = require("ids.mutations")
local skills = require("ids.skills")
local species_ids = require("ids.species")
local levels = require("policy.mutations.levels")
local roll = require("policy.combat.roll")
local statuses = require("policy.magic.effects.statuses.player")

local auxiliary = {}
local registered = {}
local ordered = {}
local by_mutation = {}

-- Validate and order auxiliary modules so attack order is stable across discovery.
function auxiliary.register(attack)
    if type(attack) ~= "table" or type(attack.id) ~= "string" or
        attack.id == "" or type(attack.order) ~= "number" or
        attack.order % 1 ~= 0 or
        (type(attack.chance) ~= "function" and
            (type(attack.chance) ~= "number" or
                attack.chance < 0 or attack.chance > 100)) or
        type(attack.available) ~= "function" or
        type(attack.describe) ~= "function" or
        registered[attack.id] then
        error("invalid or duplicate auxiliary attack")
    end

    registered[attack.id] = attack
    ordered[#ordered + 1] = attack

    for _, id in ipairs(attack.mutation_ids or {}) do
        catalog.get("mutations", id)
        by_mutation[id] = true
    end

    -- Equal auxiliary priorities use IDs so content discovery cannot reorder attack rolls.
    table.sort(ordered, function(left, right)
        if left.order == right.order then
            return left.id < right.id
        end

        return left.order < right.order
    end)
end

-- The registry gives a specific attack handler without reloading its Lua file.
function auxiliary.get(id)
    return registered[id]
end

-- Coverage checks use the same mutation IDs that unlock registered attacks.
function auxiliary.has_mutation(id)
    return by_mutation[id] == true
end

-- Example: auxiliary.all() with registered attacks -> copied list in priority order
-- Return a copy of the ordered attack list so callers cannot mutate registry order.
function auxiliary.all()
    local attacks = {}

    for index, attack in ipairs(ordered) do
        attacks[index] = attack
    end

    return attacks
end

-- Snapshot player stats and equipment once so every auxiliary contact sees the same attack state.
function auxiliary.input(ctx, target, defender)
    local player = ctx:player()
    local current = attributes.current(ctx, player)
    local progress = ctx:get(player, component.PROGRESSION)
    local durations = ctx:get(player, component.DURATIONS)
    local form = forms.modifiers(ctx, player)
    local species = fighter.species(ctx)
    local worn = combat_equipment.worn(ctx, player, {
        weapon = true,
        shield = true,
        gloves = true,
    })
    local weapon = worn.weapon
    local missing_hand = fighter.mutation(ctx,
        mutations.MUT_MISSING_HAND)
    local second_hand = weapon and equipment_rules.needs_second_hand(ctx,
        player, weapon.definition, species)
    local offhand = missing_hand == 0 and not worn.shield and
        not second_hand
    local arms = species.id == species_ids.SP_OCTOPODE and 8 or 2
    local tentacles = levels.effective(ctx, player,
        mutations.MUT_TENTACLE_ARMS)
    local usable_tentacles = tentacles > 0 and arms or 0
    local form_state = ctx:get(player, component.PLAYER_FORM)
    local form_id = form_state and form_state.remaining_aut > 0 and
        form_state.form_id or ""
    local claws = worn.gloves and 0 or levels.effective(ctx, player,
        mutations.MUT_CLAWS)

    local grip = constriction.snapshot(ctx, target, defender, species,
        worn, usable_tentacles, form.size)

    return {
        level = progress.level,
        horns = fighter.mutation(ctx, mutations.MUT_HORNS),
        hooves = fighter.mutation(ctx, mutations.MUT_HOOVES),
        talons = fighter.mutation(ctx, mutations.MUT_TALONS),
        tentacle_spike = fighter.mutation(ctx, mutations.MUT_TENTACLE_SPIKE),
        reflexive = fighter.mutation(ctx,
            mutations.MUT_REFLEXIVE_HEADBUTT) > 0,
        strength = current.strength + form.strength,
        dexterity = current.dexterity + form.dexterity,
        fighting100 = fighter.skill(ctx, skills.SK_FIGHTING, 100),
        fighting30 = fighter.skill(ctx, skills.SK_FIGHTING, 30),
        defender_ev = defender.ev or 0,
        defender_ac = defender.ac or 0,
        mighty = durations and durations.might_aut > 0 or false,
        offhand = offhand,
        punch_eligible = forms.can_offhand_punch(ctx, player) and
            (arms - missing_hand > 2 or offhand),
        unarmed1 = fighter.skill(ctx, skills.SK_UNARMED_COMBAT, 1),
        unarmed5 = fighter.skill(ctx, skills.SK_UNARMED_COMBAT, 5),
        claws = claws,
        tentacles = tentacles,
        form_id = form_id,
        target = grip.target,
        can_see = grip.can_see,
        adjacent = grip.adjacent,
        confused = grip.confused,
        player_size = grip.player_size,
        target_size = grip.target_size,
        target_immune_to_constriction =
            grip.target_immune_to_constriction,
        existing_grips = grip.existing_grips,
        free_tentacles = grip.free_tentacles,
    }
end

-- Apply strength, Fighting, Might, and armour in the source auxiliary damage order.
function auxiliary.damage(ctx, input, base)
    local potential = math.floor(base *
        math.max(2, 150 + 5 * input.strength) / 2 / 100)
    local damage = roll.melee(ctx, potential)
    local fighting = roll.melee(ctx, input.fighting100 + 1)

    damage = math.floor(damage * (4000 + fighting) / 4000)

    if input.mighty then
        damage = damage + 1 + roll.melee(ctx, 10)
    end

    damage = damage + roll.melee(ctx,
        statuses.wereblood_slay(ctx, ctx:player()) + 1)

    -- Weak scales every raw player melee hit, including natural follow-ups.
    damage = player_weakness.melee_damage(ctx, ctx:player(), damage)

    return math.max(0, damage - roll.armour(ctx, input.defender_ac))
end

-- Source: melee-attack.cc:player_aux_unarmed and player_aux_test_hit.
-- Each file supplies only its eligibility, source chance, and damage facts.
function auxiliary.resolve_one(ctx, input, attack)
    if not attack then
        return { attempted = false }
    end

    local chance = type(attack.chance) == "function" and
        attack.chance(ctx, input) or attack.chance

    if attack.scale_with_level ~= false then
        chance = math.floor(chance * (30 + input.level) / 59)
    end

    -- The source rolls trigger chance before checking whether this body has
    -- the required appendage. This matters for deterministic turn streams.
    if roll.melee(ctx, 100) >= chance or
        not attack.available(ctx, input) then
        return { attempted = false }
    end

    local description = attack.describe(ctx, input)
    local hit_base = math.floor((1300 + input.dexterity * 75 +
        input.fighting30) / 100) + accuracy.hit_bonus(ctx, ctx:player())
    local vertigo = statuses.vertigo_active(ctx, ctx:player()) and 5 or 0
    local to_hit = roll.melee(ctx, hit_base - vertigo)

    to_hit = accuracy.melee_to_hit(ctx, ctx:player(), to_hit)

    local auto_hit = roll.melee(ctx, 30)

    if to_hit < input.defender_ev and auto_hit ~= 0 then
        return {
            attempted = true,
            hit = false,
            name = description.name,
            verb = description.verb,
        }
    end

    local blocked = player_attack.shield_contact(ctx, input, to_hit)

    if blocked then
        return {
            attempted = true,
            hit = false,
            blocked = true,
            name = description.name,
            verb = description.verb,
        }
    end

    local damage = auxiliary.damage(ctx, input, description.base)

    if attack.contact_only then
        damage = 0
    end

    return {
        attempted = true,
        hit = true,
        damage = damage,
        name = description.name,
        verb = description.verb,
    }
end

return auxiliary
