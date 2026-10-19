-- Example: Most clurvy layouts break a pillar; rarer draws add an altar, debris, or tree-color ruin.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")

local handler = {}

-- Most clurvy layouts break a pillar; rarer draws add an altar, debris, or tree-color ruin.
local function choose_broken_pillar(api)
    if not api:one_in(5) then
        return
    end

    api:emit(directives.NSUBST, ". = 3:A / .")
    api:emit(directives.SUBST, "t = ttG")
    api:emit(directives.TILE, "G = dngn_crumbled_column")
    api:emit(directives.COLOUR, "G = white")
    api:record(effects.FEATURE_NAME, {
        feature = "granite_statue",
        name = "broken pillar",
    })
end

-- The optional altar placement consumes its own one-in-five draw after pillar edits.
local function choose_altar_spot(api)
    if api:one_in(5) then
        api:emit(directives.NSUBST, ". = 1:J / 3:K / 1:V / .")
    end
end

-- Debris placement is an independent rare substitution over remaining floor glyphs.
local function choose_debris_spot(api)
    if api:one_in(5) then
        api:emit(directives.NSUBST, "1 = 4:4 / 1, . = 5:U / .")
    end
end

-- The second draw only happens if the first one fails.
local function choose_colour_ruin(api)
    if api:one_in(5) then
        api:emit(directives.COLOUR, "t = yellow w:5 / red w:5 / brown")
        api:emit(directives.SUBST, "1 = 1222")
    elseif api:one_in(5) then
        api:emit(directives.SUBST, "1 = 3, U = VVVJK")
        api:emit(directives.KFEAT, "t = petrified_tree")
    end
end

handler.choose_broken_pillar = choose_broken_pillar
handler.choose_altar_spot = choose_altar_spot
handler.choose_debris_spot = choose_debris_spot
handler.choose_colour_ruin = choose_colour_ruin

return handler
