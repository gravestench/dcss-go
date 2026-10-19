-- Doom Howl has two saved owners: the hound's one-use mark and the player's
-- echo timer. Keeping IDs together lets mods inspect either state directly.
local monsters = require("ids.monsters")

local ids = {
    MONSTER_DOOM_HOWLED = "combat.monster_doom_howled",
    PLAYER_DOOM_HOWL = "combat.player_doom_howl",
    ARRIVAL = "combat.doom_arrival",
    REWARDS = "combat.doom_arrival_rewards",
    BEASTS = {
        monsters.MONS_BONE_DRAGON,
        monsters.MONS_REAPER,
        monsters.MONS_TORMENTOR,
        monsters.MONS_TZITZIMITL,
        monsters.MONS_PUTRID_MOUTH,
    },
}

-- Save validation uses the same five source kinds as the live arrival draw.
function ids.beast(kind_id)
    for _, candidate in ipairs(ids.BEASTS) do
        if candidate == kind_id then
            return true
        end
    end

    return false
end

return ids
