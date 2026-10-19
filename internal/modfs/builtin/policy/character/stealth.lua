-- Example: A heavy body armour penalty is applied after its stealth ego bonus.
local attributes = require("policy.character.attributes")
local armour_egos = require("constants.armour_egos")
local armour_flags = require("constants.armour_flags")
local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local confusion = require("policy.magic.player_confusion")
local statuses = require("policy.magic.effects.statuses.player")
local water = require("policy.character.water")
local skills = require("ids.skills")
local hex_status = require("policy.combat.monster_hexes.status")

local stealth = {}

local armour_slots = {
    body = true,
    head = true,
    cloak = true,
    gloves = true,
    boots = true,
}

-- Worn armour egos contribute before the body encumbrance deduction.
local function armour_bonus(worn)
    local bonus = 0

    for _, entry in pairs(worn) do
        local armour = entry.definition.armour

        if armour then
            local flags = type(armour.flags) == "table" and
                armour.flags or {}

            for _, flag in ipairs(flags) do
                if flag.id == armour_flags.STEALTH then
                    bonus = bonus + 50 * flag.level
                end
            end

            if entry.ego == armour_egos.STEALTH then
                bonus = bonus + 50
            end
        end
    end

    return bonus
end

-- Body armour evasion and sturdiness determine the stealth encumbrance penalty.
local function body_penalty(ctx, player)
    local body = equipment.worn(ctx, player, { body = true }).body

    if not body then
        return 0
    end

    local evasion = body.definition.armour.ev
    local sturdy = effects.sum(ctx, player,
        capabilities.BODY_ENCUMBRANCE_REDUCTION)
    local encumbrance = math.max(0, math.floor(-evasion / 10) - sturdy)

    return math.floor(2 * encumbrance * encumbrance / 3)
end

-- Combine dexterity and trained Stealth before armour, water, and visibility penalties are applied.
function stealth.score(ctx, player)
    if effects.sum(ctx, player, capabilities.STEALTH_FORBIDDEN) > 0 then
        return 0
    end

    local dexterity = attributes.current(ctx, player).dexterity
    local skill = fighter.skill(ctx, skills.SK_STEALTH, 15)
    local score = dexterity * 3 + skill

    if confusion.active(ctx, player) then
        score = math.floor(score / 3)
    end

    score = score - body_penalty(ctx, player)
    score = score + armour_bonus(equipment.worn(ctx, player,
        armour_slots))

    score = score + effects.sum(ctx, player, capabilities.STEALTH_BONUS)

    if statuses.silence_radius(ctx, player) >= 0 then
        score = score - 50
    end

    if water.at(ctx, player) then
        if effects.sum(ctx, player,
            capabilities.SWIMMER_LEVEL) > 0 then
            score = score + 50
        elseif water.immersed(ctx, player) and
            not water.can_swim(ctx, player) then
            score = math.floor(score / 2)
        end
    end

    -- player.cc:player_stealth applies backlighting after additive sources.
    if effects.sum(ctx, player, capabilities.BACKLIT) > 0 or
        hex_status.backlit(ctx, player) then
        score = math.floor(score * 2 / 5)
    end

    return math.max(0, score)
end

return stealth
