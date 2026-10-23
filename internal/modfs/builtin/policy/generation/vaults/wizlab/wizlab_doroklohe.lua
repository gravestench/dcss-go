-- Theory of operation: Doroklohe has two exclusive source layouts.
-- Each DES hook executes where the old inline Lua appeared. The rare
-- regular grid, ordinary damaged grid, and round room share one MAP
-- but must not apply each other's substitutions. Source callbacks
-- become typed markers for the live lab event owner.
local shared = require("policy.generation.vaults.wizlab.shared")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local loot = require("constants.vault_loot")
local names = require("constants.vault_feature_names")
local wizlab = require("constants.wizlab")

local map = {}

-- Source make_box changed the eight neighboring glyphs. Snapshot the
-- centers first so an adjacent edit cannot change which boxes exist.
local function box_glyph(api, center, border)
    local width, height = api:map_size()
    local points = {}

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if api:cell(x, y) == center then
                points[#points + 1] = { x = x, y = y }
            end
        end
    end

    for _, point in ipairs(points) do
        for dy = -1, 1 do
            for dx = -1, 1 do
                local x = point.x + dx
                local y = point.y + dy

                if (dx ~= 0 or dy ~= 0) and
                    x >= 1 and y >= 1 and x < width and y < height then
                    api:set_cell(x, y, border)
                end
            end
        end
    end
end

-- The source's first block only declared make_box and box_glyph. Lua
-- loads their port above before any site invokes it.
function map.site_1(_api)
end

-- Choose one layout exactly once. Only the rare regular grid erases
-- its irregular letter geometry before the round/grid branch.
function map.site_2(api)
    local layout = api:roll(13)
    api:remember("dorok_layout", layout)

    if layout < 3 then
        api:emit(directives.SUBST,
            "bcdefghijk = ., lmnopqrstu = .")
        api:emit(directives.SUBST,
            "B=b, C=c, D=d, E=e, F=f, G=g, H=h, I=i, J=j, K=k")
        api:emit(directives.SUBST,
            "L=l, M=m, N=n, O=o, P=p, Q=q, R=r, S=s, T=t, U=u")
    end
end

-- Round rooms erase both sets of lettered boxes and keep the dark
-- marked ring. Grid-only directives must not run afterward.
function map.site_3(api)
    if api:recall("dorok_layout") <= 9 then
        return
    end

    api:emit(directives.COLOUR, "_ = darkgrey")
    api:emit(directives.KFEAT, "_ = stone_wall")
    api:emit(directives.TILE,
        "_ = wall_stone_black_marked / wall_stone_dark w:4 / wall_stone_black_marked")
    api:emit(directives.SUBST,
        "bcdefghijk = ., lmnopqrstu = .")
    api:emit(directives.SUBST,
        "BCDEFGHIJK = ., LMNOPQRSTU = .")
end

-- Grid rooms selectively keep their lettered tombs. The source uses
-- NSUBST before SHUFFLE so only three randomized outer boxes break.
function map.site_4(api)
    if api:recall("dorok_layout") > 9 then
        return
    end

    api:emit(directives.SUBST, "_ = .")
    api:emit(directives.SUBST, "*=., %=.")
    api:emit(directives.SUBST,
        "B=b, C=c, D=d, E=e, F=f, G=g, H=h, I=i, J=j, K=k")
    api:emit(directives.SUBST,
        "L=l, M=m, N=n, O=o, P=p, Q=q, R=r, S=s, T=t, U=u")

    for letter in ("bcdefghijklmnopqrstu"):gmatch(".") do
        api:emit(directives.NSUBST,
            letter .. " = 1:" .. letter .. " / *:.")
    end

    api:emit(directives.SHUFFLE, "bcdefghijklm")
end

-- At this hook SHUFFLE has already touched the MAP. Damage three
-- selected tomb rings, then distribute six small and seven large
-- tombs as the source grid branch did.
function map.site_5(api)
    if api:recall("dorok_layout") > 9 then
        return
    end

    box_glyph(api, "b", "X")
    box_glyph(api, "c", "Y")
    box_glyph(api, "d", "Z")
    api:emit(directives.SUBST, "bcd = .")
    api:emit(directives.NSUBST, "X = 1=. / *=!:20 .:1")
    api:emit(directives.NSUBST, "Y = 1=. / *=!:30 .:1")
    api:emit(directives.NSUBST, "Z = 1=. / *=!:50 .:1")
    api:emit(directives.SHUFFLE, "nqru")
    api:emit(directives.SUBST, "efghijklmn = %")
    api:emit(directives.SUBST, "opqrstu = *")
end

-- The source site only closed the conditional started at site 3.
-- The following monster choice is independent of room geometry.
function map.site_6(_api)
end

-- One in three rooms uses demons. Keep keyed monster rules scoped to
-- that draw; emitting both rosters would populate the same glyph twice.
function map.site_7(api)
    local demons = api:roll(3) == 0
    api:remember("dorok_demons", demons)

    if demons then
        api:emit(directives.KMONS,
            "0% = smoke demon / ynoxinul / neqoxec w:6 / ice devil / " ..
            "chaos spawn / soul eater / sun demon")
        api:emit(directives.KMONS,
            "* = lorocyproca / reaper / shadow demon / tormentor / hellion / " ..
            "blizzard demon / green death / balrug / cacodemon")
        api:emit(directives.KMONS,
            "| = hell sentinel / brimstone fiend / tzitzimitl / " ..
            "ice fiend / executioner")
    end
end

-- The else site installs the mummy roster only when the demon draw
-- failed, along with the matching ambient shadow-creature list.
function map.site_8(api)
    if api:recall("dorok_demons") then
        shared.random_monsters(api,
            "smoke demon / ynoxinul / neqoxec / " ..
            "chaos spawn / soul eater / sun demon / " ..
            "lorocyproca / reaper / shadow demon / tormentor / hellion")
        return
    end

    api:emit(directives.KMONS,
        "0% = place:Depths:1 zombie / guardian mummy w:4")
    api:emit(directives.KMONS, "* = zombie / mummy priest w:6")
    api:emit(directives.KMONS,
        "| = ancient lich / dread lich / royal mummy w:20")
end

-- The final source line supplies the mummy ambient roster; for a
-- demon room it only closed the already-applied conditional.
function map.site_9(api)
    if not api:recall("dorok_demons") then
        shared.random_monsters(api,
            "place:Depths:1 zombie / zombie / guardian mummy")
    end
end

-- Loot draws independently from layout and monsters. This first site
-- emits the scroll ring before the source's good-scroll list site.
function map.site_10(api)
    local choice = api:roll(3)
    api:remember("dorok_loot", choice)

    if choice == 0 then
        api:emit(directives.KITEM,
            "% = any scroll / any scroll q:2 w:3 / any scroll q:3 w:1")
    end
end

-- Source dungeon.lua owns the common good-scroll weights; importing
-- them here avoids a second drifting copy of the entire list.
function map.site_11(api)
    if api:recall("dorok_loot") ~= 0 then
        return
    end

    api:emit(directives.KITEM, "* = " .. loot.GOOD_SCROLLS)
    api:emit(directives.KITEM,
        "| = scroll of acquirement q:1 ident:type / " ..
        "scroll of enchant weapon q:3 ident:type / " ..
        "scroll of blinking q:2 ident:type, " ..
        "any concealment scroll q:2 ident:type")
end

-- Armour rooms use the source's middle loot alternative exclusively.
function map.site_12(api)
    if api:recall("dorok_loot") ~= 1 then
        return
    end

    api:emit(directives.KITEM, "% = any armour")
    api:emit(directives.KITEM, "* = any good_item armour")
    api:emit(directives.KITEM,
        "| = robe ego:resistance ident:type / gold dragon scales")
end

-- The remaining source branch mixes ordinary, star, and superb items.
function map.site_13(api)
    if api:recall("dorok_loot") ~= 2 then
        return
    end

    api:emit(directives.KITEM, "% = any / star_item w:2")
    api:emit(directives.KITEM,
        "* = star_item / superb_item w:2")
    api:emit(directives.KITEM, "| = superb_item")
end

-- The source site only closes the loot conditional.
function map.site_14(_api)
end

-- Build the delayed drop walls around every populated tomb. This is
-- after all room substitutions so it sees the final content glyphs.
function map.site_15(api)
    box_glyph(api, "%", "!")
    box_glyph(api, "*", "!")
    box_glyph(api, "|", "!")
end

-- The timed three-phase wall conversion is live state, not generation
-- randomness. Its event owner materializes the marker at the A glyph.
function map.site_16(api)
    api:emit(directives.MARKER,
        "A = " .. wizlab.DOROK_BOX_MARKER)
end

-- Feature names are local to this room, while setup supplies its
-- shared return arches after all boxes have been generated.
function map.site_17(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.ROCK_WALL,
        name = names.WIZLAB_STRANGE_ROCK_WALL,
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.STONE_WALL,
        name = names.WIZLAB_DECORATED_STONE_WALL,
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.FLOOR,
        name = names.WIZLAB_ROUGH_FLOOR,
    })
    shared.setup(api)
end

-- Name this lab only on first arrival, after travel has committed.
function map.epilogue(api)
    shared.epilogue(api, "Doroklohe's Tomb")
end

return map
