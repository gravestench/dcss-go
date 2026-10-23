-- Source Tomb scripts set local monster arrays, hatch markers, traps, and
-- feature names. The DES files retain the geometry and call these functions
-- at the exact positions of the old embedded Lua statements.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")
local fill = require("constants.vault_border_fill")
local hatches = require("policy.generation.tomb.hatch_markers")

local hooks = {}

local guardian_sets = {
    "ushabti w:119 / guardian mummy w:79 / mummy w:28 / " ..
        "skeletal warrior w:8 / ancient champion w:8 / bennu w:8",
    "guardian mummy w:119 / death scarab band w:79 / mummy w:28 / " ..
        "skeletal warrior w:8 / ancient champion w:8 / bennu w:8",
    "guardian mummy w:98 / mummy w:18 / skeletal warrior w:38 / " ..
        "ancient champion w:28 / bennu w:28",
}

-- Choose among the least-used guardian pools in this three-floor build.
-- Source Crawl stores this counter in dgn.persist; the bundle owns it for
-- its entire construction and saves only the resolved monster records.
local function choose_guardian(api)
    local counts = api:setting("guardian_counts") or {
        0,
        0,
        0,
    }
    local minimum = math.min(counts[1], counts[2], counts[3])
    local chosen
    local seen = 0

    for index, count in ipairs(counts) do
        if count == minimum then
            seen = seen + 1

            if api:roll(seen) == 0 then
                chosen = index
            end
        end
    end

    counts[chosen] = counts[chosen] + 1

    return guardian_sets[chosen]
end

-- An optional monster slot is used in Tomb:1, where some cells stay empty.
function hooks.guardian_optional(api)
    api:emit(directives.MONS, choose_guardian(api) .. " / nothing w:248")
end

-- Deeper floors use the selected guardian pool without the empty option.
function hooks.guardian(api)
    api:emit(directives.MONS, choose_guardian(api))
end

-- The later floors reserve separate slots for priests and royal mummies.
function hooks.mummy_priests(api)
    api:emit(directives.MONS,
        "mummy priest w:20 / lich w:2 / revenant w:2")
    api:emit(directives.MONS, "royal mummy")
end

-- The centre's five source slots graduate from mummies to a statue.
-- Attach both hatch roles before following substitutions can erase `>`.
function hooks.centre_setup(api)
    api:emit(directives.MONS, "mummy / skeletal warrior w:1 / nothing")
    hooks.guardian_optional(api)
    api:emit(directives.MONS,
        "mummy priest w:30 / revenant w:5 / lich w:5 / nothing w:30")
    api:emit(directives.MONS, "royal mummy / nothing w:11")
    api:emit(directives.MONS,
        "obsidian statue / orange crystal statue")
    api:emit(directives.KFEAT,
        "^ = alarm trap w:5 / dispersal trap / net trap / zot trap")
    api:emit(directives.SUBST, ". = ^ .:490")
    hatches.name_tomb2_entry(api)
    hatches.dest_tomb2_exit(api)
end

-- Hall glyphs P/Q/R are source route roles, not interchangeable stairs.
-- Their markers must be anchored before each glyph becomes floor or stair.
function hooks.hall_setup(api)
    hatches.dest_tomb1_hall_entry(api)
    api:emit(directives.SUBST, "P = .")
    hatches.name_tomb1_hall_exit_1(api)
    api:emit(directives.SUBST, "Q = >")
    hatches.name_tomb1_hall_exit_2(api)
    api:emit(directives.SUBST, "R = >")
    hooks.guardian_optional(api)
    api:emit(directives.MONS,
        "mummy priest w:30 / revenant w:5 / lich w:5 / nothing w:30")
    api:emit(directives.MONS, "royal mummy")
    api:emit(directives.SUBST, ". = 3:12 ^ .:230")
    api:emit(directives.KFEAT,
        "^ = alarm trap / dispersal trap / net trap / zot trap")
end

-- The ambush receives two named routes at R. One S becomes the single
-- return hatch; the other candidate cells become ordinary floor.
function hooks.ambush_setup(api)
    hooks.guardian(api)
    hooks.mummy_priests(api)
    hatches.dest_tomb2_entry(api)
    hatches.dest_tomb1_hall_exit_1(api)
    api:emit(directives.SUBST, "R = .")
    hatches.name_tomb2_exit_ambush(api)
    api:emit(directives.NSUBST, "S = 1:< / *:.")
    api:emit(directives.SUBST, ". = ^ .:740")
    api:emit(directives.KFEAT,
        "^ = alarm trap / dispersal trap / net trap / zot trap")
end

-- Each Tomb:3 rune room reserves its O glyph for the golden rune and
-- masks ambient items there. Other loot remains in the whole-floor DES.
function hooks.rune_setup(api)
    hooks.guardian(api)
    hooks.mummy_priests(api)
    api:emit(directives.KMASK, "O = no_item_gen")
    api:emit(directives.KITEM, "O = golden rune of Zot")
    api:emit(directives.KMONS,
        "K = Khufu w:3 / royal mummy, royal mummy")
    api:emit(directives.KFEAT,
        "^ = alarm trap / dispersal trap / net trap / zot trap")
    api:emit(directives.SUBST, ". = ^ .:490")
end

-- Doroklohe's rune glyph itself may guard Khufu, beyond the common K slot.
function hooks.khufu_rune(api)
    api:emit(directives.KMONS,
        "O = Khufu w:3 / royal mummy, royal mummy")
end

-- The paired statue decoration only changes with this one source coinflip.
-- Both choices leave the later common statue substitution in the DES.
function hooks.choose_statues(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "I = I:900 5, N = N:900 5")
        api:emit(directives.SUBST, "J = J:750 5, O = O:750 5")
        api:emit(directives.SUBST, "K = K:550 5, P = P:550 5")
        api:emit(directives.SUBST, "L = L:300 5, Q = Q:300 5")
    end
end

-- A sarcophagus is still granite statue terrain; this map-local name
-- changes inspection text without changing collision or sight rules.
function hooks.sarcophagus(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.SARCOPHAGUS,
    })
end

-- Source escape hatches use the normal linked-stair grid but keep their
-- one-way descriptions in saved feature-name records.
function hooks.hatch_down_name(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.ESCAPE_HATCH_DOWN,
        name = names.ONE_WAY_DOWN,
    })
end

-- The upward hatch has a different command direction and source label.
function hooks.hatch_up_name(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.ESCAPE_HATCH_UP,
        name = names.ONE_WAY_UP,
    })
end

-- The edge outside Tomb's authored rectangle is permanent rock, so a
-- generic border fill cannot open an unintended shortcut around a wall.
function hooks.permarock_border(api)
    api:record(effects.BORDER_FILL, {
        style = fill.PERMAROCK_WALL,
    })
end

return hooks
