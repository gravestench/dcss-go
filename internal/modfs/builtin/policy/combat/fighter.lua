local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local statuses = require("policy.magic.effects.statuses.player")
local forms = require("policy.magic.effects.forms.player")

local fighter = {}

local function required(ctx, entity, component)
    local value = ctx:get(entity, component)

    if not value then
        error("fighter lacks " .. component)
    end

    return value
end

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

function fighter.species(ctx)
    local choice = required(ctx, ctx:player(), "core.player")

    return catalog.get("species", choice.species_id)
end

function fighter.skill(ctx, id, scale)
    local skills = required(ctx, ctx:player(), "core.skills")
    local species = fighter.species(ctx)
    local aptitude = species.aptitudes[id]

    if not aptitude or not aptitude.allowed then
        error("fighter cannot use skill " .. id)
    end

    for _, entry in ipairs(skills.entries) do
        if entry.id == id then
            if entry.level == 27 then
                return 27 * scale
            end

            local previous = cost(entry.level, aptitude.value)
            local next_cost = cost(entry.level + 1, aptitude.value)

            return entry.level * scale +
                math.floor((entry.points - previous) * scale / (next_cost - previous))
        end
    end

    return 0
end

function fighter.skill_level(ctx, id)
    local skills = required(ctx, ctx:player(), "core.skills")

    for _, entry in ipairs(skills.entries) do
        if entry.id == id then
            return entry.level
        end
    end

    return 0
end

function fighter.mutation(ctx, id)
    local species = fighter.species(ctx)
    local progress = required(ctx, ctx:player(), "core.progression")
    local total = 0

    for _, mutation in ipairs(species.mutations or {}) do
        if mutation.id == id and mutation.level <= progress.level then
            total = total + mutation.amount
        end
    end

    return total + forms.mutation_level(ctx, ctx:player(), id)
end

function fighter.attack(ctx, defender)
    local player = ctx:player()
    local attributes = required(ctx, player, "core.attributes")
    local form = forms.modifiers(ctx, player)
    local worn = equipment.worn(ctx, player, { weapon = true })
    local weapon = worn.weapon
    local input = {
        strength = attributes.strength + form.strength,
        dexterity = attributes.dexterity + form.dexterity,
        fighting100 = fighter.skill(ctx, "SK_FIGHTING", 100),
        defender_ev = defender.ev or 0,
        defender_ac = defender.ac or 0,
        mighty = false,
        slay = statuses.wereblood_slay(ctx, player),
    }

    local durations = ctx:get(player, "core.durations")
    input.mighty = durations and durations.might_aut > 0 or false

    if weapon then
        local definition = weapon.definition

        if not definition.weapon then
            error("equipped weapon lacks melee properties")
        end

        local launcher = definition.weapon.ammo_id ~= nil and
            definition.weapon.ammo_id ~= "MI_NONE"
        input.held_non_melee = launcher
        input.using_weapon = not launcher
        input.weapon_skill = launcher and "SK_FIGHTING" or
            definition.weapon.skill_id
        input.weapon_damage = launcher and 0 or definition.weapon.damage
        input.weapon_hit = launcher and 0 or definition.weapon.hit
        input.weapon_speed = definition.weapon.speed
        input.weapon_plus = launcher and 0 or weapon.item.plus
        input.weapon100 = fighter.skill(ctx, input.weapon_skill, 100)
    else
        input.unarmed = true
        input.using_weapon = false
        input.weapon_skill = "SK_UNARMED_COMBAT"
        input.weapon_damage = 0
        input.weapon_hit = 0
        input.weapon_plus = 0
        input.weapon100 = fighter.skill(ctx, input.weapon_skill, 100)
        input.unarmed256 = fighter.skill(ctx, input.weapon_skill, 256)
    end

    return input
end

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

function fighter.defense(ctx)
    local player = ctx:player()
    local attributes = required(ctx, player, "core.attributes")
    local form = forms.modifiers(ctx, player)
    local state = required(ctx, player, "core.combat")
    local worn = equipment.worn(ctx, player, {
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
    local body_encumbrance = math.floor(-body.ev / 10)
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
    local ev = math.floor((natural_ev + 99) / 100)
    local factor = 440 + armour_skill * 20
    local scaled_ac = math.floor(body.ac * 100 * factor / 440) + body.plus * 100

    for _, piece in ipairs(auxiliary) do
        scaled_ac = scaled_ac + math.floor(piece.ac * 100 * factor / 440) + piece.plus * 100
    end

    scaled_ac = scaled_ac + statuses.ice_armour_bonus_x100(ctx, player,
        body_encumbrance)
    scaled_ac = scaled_ac + form.ac_x100

    local ac = math.max(0, math.floor(scaled_ac / 100))
    local shield_class = 0

    if shield.ac > 0 then
        local base = shield.ac * 2
        local value = base * 50 + math.floor(base * (shields_skill * 5) / 2) +
            shields_skill * 38 + math.min(shields_skill * 38, 3 * 38) +
            math.floor(dexterity * 38 * (base + 13) / 26) + shield.plus * 200
        shield_class = math.max(0, math.floor((value + 50) / 100))
    end

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
    }
end

return fighter
