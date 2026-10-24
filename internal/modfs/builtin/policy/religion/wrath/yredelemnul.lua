-- Yredelemnul either fires a draining bolt or reclaims undead gifts and
-- sends hostile servants. Rare derived undead use the committed Dungeon
-- population for their base, not a handwritten second monster roster.
local component = require("constants.component")
local roll = require("policy.combat.roll")
local avatar = require("policy.religion.wrath.avatar")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local souls = require("policy.religion.wrath.yredelemnul.souls")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")
local zombies = require("policy.religion.wrath.yredelemnul.zombies")

local yredelemnul = {}
local MAX_PLACEMENT_FAILURES = 64

-- A sealed floor has no destination for any servant. Stop after the
-- first failed placement there; other floors may retry a different kind
-- whose habitat fits an open adjacent cell.
local function has_open_neighbor(ctx, player)
    local position = ctx:get(player, component.POSITION)

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = position.x + dx
                local y = position.y + dy

                if ctx:walkable(position.level_id, x, y) and
                    not ctx:actor_at(position.level_id, x, y) then
                    return true
                end
            end
        end
    end

    return false
end

-- religion.cc:_yred_servants is ordered by power. The source clamps the
-- upper index after computing its lower index from the unclamped value.
local servants = {
    monsters.MONS_WIGHT,
    monsters.MONS_NECROPHAGE,
    monsters.MONS_SHADOW,
    monsters.MONS_PHANTOM,
    monsters.MONS_WRAITH,
    monsters.MONS_FLYING_SKULL,
    monsters.MONS_FREEZING_WRAITH,
    monsters.MONS_VAMPIRE,
    monsters.MONS_SHADOW_WRAITH,
    monsters.MONS_PHANTASMAL_WARRIOR,
    monsters.MONS_BOG_BODY,
    monsters.MONS_SKELETAL_WARRIOR,
    monsters.MONS_JIANGSHI,
    monsters.MONS_FLAYED_GHOST,
    monsters.MONS_VAMPIRE_KNIGHT,
    monsters.MONS_EIDOLON,
    monsters.MONS_DEATH_COB,
    monsters.MONS_ANCIENT_CHAMPION,
    monsters.MONS_GHOUL,
    monsters.MONS_REVENANT,
    monsters.MONS_SEARING_WRETCH,
    monsters.MONS_PROFANE_SERVITOR,
    monsters.MONS_BONE_DRAGON,
}

-- random2avg(n, 2) widens its second bound by one; the shared roll owner
-- preserves that source distribution for each summon-attempt count.
local function attempts(ctx, level)
    local bound = 1 + math.floor(level / 5)

    return 1 + roll.average_two(ctx, streams.CARDS, bound)
end

-- The hostile servant threshold grows with XL; selected kind and placement
-- use separate draws and the common summon owner writes the permanent body.
local function send_servant(ctx, player, level)
    local upper = 3 + math.floor((#servants - 3) * level / 21)
    local lower = upper <= 6 and 0 or math.floor(upper / 2) + 3
    upper = math.min(upper, #servants - 1)

    local index = lower + ctx:random(streams.CARDS,
        upper - lower + 1)

    return summons.hostile(ctx, player, gods.YREDELEMNUL,
        servants[index + 1]) ~= nil
end

-- Source checks follower reclaim only on the servant half of the coinflip.
-- A failed regular servant placement retries that attempt. Bound its
-- retries because a sealed map otherwise turns source's retry loop into
-- an unending game action; zombie attempts consume their slot either way.
function yredelemnul.apply(ctx, player)
    local level = math.max(1,
        ctx:get(player, component.PROGRESSION).level)

    if ctx:random(streams.CARDS, 2) ~= 0 then
        return avatar.cast(ctx, player, gods.YREDELEMNUL,
            spells.SPELL_BOLT_OF_DRAINING,
            "Yredelemnul's anger turns toward you for a moment.")
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if worship.god_id == gods.YREDELEMNUL and
        ctx:random(streams.CARDS, 2) == 0 then
        if souls.reclaim(ctx, player) then
            return true
        end
    end

    local remaining = attempts(ctx, level)
    local count = 0
    local failures = 0

    while remaining > 0 and
        failures < MAX_PLACEMENT_FAILURES do
        if ctx:random(streams.CARDS, level) == 0 then
            if zombies.spawn(ctx, player, level) then
                count = count + 1
            end

            remaining = remaining - 1
        elseif send_servant(ctx, player, level) then
            count = count + 1
            remaining = remaining - 1
            failures = 0
        else
            failures = failures + 1

            if not has_open_neighbor(ctx, player) then
                break
            end
        end
    end

    ctx:emit("religion", count > 1 and
        "Yredelemnul sends servants to punish you." or
        count == 1 and "Yredelemnul sends a servant to punish you." or
        "Yredelemnul's servants fail to arrive.")

    return true
end

return yredelemnul
