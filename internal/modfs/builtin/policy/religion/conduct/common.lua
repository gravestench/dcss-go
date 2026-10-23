-- Shared source response shapes keep the same kill curve and common
-- good-god prohibitions in one readable place. A god imports only the
-- responses it actually uses; adding a god never grows a central switch.
local kinds = require("constants.religion_conduct")
local monsters = require("ids.monsters")

local common = {}

-- A neutral-then-hostile holy creature or a no-reward wrath creature still
-- matters to a good god. Ordinary hostile holy enemies do not.
function common.holy_matters(_, _, event)
    return event.was_neutral == true or event.no_reward == true
end

-- Gods can tolerate an ally that the source marks as expendable. Combat
-- classification supplies this fact before the victim is destroyed.
function common.friend_matters(_, _, event)
    return event.friend_hated ~= false
end

-- Beogh protects allied orcs, not every creature that happens to fight
-- beside the player. Genus preserves this rule for modded orc subtypes.
function common.orc_friend(_, _, event)
    return event.friend_hated ~= false and
        event.genus_id == monsters.MONS_ORC
end

-- Jiyva protects real slimes. A known shapeshifter wearing a slime shape
-- is not a member of the god's family.
function common.slime_friend(_, _, event)
    return event.friend_hated ~= false and event.slime == true and
        event.shapeshifter ~= true
end

-- Fedhas only protects plant-class creatures, including modded variants.
function common.plant_friend(_, _, event)
    return event.friend_hated ~= false and event.plant == true
end

-- Build the source's standard kill response. The bonus depends on the
-- victim's holiness, while good gods omit the player-XL divisor.
function common.kill(description, bonus, good)
    return {
        description = description,
        bonus = bonus,
        denom_bonus = 18,
        xl_denom = good and 0 or 2,
        message = " accepts your kill.",
    }
end

-- Five ordinary kill classes are repeated across several source gods.
-- Returning a fresh table keeps god modules independent for mod overlays.
function common.kills()
    return {
        [kinds.KILL_LIVING] = common.kill("you kill living beings", -6),
        [kinds.KILL_UNDEAD] = common.kill("you destroy the undead", -5),
        [kinds.KILL_DEMON] = common.kill("you kill demons", -4),
        [kinds.KILL_HOLY] = common.kill("you kill holy beings", -3),
        [kinds.KILL_NONLIVING] = common.kill(
            "you destroy nonliving beings", -6),
    }
end

-- A common good-god offense starts from the source's piety and penance
-- factors. Per-god modules can override one field without copy-paste.
function common.peeve(description, loss, penance, forgiveness, filter)
    return {
        description = description,
        loss_factor = loss,
        penance_factor = penance,
        forgiveness = forgiveness,
        filter = filter,
    }
end

-- Three good gods share the same penalty for killing a holy creature that
-- had been neutral; the attack offense is deliberately a separate rule.
function common.kill_holy_peeve()
    return common.peeve("you kill non-hostile holy beings", 3, 3,
        nil, common.holy_matters)
end

-- An accidental strike against a disliked ally gets one explicit pardon.
function common.attack_friend(description, filter)
    return common.peeve(description, 1, 3,
        " forgives your inadvertent attack on an ally, just this once.",
        filter or common.friend_matters)
end

return common
