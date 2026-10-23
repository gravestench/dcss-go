-- Vault colour tokens are presentation choices; random selection happens during placement.

-- Source: crawl-ref/source/mon-util.cc random_monster_colour.
local colours = {
    ANY = "any",
    MUTAGENIC = "mutagenic",
    VEHUMET = "vehumet",
    RANDOM = {
        "black",
        "blue",
        "green",
        "cyan",
        "red",
        "magenta",
        "brown",
        "lightgrey",
        "lightblue",
        "lightgreen",
        "lightcyan",
        "lightred",
        "lightmagenta",
        "yellow",
        "white",
    },
}

colours.VALID = {
    [colours.ANY] = true,
    [colours.MUTAGENIC] = true,
    [colours.VEHUMET] = true,
    darkgrey = true,
}

for _, id in ipairs(colours.RANDOM) do
    colours.VALID[id] = true
end

return colours
