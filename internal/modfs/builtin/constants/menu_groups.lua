-- Menu groups preserve the authored character choice grouping shown on the start screen.

-- Source: crawl-ref/source/species-groups.h
-- Source: crawl-ref/source/newgame.cc

local groups = {
    MODDED_SPECIES = "Modded species",
    MODDED_BACKGROUNDS = "Modded backgrounds",
    SPECIES_SIMPLE = "Simple",
    SPECIES_INTERMEDIATE = "Intermediate",
    SPECIES_ADVANCED = "Advanced",
    JOB_WARRIOR = "Warrior",
    JOB_ADVENTURER = "Adventurer",
    JOB_ZEALOT = "Zealot",
    JOB_WARRIOR_MAGE = "Warrior-mage",
    JOB_MAGE = "Mage",
}

groups.species = {
    groups.SPECIES_SIMPLE,
    groups.SPECIES_INTERMEDIATE,
    groups.SPECIES_ADVANCED,
}

groups.species_capacities = {
    9,
    9,
    9,
}

groups.jobs = {
    groups.JOB_WARRIOR,
    groups.JOB_ADVENTURER,
    groups.JOB_ZEALOT,
    groups.JOB_WARRIOR_MAGE,
    groups.JOB_MAGE,
}

groups.jobs_capacities = {
    5,
    3,
    4,
    4,
    9,
}

return groups
