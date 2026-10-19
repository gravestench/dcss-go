-- _thing_names_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_thing_names_",
    entries = {
        {
            weight = 10,
            text = "Allies",
        },
        {
            weight = 10,
            text = "Artisans",
        },
        {
            weight = 10,
            text = "Artists",
        },
        {
            weight = 10,
            text = "Beasts",
        },
        {
            weight = 10,
            text = "Beds",
        },
        {
            weight = 10,
            text = "Beggars",
        },
        {
            weight = 10,
            text = "Blessings",
        },
        {
            weight = 10,
            text = "Bones",
        },
        {
            weight = 10,
            text = "Bounties",
        },
        {
            weight = 10,
            text = "Brambles",
        },
        {
            weight = 5,
            text = "Cities",
        },
        {
            weight = 10,
            text = "Coins",
        },
        {
            weight = 10,
            text = "Continents",
        },
        {
            weight = 10,
            text = "Curses",
        },
        {
            weight = 10,
            text = "Dances",
        },
        {
            weight = 10,
            text = "Deaths",
        },
        {
            weight = 10,
            text = "Defenders",
        },
        {
            weight = 10,
            text = "Demons",
        },
        {
            weight = 10,
            text = "Dreams",
        },
        {
            weight = 10,
            text = "Ears",
        },
        {
            weight = 10,
            text = "Emperors",
        },
        {
            weight = 10,
            text = "Eyes",
        },
        {
            weight = 10,
            text = "Friends",
        },
        {
            weight = 10,
            text = "Friars",
        },
        {
            weight = 10,
            text = "Geomancers",
        },
        {
            weight = 10,
            text = "Ghosts",
        },
        {
            weight = 10,
            text = "Gods",
        },
        {
            weight = 10,
            text = "Heavens",
        },
        {
            weight = 10,
            text = "Hells",
        },
        {
            weight = 10,
            text = "Hosts",
        },
        {
            weight = 10,
            text = "Interlopers",
        },
        {
            weight = 10,
            text = "Invaders",
        },
        {
            weight = 10,
            text = "Knaves",
        },
        {
            weight = 25,
            text = "Knives",
        },
        {
            weight = 10,
            text = "Leylines",
        },
        {
            weight = 10,
            text = "Lies",
        },
        {
            weight = 10,
            text = "Lives",
        },
        {
            weight = 10,
            text = "Loafs",
        },
        {
            weight = 10,
            text = "Lovers",
        },
        {
            weight = 10,
            text = "Mice",
        },
        {
            weight = 10,
            text = "Moons",
        },
        {
            weight = 10,
            text = "Mouths",
        },
        {
            weight = 10,
            text = "Mystics",
        },
        {
            weight = 5,
            text = "Nightcaps",
        },
        {
            weight = 10,
            text = "Nightingales",
        },
        {
            weight = 10,
            text = "Nightmares",
        },
        {
            weight = 10,
            text = "Nights",
        },
        {
            weight = 10,
            text = "Olives",
        },
        {
            weight = 10,
            text = "Orbs",
        },
        {
            weight = 10,
            text = "People",
        },
        {
            weight = 10,
            text = "Persimmons",
        },
        {
            weight = 10,
            text = "Places",
        },
        {
            weight = 10,
            text = "Planets",
        },
        {
            weight = 10,
            text = "Portals",
        },
        {
            weight = 10,
            text = "Priests",
        },
        {
            weight = 10,
            text = "Princes",
        },
        {
            weight = 10,
            text = "Prophets",
        },
        {
            weight = 10,
            text = "Queens",
        },
        {
            weight = 10,
            text = "Quests",
        },
        {
            weight = 10,
            text = "Realms",
        },
        {
            weight = 10,
            text = "Runes",
        },
        {
            weight = 10,
            text = "Scars",
        },
        {
            weight = 10,
            text = "Seas",
        },
        {
            weight = 10,
            text = "Seers",
        },
        {
            weight = 10,
            text = "Servitors",
        },
        {
            weight = 10,
            text = "Ships",
        },
        {
            weight = 10,
            text = "Shrikes",
        },
        {
            weight = 10,
            text = "Songs",
        },
        {
            weight = 10,
            text = "Souls",
        },
        {
            weight = 10,
            text = "Spines",
        },
        {
            weight = 10,
            text = "Spirits",
        },
        {
            weight = 5,
            text = "Spreadsheets",
        },
        {
            weight = 10,
            text = "Stars",
        },
        {
            weight = 10,
            text = "Stories",
        },
        {
            weight = 10,
            text = "Suns",
        },
        {
            weight = 10,
            text = "Tables",
        },
        {
            weight = 10,
            text = "Tales",
        },
        {
            weight = 10,
            text = "Teeth",
        },
        {
            weight = 10,
            text = "Thickets",
        },
        {
            weight = 5,
            text = "Things",
        },
        {
            weight = 5,
            text = "Towns",
        },
        {
            weight = 10,
            text = "Tusks",
        },
        {
            weight = 10,
            text = "Ultimatums",
        },
        {
            weight = 10,
            text = "Underlurkers",
        },
        {
            weight = 5,
            text = "Villages",
        },
        {
            weight = 10,
            text = "Violins",
        },
        {
            weight = 10,
            text = "Visionaries",
        },
        {
            weight = 10,
            text = "Visions",
        },
        {
            weight = 10,
            text = "Wars",
        },
        {
            weight = 10,
            text = "Wishes",
        },
        {
            weight = 10,
            text = "Wonders",
        },
        {
            weight = 10,
            text = "Xalams",
        },
        {
            weight = 10,
            text = "Xenops",
        },
        {
            weight = 10,
            text = "Xeniums",
        },
        {
            weight = 5,
            text = "Xenophobes",
        },
        {
            weight = 10,
            text = "Yaks",
        },
        {
            weight = 10,
            text = "Youths",
        },
        {
            weight = 10,
            text = "Ziggurats",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
