-- Theory of operation: each source Treasure Trove map keeps its DES MAP
-- and calls these small helpers at the original script sites. The helpers
-- emit ordinary directives or typed records; placement and population own
-- the resulting terrain and entities. The vetoes read live player skills
-- so the chosen reward theme suits the character.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local fill = require("constants.vault_border_fill")

local shared = {}

-- Every reward map has an exit arch; the visit component later supplies
-- its precise outside return cell rather than guessing a dungeon depth.
local function setup(api)
    api:emit(directives.KFEAT, "< = exit_trove")
end

-- Ordinary good-scroll generation includes useless noise. The source
-- narrows this pool while retaining its authored alternative weights.
local function good_scroll(api)
    api:emit(directives.ITEM,
        "scroll of enchant weapon / scroll of brand weapon w:3 / " ..
        "scroll of enchant armour / scroll of immolation w:8 / " ..
        "scroll of magic mapping w:8 / scroll of blinking / " ..
        "scroll of silence w:2 / scroll of acquirement w:1 / " ..
        "scroll of teleportation w:20 / scroll of vulnerability w:2 / " ..
        "any concealment scroll w:8 / scroll of torment w:8 / " ..
        "scroll of summoning w:1")
end

-- Preserve the garden's blue smoke machine as a typed source marker. The
-- gameplay cloud owner can read it when environmental timing is enabled.
local function blue_smoke(api)
    api:record(effects.MARKER, {
        glyph = "m",
        identity = "fog_machine:blue_smoke",
        pow_max = 30,
        cloud_type = "blue smoke",
        delay_min = 50,
        delay_max = 300,
        size = 12,
        start_clouds = 1,
    })
end

-- This reward island asks the grid to render sea outside its MAP.
local function open_sea(api)
    api:record(effects.BORDER_FILL, {
        style = fill.OPEN_SEA,
    })
end

-- The salt map uses a distinct solid source feature around its MAP.
local function endless_salt(api)
    api:record(effects.BORDER_FILL, {
        style = fill.ENDLESS_SALT,
    })
end

-- Source text renames granite statues in the salt room without changing
-- their blocking and sight properties in the generic terrain grid.
local function ruined_idol(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = "ruined idol",
    })
end

-- Weapon-themed rooms normally avoid a spell specialist, but source
-- leaves a one-in-three chance for variety. A pre-game preview never vets.
local function weapon_veto(api)
    if not api:game_started() then
        return false
    end

    local weapon = api:weapon_skills()
    local spell = api:spell_skills()
    local unarmed = api:unarmed_skill()

    return (weapon < spell or weapon < unarmed) and api:roll(3) ~= 0
end

-- Spell libraries similarly favor spell users while allowing a rare
-- weapon specialist to see one. This is a placement veto, not loot bias.
local function library_veto(api)
    return api:game_started() and
        api:spell_skills() < api:weapon_skills() and
        api:roll(6) ~= 0
end

-- Device-disabled characters cannot use the throne room's chief reward.
-- Low Evocations also vetoes it two times in three, as in source DCSS.
local function misc_veto(api)
    return api:game_started() and
        ((api:evocations_skill() < 4 and api:roll(3) ~= 0) or
            api:cannot_use_devices())
end

shared.setup = setup
shared.good_scroll = good_scroll
shared.blue_smoke = blue_smoke
shared.open_sea = open_sea
shared.endless_salt = endless_salt
shared.ruined_idol = ruined_idol
shared.weapon_eligible = weapon_veto
shared.library_eligible = library_veto
shared.misc_eligible = misc_veto

return shared
