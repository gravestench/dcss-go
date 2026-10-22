-- Theory of operation: each source Bailey entrance chooses an axe or
-- polearm theme once. Decorations, guards, and the timed marker all use
-- that choice. The marker persists the theme so destination generation
-- never redraws it after the player finds the gate.
local bailey = require("constants.bailey")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local shared = {}

-- The source draws duration after theme and writes a single timed marker.
-- Fixed low and high bounds carry the result into ECS without another roll.
local function portal(api, theme)
    local turns = bailey.MIN_DURATION_TURNS +
        api:roll(bailey.DURATION_RANGE_TURNS)

    api:emit(directives.MARKER,
        'O = lua:timed_marker { low = ' .. turns ..
        ', high = ' .. turns ..
        ', bailey_type = "' .. theme ..
        '", single_timed = true, floor = "' ..
        bailey.EXPIRED_MARKER_FLOOR ..
        '", feat_tile = "dngn_portal_bailey_gone", ' ..
        'disappear = "The portal closes with a thud." }')
    api:emit(directives.KFEAT, "O = enter_bailey")
    api:emit(directives.TILE, "c = wall_stone_smooth")
end

-- This draw precedes all map-local conditional content. Its bound is two,
-- matching the source's `crawl.random2(2)` rather than two independent
-- coinflips for the gate and its decorations.
local function theme(api)
    if api:roll(2) == 0 then
        return bailey.AXE
    end

    return bailey.POLEARM
end

-- The single-cell entrance has no themed neighbors, but still records
-- the chosen theme and finite portal deadline.
local function entry_1(api)
    portal(api, theme(api))
end

-- These weapons make the two possible Bailey themes visible in the
-- approach room without making a second choice at the ITEM stage.
local function entry_2(api)
    local chosen = theme(api)

    if chosen == bailey.AXE then
        api:emit(directives.ITEM, "hand axe")
    else
        api:emit(directives.ITEM, "halberd / spear")
    end

    portal(api, chosen)
end

-- The goblin's weapon matches the destination family. The surrounding
-- source KMASK remains in DES because it is independent of the theme.
local function entry_3(api)
    local chosen = theme(api)

    if chosen == bailey.AXE then
        api:emit(directives.MONS, "goblin ; hand axe")
    else
        api:emit(directives.MONS, "goblin ; spear")
    end

    portal(api, chosen)
end

-- The larger fort gives axe defenders boomerangs and widens one guard
-- slot; polearm defenders keep their longer melee weapons instead.
local function entry_4(api)
    local chosen = theme(api)

    if chosen == bailey.AXE then
        api:emit(directives.MONS,
            "goblin ; hand axe / hobgoblin ; hand axe / orc ; hand axe")
        api:emit(directives.MONS,
            "goblin ; boomerang ident:type q:2 | " ..
            "boomerang ident:type q:1 / " ..
            "hobgoblin ; boomerang ident:type q:2 | " ..
            "boomerang ident:type q:1 / " ..
            "orc ; boomerang ident:type q:2 | " ..
            "boomerang ident:type q:1")
        api:emit(directives.SUBST, "1 = 122")
    else
        api:emit(directives.MONS,
            "goblin ; spear / hobgoblin ; spear / orc ; spear")
    end

    portal(api, chosen)
end

-- The shuffled gatehouse keeps its source boomerang count on the axe
-- branch, while the polearm branch gets a spear-bearing goblin.
local function entry_5(api)
    local chosen = theme(api)

    if chosen == bailey.AXE then
        api:emit(directives.MONS,
            "goblin ; boomerang ident:type q:2 | " ..
            "boomerang ident:type q:1")
    else
        api:emit(directives.MONS, "goblin ; spear")
    end

    portal(api, chosen)
end

-- The source names and tiles these statues at the same conditional site.
-- A typed feature-name record keeps the description local to this vault.
local function statue(api, chosen)
    local name = names.BAILEY_AXE_STATUE
    local tile = "dngn_statue_axe"

    if chosen == bailey.POLEARM then
        name = names.BAILEY_POLEARM_STATUE
        tile = "dngn_statue_polearm"
    end

    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = name,
    })
    api:emit(directives.TILE, "G = " .. tile)
end

-- The first statue approach retains its preceding colour and terrain
-- substitutions in DES; only the statue theme belongs to this hook.
local function entry_6(api)
    local chosen = theme(api)

    statue(api, chosen)
    portal(api, chosen)
end

-- The party's weapon choice is visible before the player reaches the
-- gate. Its degeneration potion cells are fixed DES declarations.
local function entry_7(api)
    local chosen = theme(api)

    if chosen == bailey.AXE then
        api:emit(directives.MONS,
            "gnoll ; hand axe / goblin ; hand axe")
    else
        api:emit(directives.MONS,
            "gnoll ; spear / goblin ; spear")
    end

    portal(api, chosen)
end

-- This second statue approach uses the same source conditional naming
-- as entry 6, while its corridor and masks remain authored in DES.
local function entry_8(api)
    local chosen = theme(api)

    statue(api, chosen)
    portal(api, chosen)
end

-- The large fortress keeps two axe guard requests or one polearm request
-- before creating the gate. Their equipment remains a source expression.
local function fortress(api)
    local chosen = theme(api)

    if chosen == bailey.AXE then
        api:emit(directives.MONS,
            "orc ; boomerang ident:type q:1 | " ..
            "boomerang ident:type q:2 . hand axe")
        api:emit(directives.MONS,
            "gnoll ; hand axe / goblin ; hand axe")
    else
        api:emit(directives.MONS,
            "orc ; spear, gnoll ; spear / goblin ; spear")
    end

    portal(api, chosen)
end

shared.entry_1 = entry_1
shared.entry_2 = entry_2
shared.entry_3 = entry_3
shared.entry_4 = entry_4
shared.entry_5 = entry_5
shared.entry_6 = entry_6
shared.entry_7 = entry_7
shared.entry_8 = entry_8
shared.fortress = fortress

return shared
