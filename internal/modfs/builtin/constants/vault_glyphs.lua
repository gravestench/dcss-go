-- DES glyphs are map syntax decoded into terrain and placement records.

local glyphs = {}

-- DCSS DES glyph meanings from docs/develop/levels/syntax.txt, pinned source.
glyphs.terrain = {
    x = "DNGN_ROCK_WALL",
    X = "DNGN_PERMAROCK_WALL",
    c = "DNGN_STONE_WALL",
    m = "DNGN_CLEAR_ROCK_WALL",
    n = "DNGN_CLEAR_STONE_WALL",
    o = "DNGN_CLEAR_PERMAROCK_WALL",
    v = "DNGN_METAL_WALL",
    b = "DNGN_CRYSTAL_WALL",
    t = "DNGN_TREE",
    ["."] = "DNGN_FLOOR",
    ["+"] = "DNGN_CLOSED_DOOR",
    ["~"] = "DNGN_CLOSED_CLEAR_DOOR",
    ["="] = "DNGN_RUNED_DOOR",
    W = "DNGN_SHALLOW_WATER",
    w = "DNGN_DEEP_WATER",
    l = "DNGN_LAVA",
    ["{"] = "DNGN_STONE_STAIRS_UP_I",
    ["("] = "DNGN_STONE_STAIRS_UP_II",
    ["["] = "DNGN_STONE_STAIRS_UP_III",
    ["}"] = "DNGN_STONE_STAIRS_DOWN_I",
    [")"] = "DNGN_STONE_STAIRS_DOWN_II",
    ["]"] = "DNGN_STONE_STAIRS_DOWN_III",
    ["<"] = "DNGN_ESCAPE_HATCH_UP",
    [">"] = "DNGN_ESCAPE_HATCH_DOWN",
    G = "DNGN_GRANITE_STATUE",
    I = "DNGN_ORCISH_IDOL",
    A = "DNGN_STONE_ARCH",
    B = "DNGN_RANDOM_ALTAR",
    C = "DNGN_RANDOM_ALTAR",
    T = "DNGN_FOUNTAIN_BLUE",
    U = "DNGN_FOUNTAIN_MAGIC",
    V = "DNGN_FOUNTAIN_DRY",
    Y = "DNGN_FOUNTAIN_BLOOD",
}

glyphs.wall = {
    x = true,
    X = true,
    c = true,
    m = true,
    n = true,
    o = true,
    v = true,
    b = true,
    t = true,
    G = true,
    I = true,
}

glyphs.up = {
    ["{"] = true,
    ["("] = true,
    ["["] = true,
    ["<"] = true,
}

glyphs.down = {
    ["}"] = true,
    [")"] = true,
    ["]"] = true,
    [">"] = true,
}

return glyphs
