-- _game_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_game_name_",
    entries = {
        {
            weight = 10,
            text = "Dice, Bag, and Bottle",
        },
        {
            weight = 10,
            text = "Fun and Games",
        },
        {
            weight = 10,
            text = "Parlour Games",
        },
        {
            weight = 10,
            text = "the Game Afoot",
        },
        {
            weight = 10,
            text = "the Game of Kings",
        },
        {
            weight = 10,
            text = "the Great Game",
        },
        {
            weight = 10,
            text = "Follow the Leader",
        },
        {
            weight = 10,
            text = "Hide-and-Seek",
        },
        {
            weight = 10,
            text = "Hopscotch",
        },
        {
            weight = 10,
            text = "Leapfrog",
        },
        {
            weight = 10,
            text = "Mumblety Peg",
        },
        {
            weight = 10,
            text = "Peek-a-Boo",
        },
        {
            weight = 10,
            text = "the King of the Hill",
        },
        {
            weight = 10,
            text = "Card Tricks",
        },
        {
            weight = 10,
            text = "Hangman",
        },
        {
            weight = 10,
            text = "Jigsaw",
        },
        {
            weight = 10,
            text = "Marbles",
        },
        {
            weight = 10,
            text = "Noughts and Crosses",
        },
        {
            weight = 10,
            text = "Snakes and Ladders",
        },
        {
            weight = 10,
            text = "Whack-A-Mole",
        },
        {
            weight = 10,
            text = "the Dice",
        },
        {
            weight = 10,
            text = "the Game of Life",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
