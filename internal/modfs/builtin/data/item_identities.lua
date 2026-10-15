-- Generated from a committed DCSS import. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/book-type.h
-- SHA-256: 0c247550afabe35cecf089c17eff21b54f400173d85c20a65b933fd9f26a2394
-- Source: crawl-ref/source/equipment-type.h
-- SHA-256: 97f17a6ba82322abdb8dadec30033033c2ad1b7ad5779927e7808e3767334628
-- Source: crawl-ref/source/item-prop-enum.h
-- SHA-256: 61b0272b6c03dd00167f9cd04b1720e18c3800118e2c1dc675cea24834203d38
-- Source: crawl-ref/source/item-prop.cc
-- SHA-256: 46cf9a4d404a74333fd275b490b0f3c2eec5a919f96687d70986c97c45625111
-- Source: crawl-ref/source/item-prop.h
-- SHA-256: 94f8acc0991ae3b15f85962c2153485956eb03aee24b0bf6ac970e683a8d7fa6
-- Source: crawl-ref/source/object-class-type.h
-- SHA-256: 5a7401ca1c7c4ffaec5c5d0121fd274a90845193d995850f4c98b1d5a21edc6a
-- Source: crawl-ref/source/orb-type.h
-- SHA-256: 58779b3c734d011124af456ee8a83ec3e5f0d8ad20246ab3294877fdcaf744aa
-- Source: crawl-ref/source/potion-type.h
-- SHA-256: bd368d1829afd0151e94322f4d3d15a895341801cadd49ea89f5e6fccc62bad9
-- Source: crawl-ref/source/size-type.h
-- SHA-256: 044e924bfc581721cef6ca0caaeee40f131cf4caf55d981d8f0cd92b8525955e
-- Source: crawl-ref/source/skill-type.h
-- SHA-256: 41db7cbdd07c188228a007d3769cd20a68cce42fe0f5b2ae6023c1e677a243ee
-- Source: crawl-ref/source/tag-version.h
-- SHA-256: 2f8ed7610ca03ba6014044f78ca9f9b9392208a37d3539119ef04bd853ab1dfa

local catalog = {
    schema_version = 1,
    identities = {
        -- Source: crawl-ref/source/item-prop-enum.h:585
        {
            id = "WPN_CLUB",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 0,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:586
        {
            id = "WPN_WHIP",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 1,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:588
        {
            id = "WPN_HAMMER",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 2,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:590
        {
            id = "WPN_MACE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 3,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:591
        {
            id = "WPN_FLAIL",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 4,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:592
        {
            id = "WPN_MORNINGSTAR",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 5,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:594
        {
            id = "WPN_SPIKED_FLAIL",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 6,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:596
        {
            id = "WPN_DIRE_FLAIL",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 7,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:597
        {
            id = "WPN_EVENINGSTAR",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 8,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:598
        {
            id = "WPN_GREAT_MACE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 9,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:600
        {
            id = "WPN_DAGGER",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 10,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:601
        {
            id = "WPN_QUICK_BLADE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 11,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:602
        {
            id = "WPN_SHORT_SWORD",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 12,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:603
        {
            id = "WPN_RAPIER",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 13,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:605
        {
            id = "WPN_FALCHION",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 14,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:606
        {
            id = "WPN_LONG_SWORD",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 15,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:607
        {
            id = "WPN_SCIMITAR",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 16,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:608
        {
            id = "WPN_GREAT_SWORD",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 17,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:610
        {
            id = "WPN_HAND_AXE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 18,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:611
        {
            id = "WPN_WAR_AXE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 19,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:612
        {
            id = "WPN_BROAD_AXE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 20,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:613
        {
            id = "WPN_BATTLEAXE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 21,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:614
        {
            id = "WPN_EXECUTIONERS_AXE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 22,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:616
        {
            id = "WPN_SPEAR",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 23,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:617
        {
            id = "WPN_TRIDENT",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 24,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:618
        {
            id = "WPN_HALBERD",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 25,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:619
        {
            id = "WPN_GLAIVE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 26,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:620
        {
            id = "WPN_BARDICHE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 27,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:623
        {
            id = "WPN_BLOWGUN",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 28,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:629
        {
            id = "WPN_ARBALEST",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 29,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:634
        {
            id = "WPN_SHORTBOW",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 30,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:635
        {
            id = "WPN_LONGBOW",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 31,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:641
        {
            id = "WPN_DEMON_WHIP",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 32,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:642
        {
            id = "WPN_GIANT_CLUB",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 33,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:643
        {
            id = "WPN_GIANT_SPIKED_CLUB",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 34,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:645
        {
            id = "WPN_DEMON_BLADE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 35,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:646
        {
            id = "WPN_DOUBLE_SWORD",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 36,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:647
        {
            id = "WPN_TRIPLE_SWORD",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 37,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:649
        {
            id = "WPN_DEMON_TRIDENT",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 38,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:651
        {
            id = "WPN_SCYTHE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 39,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:654
        {
            id = "WPN_STAFF",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 40,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:655
        {
            id = "WPN_QUARTERSTAFF",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 41,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:656
        {
            id = "WPN_LAJATANG",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 42,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:659
        {
            id = "WPN_SLING",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 43,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:661
        {
            id = "WPN_BLESSED_FALCHION",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 44,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:662
        {
            id = "WPN_BLESSED_LONG_SWORD",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 45,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:663
        {
            id = "WPN_BLESSED_SCIMITAR",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 46,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:664
        {
            id = "WPN_BLESSED_GREAT_SWORD",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 47,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:666
        {
            id = "WPN_EUDEMON_BLADE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 48,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:668
        {
            id = "WPN_BLESSED_DOUBLE_SWORD",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 49,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:669
        {
            id = "WPN_BLESSED_TRIPLE_SWORD",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 50,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:671
        {
            id = "WPN_SACRED_SCOURGE",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 51,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:672
        {
            id = "WPN_TRISHULA",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 52,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:675
        {
            id = "WPN_FUSTIBALUS",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 53,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:676
        {
            id = "WPN_HAND_CROSSBOW",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 54,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:677
        {
            id = "WPN_TRIPLE_CROSSBOW",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 55,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:679
        {
            id = "WPN_CUTLASS",
            class_id = "OBJ_WEAPONS",
            class_value = 0,
            subtype_value = 56,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:360
        {
            id = "MI_DART",
            class_id = "OBJ_MISSILES",
            class_value = 1,
            subtype_value = 0,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:362
        {
            id = "MI_NEEDLE",
            class_id = "OBJ_MISSILES",
            class_value = 1,
            subtype_value = 1,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:364
        {
            id = "MI_ARROW",
            class_id = "OBJ_MISSILES",
            class_value = 1,
            subtype_value = 2,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:365
        {
            id = "MI_BOLT",
            class_id = "OBJ_MISSILES",
            class_value = 1,
            subtype_value = 3,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:366
        {
            id = "MI_JAVELIN",
            class_id = "OBJ_MISSILES",
            class_value = 1,
            subtype_value = 4,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:368
        {
            id = "MI_STONE",
            class_id = "OBJ_MISSILES",
            class_value = 1,
            subtype_value = 5,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:369
        {
            id = "MI_LARGE_ROCK",
            class_id = "OBJ_MISSILES",
            class_value = 1,
            subtype_value = 6,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:370
        {
            id = "MI_SLING_BULLET",
            class_id = "OBJ_MISSILES",
            class_value = 1,
            subtype_value = 7,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:371
        {
            id = "MI_THROWING_NET",
            class_id = "OBJ_MISSILES",
            class_value = 1,
            subtype_value = 8,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:372
        {
            id = "MI_BOOMERANG",
            class_id = "OBJ_MISSILES",
            class_value = 1,
            subtype_value = 9,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:20
        {
            id = "ARM_ROBE",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 0,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:22
        {
            id = "ARM_LEATHER_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 1,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:23
        {
            id = "ARM_RING_MAIL",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 2,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:24
        {
            id = "ARM_SCALE_MAIL",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 3,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:25
        {
            id = "ARM_CHAIN_MAIL",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 4,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:26
        {
            id = "ARM_PLATE_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 5,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:32
        {
            id = "ARM_CLOAK",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 6,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:38
        {
            id = "ARM_CAP",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 7,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:40
        {
            id = "ARM_HAT",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 8,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:41
        {
            id = "ARM_HELMET",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 9,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:43
        {
            id = "ARM_GLOVES",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 10,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:45
        {
            id = "ARM_BOOTS",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 11,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:47
        {
            id = "ARM_BUCKLER",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 12,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:49
        {
            id = "ARM_KITE_SHIELD",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 13,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:50
        {
            id = "ARM_TOWER_SHIELD",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 14,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:57
        {
            id = "ARM_CRYSTAL_PLATE_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 15,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:60
        {
            id = "ARM_ANIMAL_SKIN",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 16,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:63
        {
            id = "ARM_TROLL_HIDE",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 17,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:65
        {
            id = "ARM_TROLL_LEATHER_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 18,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:68
        {
            id = "ARM_FIRE_DRAGON_HIDE",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 19,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:70
        {
            id = "ARM_FIRE_DRAGON_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 20,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:72
        {
            id = "ARM_ICE_DRAGON_HIDE",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 21,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:74
        {
            id = "ARM_ICE_DRAGON_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 22,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:76
        {
            id = "ARM_STEAM_DRAGON_HIDE",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 23,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:78
        {
            id = "ARM_STEAM_DRAGON_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 24,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:80
        {
            id = "ARM_ACID_DRAGON_HIDE",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 25,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:82
        {
            id = "ARM_ACID_DRAGON_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 26,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:84
        {
            id = "ARM_STORM_DRAGON_HIDE",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 27,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:86
        {
            id = "ARM_STORM_DRAGON_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 28,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:88
        {
            id = "ARM_GOLD_DRAGON_HIDE",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 29,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:90
        {
            id = "ARM_GOLD_DRAGON_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 30,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:92
        {
            id = "ARM_SWAMP_DRAGON_HIDE",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 31,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:94
        {
            id = "ARM_SWAMP_DRAGON_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 32,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:96
        {
            id = "ARM_PEARL_DRAGON_HIDE",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 33,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:98
        {
            id = "ARM_PEARL_DRAGON_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 34,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:105
        {
            id = "ARM_CENTAUR_BARDING",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 35,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:107
        {
            id = "ARM_BARDING",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 36,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:110
        {
            id = "ARM_SHADOW_DRAGON_HIDE",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 37,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:111
        {
            id = "ARM_SHADOW_DRAGON_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 38,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:112
        {
            id = "ARM_QUICKSILVER_DRAGON_HIDE",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 39,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:113
        {
            id = "ARM_QUICKSILVER_DRAGON_ARMOUR",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 40,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:114
        {
            id = "ARM_SCARF",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 41,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:115
        {
            id = "ARM_ORB",
            class_id = "OBJ_ARMOUR",
            class_value = 2,
            subtype_value = 42,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:737
        {
            id = "WAND_FLAME",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 0,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:739
        {
            id = "WAND_FROST_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 1,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:740
        {
            id = "WAND_SLOWING_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 2,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:741
        {
            id = "WAND_HASTING_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 3,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:742
        {
            id = "WAND_MAGIC_DARTS_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 4,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:743
        {
            id = "WAND_HEAL_WOUNDS_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 5,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:745
        {
            id = "WAND_PARALYSIS",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 6,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:747
        {
            id = "WAND_FIRE_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 7,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:748
        {
            id = "WAND_COLD_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 8,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:749
        {
            id = "WAND_CONFUSION_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 9,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:750
        {
            id = "WAND_INVISIBILITY_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 10,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:752
        {
            id = "WAND_DIGGING",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 11,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:753
        {
            id = "WAND_ICEBLAST",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 12,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:755
        {
            id = "WAND_TELEPORTATION_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 13,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:756
        {
            id = "WAND_LIGHTNING_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 14,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:758
        {
            id = "WAND_POLYMORPH",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 15,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:759
        {
            id = "WAND_CHARMING",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 16,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:760
        {
            id = "WAND_ACID",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 17,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:762
        {
            id = "WAND_RANDOM_EFFECTS_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 18,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:764
        {
            id = "WAND_MINDBURST",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 19,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:766
        {
            id = "WAND_CLOUDS_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 20,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:767
        {
            id = "WAND_SCATTERSHOT_REMOVED",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 21,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:769
        {
            id = "WAND_LIGHT",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 22,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:770
        {
            id = "WAND_QUICKSILVER",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 23,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:771
        {
            id = "WAND_ROOTS",
            class_id = "OBJ_WANDS",
            class_value = 3,
            subtype_value = 24,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:778
        {
            id = "FOOD_RATION",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 0,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:779
        {
            id = "FOOD_BREAD_RATION",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 1,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:780
        {
            id = "FOOD_PEAR",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 2,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:781
        {
            id = "FOOD_APPLE",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 3,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:782
        {
            id = "FOOD_CHOKO",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 4,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:783
        {
            id = "FOOD_ROYAL_JELLY",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 5,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:784
        {
            id = "FOOD_UNUSED",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 6,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:785
        {
            id = "FOOD_FRUIT",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 7,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:786
        {
            id = "FOOD_PIZZA",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 8,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:787
        {
            id = "FOOD_APRICOT",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 9,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:788
        {
            id = "FOOD_ORANGE",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 10,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:789
        {
            id = "FOOD_BANANA",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 11,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:790
        {
            id = "FOOD_STRAWBERRY",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 12,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:791
        {
            id = "FOOD_RAMBUTAN",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 13,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:792
        {
            id = "FOOD_LEMON",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 14,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:793
        {
            id = "FOOD_GRAPE",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 15,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:794
        {
            id = "FOOD_SULTANA",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 16,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:795
        {
            id = "FOOD_LYCHEE",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 17,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:796
        {
            id = "FOOD_BEEF_JERKY",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 18,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:797
        {
            id = "FOOD_CHEESE",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 19,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:798
        {
            id = "FOOD_SAUSAGE",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 20,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:799
        {
            id = "FOOD_CHUNK",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 21,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:800
        {
            id = "FOOD_AMBROSIA",
            class_id = "OBJ_FOOD",
            class_value = 4,
            subtype_value = 22,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:410
        {
            id = "SCR_IDENTIFY",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 0,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:411
        {
            id = "SCR_TELEPORTATION",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 1,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:412
        {
            id = "SCR_FEAR",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 2,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:413
        {
            id = "SCR_NOISE",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 3,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:415
        {
            id = "SCR_REMOVE_CURSE",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 4,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:417
        {
            id = "SCR_SUMMONING",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 5,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:418
        {
            id = "SCR_ENCHANT_WEAPON",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 6,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:419
        {
            id = "SCR_ENCHANT_ARMOUR",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 7,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:420
        {
            id = "SCR_TORMENT",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 8,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:422
        {
            id = "SCR_RANDOM_USELESSNESS",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 9,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:423
        {
            id = "SCR_CURSE_WEAPON",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 10,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:424
        {
            id = "SCR_CURSE_ARMOUR",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 11,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:426
        {
            id = "SCR_IMMOLATION",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 12,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:427
        {
            id = "SCR_BLINKING",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 13,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:428
        {
            id = "SCR_MAGIC_MAPPING",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 14,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:429
        {
            id = "SCR_FOG",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 15,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:430
        {
            id = "SCR_ACQUIREMENT",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 16,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:432
        {
            id = "SCR_ENCHANT_WEAPON_II",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 17,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:434
        {
            id = "SCR_BRAND_WEAPON",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 18,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:436
        {
            id = "SCR_RECHARGING",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 19,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:437
        {
            id = "SCR_ENCHANT_WEAPON_III",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 20,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:438
        {
            id = "SCR_HOLY_WORD",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 21,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:440
        {
            id = "SCR_VULNERABILITY",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 22,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:441
        {
            id = "SCR_SILENCE",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 23,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:442
        {
            id = "SCR_AMNESIA",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 24,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:444
        {
            id = "SCR_CURSE_JEWELLERY",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 25,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:446
        {
            id = "SCR_POISON",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 26,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:447
        {
            id = "SCR_BUTTERFLIES",
            class_id = "OBJ_SCROLLS",
            class_value = 5,
            subtype_value = 27,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:203
        {
            id = "RING_REGENERATION",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 0,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:205
        {
            id = "RING_PROTECTION",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 1,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:207
        {
            id = "RING_PROTECTION_FROM_FIRE",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 2,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:208
        {
            id = "RING_POISON_RESISTANCE",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 3,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:209
        {
            id = "RING_PROTECTION_FROM_COLD",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 4,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:210
        {
            id = "RING_STRENGTH",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 5,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:211
        {
            id = "RING_SLAYING",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 6,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:212
        {
            id = "RING_SEE_INVISIBLE",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 7,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:213
        {
            id = "RING_RESIST_CORROSION",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 8,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:215
        {
            id = "RING_ATTENTION",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 9,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:216
        {
            id = "RING_TELEPORTATION",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 10,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:218
        {
            id = "RING_EVASION",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 11,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:220
        {
            id = "RING_SUSTAIN_ATTRIBUTES",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 12,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:222
        {
            id = "RING_STEALTH",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 13,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:223
        {
            id = "RING_DEXTERITY",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 14,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:224
        {
            id = "RING_INTELLIGENCE",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 15,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:225
        {
            id = "RING_WIZARDRY",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 16,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:226
        {
            id = "RING_MAGICAL_POWER",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 17,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:227
        {
            id = "RING_FLIGHT",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 18,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:228
        {
            id = "RING_LIFE_PROTECTION",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 19,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:229
        {
            id = "RING_WILLPOWER",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 20,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:230
        {
            id = "RING_FIRE",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 21,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:231
        {
            id = "RING_ICE",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 22,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:233
        {
            id = "RING_TELEPORT_CONTROL",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 23,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:243
        {
            id = "AMU_RAGE",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 35,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:245
        {
            id = "AMU_HARM",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 36,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:251
        {
            id = "AMU_ACROBAT",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 37,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:253
        {
            id = "AMU_MANA_REGENERATION",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 38,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:255
        {
            id = "AMU_THE_GOURMAND",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 39,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:256
        {
            id = "AMU_CONSERVATION",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 40,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:257
        {
            id = "AMU_CONTROLLED_FLIGHT",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 41,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:258
        {
            id = "AMU_INACCURACY",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 42,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:260
        {
            id = "AMU_NOTHING",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 43,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:261
        {
            id = "AMU_GUARDIAN_SPIRIT",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 44,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:262
        {
            id = "AMU_FAITH",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 45,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:263
        {
            id = "AMU_REFLECTION",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 46,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:264
        {
            id = "AMU_REGENERATION",
            class_id = "OBJ_JEWELLERY",
            class_value = 6,
            subtype_value = 47,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:11
        {
            id = "POT_CURING",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 0,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:12
        {
            id = "POT_HEAL_WOUNDS",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 1,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:13
        {
            id = "POT_HASTE",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 2,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:14
        {
            id = "POT_MIGHT",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 3,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:15
        {
            id = "POT_BRILLIANCE",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 4,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:16
        {
            id = "POT_ATTRACTION",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 5,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:18
        {
            id = "POT_GAIN_STRENGTH",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 6,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:19
        {
            id = "POT_GAIN_DEXTERITY",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 7,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:20
        {
            id = "POT_GAIN_INTELLIGENCE",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 8,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:22
        {
            id = "POT_FLIGHT",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 9,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:24
        {
            id = "POT_POISON",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 10,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:25
        {
            id = "POT_SLOWING",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 11,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:27
        {
            id = "POT_CANCELLATION",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 12,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:28
        {
            id = "POT_AMBROSIA",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 13,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:29
        {
            id = "POT_INVISIBILITY",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 14,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:31
        {
            id = "POT_PORRIDGE",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 15,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:33
        {
            id = "POT_DEGENERATION",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 16,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:35
        {
            id = "POT_DECAY",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 17,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:36
        {
            id = "POT_WATER",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 18,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:38
        {
            id = "POT_EXPERIENCE",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 19,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:39
        {
            id = "POT_MAGIC",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 20,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:41
        {
            id = "POT_RESTORE_ABILITIES",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 21,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:42
        {
            id = "POT_STRONG_POISON",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 22,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:44
        {
            id = "POT_BERSERK_RAGE",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 23,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:46
        {
            id = "POT_CURE_MUTATION",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 24,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:48
        {
            id = "POT_MUTATION",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 25,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:49
        {
            id = "POT_RESISTANCE",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 26,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:51
        {
            id = "POT_BLOOD",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 27,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:52
        {
            id = "POT_BLOOD_COAGULATED",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 28,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:54
        {
            id = "POT_LIGNIFY",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 29,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/potion-type.h:56
        {
            id = "POT_BENEFICIAL_MUTATION",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 30,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/potion-type.h:57
        {
            id = "POT_DUMMY_AGILITY",
            class_id = "OBJ_POTIONS",
            class_value = 7,
            subtype_value = 31,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/book-type.h:7
        {
            id = "BOOK_MINOR_MAGIC",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 0,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:8
        {
            id = "BOOK_CONJURATIONS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 1,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:9
        {
            id = "BOOK_FLAMES",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 2,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:10
        {
            id = "BOOK_FROST",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 3,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:11
        {
            id = "BOOK_WILDERNESS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 4,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:12
        {
            id = "BOOK_FIRE",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 5,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:13
        {
            id = "BOOK_ICE",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 6,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:14
        {
            id = "BOOK_SPATIAL_TRANSLOCATIONS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 7,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:15
        {
            id = "BOOK_HEXES",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 8,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:16
        {
            id = "BOOK_YOUNG_POISONERS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 9,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:17
        {
            id = "BOOK_LIGHTNING",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 10,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:18
        {
            id = "BOOK_DEATH",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 11,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:19
        {
            id = "BOOK_MISFORTUNE",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 12,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:20
        {
            id = "BOOK_CHANGES",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 13,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:21
        {
            id = "BOOK_TRANSFIGURATIONS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 14,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:22
        {
            id = "BOOK_FEN",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 15,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:26
        {
            id = "BOOK_VAPOURS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 16,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:27
        {
            id = "BOOK_NECROMANCY",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 17,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:28
        {
            id = "BOOK_CALLINGS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 18,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:29
        {
            id = "BOOK_MALEDICT",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 19,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:30
        {
            id = "BOOK_AIR",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 20,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:31
        {
            id = "BOOK_SKY",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 21,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:32
        {
            id = "BOOK_WARP",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 22,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:34
        {
            id = "BOOK_ENVENOMATIONS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 23,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/book-type.h:36
        {
            id = "BOOK_UNLIFE",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 24,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:38
        {
            id = "BOOK_CONTROL",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 25,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/book-type.h:39
        {
            id = "BOOK_BATTLE",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 26,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/book-type.h:41
        {
            id = "BOOK_GEOMANCY",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 27,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:43
        {
            id = "BOOK_STONE",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 28,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/book-type.h:44
        {
            id = "BOOK_WIZARDRY",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 29,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/book-type.h:46
        {
            id = "BOOK_POWER",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 30,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:47
        {
            id = "BOOK_CANTRIPS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 31,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:48
        {
            id = "BOOK_PARTY_TRICKS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 32,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:50
        {
            id = "BOOK_AKASHIC_RECORD",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 33,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/book-type.h:52
        {
            id = "BOOK_DEBILITATION",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 34,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:53
        {
            id = "BOOK_DRAGON",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 35,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:54
        {
            id = "BOOK_BURGLARY",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 36,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:55
        {
            id = "BOOK_DREAMS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 37,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:56
        {
            id = "BOOK_ALCHEMY",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 38,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:57
        {
            id = "BOOK_BEASTS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 39,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:59
        {
            id = "BOOK_ANNIHILATIONS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 40,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:60
        {
            id = "BOOK_GRAND_GRIMOIRE",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 41,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:61
        {
            id = "BOOK_NECRONOMICON",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 42,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:65
        {
            id = "BOOK_RANDART_LEVEL",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 43,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:66
        {
            id = "BOOK_RANDART_THEME",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 44,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:68
        {
            id = "BOOK_MANUAL",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 45,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:70
        {
            id = "BOOK_BUGGY_DESTRUCTION",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 46,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/book-type.h:73
        {
            id = "BOOK_SPECTACLE",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 47,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:74
        {
            id = "BOOK_WINTER",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 48,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:75
        {
            id = "BOOK_SPHERES",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 49,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:76
        {
            id = "BOOK_ARMAMENTS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 50,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:78
        {
            id = "BOOK_PAIN",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 51,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/book-type.h:80
        {
            id = "BOOK_DECAY",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 52,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:81
        {
            id = "BOOK_DISPLACEMENT",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 53,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:82
        {
            id = "BOOK_RIME",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 54,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:83
        {
            id = "BOOK_EVERBURNING",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 55,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:84
        {
            id = "BOOK_EARTH",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 56,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:85
        {
            id = "BOOK_OZOCUBU",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 57,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:86
        {
            id = "BOOK_SENSES",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 58,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:87
        {
            id = "BOOK_MOON",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 59,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:88
        {
            id = "BOOK_BLASTING",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 60,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:89
        {
            id = "BOOK_IRON",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 61,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:90
        {
            id = "BOOK_NEARBY",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 62,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:91
        {
            id = "BOOK_TUNDRA",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 63,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:92
        {
            id = "BOOK_STORMS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 64,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:93
        {
            id = "BOOK_WEAPONS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 65,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:94
        {
            id = "BOOK_SLOTH",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 66,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:95
        {
            id = "BOOK_BLOOD",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 67,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:96
        {
            id = "BOOK_THERE_AND_BACK",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 68,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:97
        {
            id = "BOOK_DANGEROUS_FRIENDS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 69,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:98
        {
            id = "BOOK_TOUCH",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 70,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:99
        {
            id = "BOOK_CHAOS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 71,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:100
        {
            id = "BOOK_UNRESTRAINED",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 72,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:101
        {
            id = "BOOK_BIOGRAPHIES_II",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 73,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:102
        {
            id = "BOOK_BIOGRAPHIES_VII",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 74,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:103
        {
            id = "BOOK_TRISMEGISTUS",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 75,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:104
        {
            id = "BOOK_HUNTER",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 76,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/book-type.h:105
        {
            id = "BOOK_SCORCHING",
            class_id = "OBJ_BOOKS",
            class_value = 8,
            subtype_value = 77,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:543
        {
            id = "STAFF_WIZARDRY",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 0,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:544
        {
            id = "STAFF_POWER",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 1,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:546
        {
            id = "STAFF_FIRE",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 2,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:547
        {
            id = "STAFF_COLD",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 3,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:548
        {
            id = "STAFF_POISON",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 4,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:550
        {
            id = "STAFF_ENERGY",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 5,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:552
        {
            id = "STAFF_DEATH",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 6,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:553
        {
            id = "STAFF_CONJURATION",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 7,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:555
        {
            id = "STAFF_ENCHANTMENT",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 8,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:556
        {
            id = "STAFF_SUMMONING",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 9,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:558
        {
            id = "STAFF_AIR",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 10,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:559
        {
            id = "STAFF_EARTH",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 11,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:561
        {
            id = "STAFF_CHANNELING",
            class_id = "OBJ_STAVES",
            class_value = 9,
            subtype_value = 12,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/orb-type.h:5
        {
            id = "ORB_ZOT",
            class_id = "OBJ_ORBS",
            class_value = 10,
            subtype_value = 0,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:280
        {
            id = "MISC_BOTTLED_EFREET",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 0,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:281
        {
            id = "MISC_FAN_OF_GALES",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 1,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:282
        {
            id = "MISC_LAMP_OF_FIRE",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 2,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:283
        {
            id = "MISC_STONE_OF_TREMORS",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 3,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:284
        {
            id = "MISC_BUGGY_LANTERN_OF_SHADOWS",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 4,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:286
        {
            id = "MISC_HORN_OF_GERYON",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 5,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:287
        {
            id = "MISC_BOX_OF_BEASTS",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 6,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:289
        {
            id = "MISC_CRYSTAL_BALL_OF_ENERGY",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 7,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:290
        {
            id = "MISC_BUGGY_EBONY_CASKET",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 8,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:292
        {
            id = "MISC_LIGHTNING_ROD",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 9,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:295
        {
            id = "MISC_DECK_OF_ESCAPE",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 10,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:297
        {
            id = "MISC_DECK_OF_DESTRUCTION",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 11,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:298
        {
            id = "MISC_DECK_OF_DUNGEONS",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 12,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:299
        {
            id = "MISC_DECK_OF_SUMMONING",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 13,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:300
        {
            id = "MISC_DECK_OF_WONDERS",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 14,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:301
        {
            id = "MISC_DECK_OF_PUNISHMENT",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 15,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:302
        {
            id = "MISC_DECK_OF_WAR",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 16,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:303
        {
            id = "MISC_DECK_OF_CHANGES",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 17,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:304
        {
            id = "MISC_DECK_OF_DEFENCE",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 18,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:307
        {
            id = "MISC_RUNE_OF_ZOT",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 19,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:310
        {
            id = "MISC_QUAD_DAMAGE",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 20,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:312
        {
            id = "MISC_PHIAL_OF_FLOODS",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 21,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:314
        {
            id = "MISC_SACK_OF_SPIDERS",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 22,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:316
        {
            id = "MISC_ZIGGURAT",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 23,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:318
        {
            id = "MISC_PHANTOM_MIRROR",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 24,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:320
        {
            id = "MISC_DECK_OF_ODDITIES",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 25,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:322
        {
            id = "MISC_XOMS_CHESSBOARD",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 26,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:323
        {
            id = "MISC_TIN_OF_TREMORSTONES",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 27,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:324
        {
            id = "MISC_CONDENSER_VANE",
            class_id = "OBJ_MISCELLANY",
            class_value = 11,
            subtype_value = 28,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:190
        {
            id = "CORPSE_BODY",
            class_id = "OBJ_CORPSES",
            class_value = 12,
            subtype_value = 0,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:191
        {
            id = "CORPSE_SKELETON",
            class_id = "OBJ_CORPSES",
            class_value = 12,
            subtype_value = 1,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/object-class-type.h:24
        {
            id = "OBJ_GOLD",
            class_id = "OBJ_GOLD",
            class_value = 13,
            subtype_value = 0,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:569
        {
            id = "ROD_LIGHTNING",
            class_id = "OBJ_RODS",
            class_value = 14,
            subtype_value = 0,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:570
        {
            id = "ROD_SWARM",
            class_id = "OBJ_RODS",
            class_value = 14,
            subtype_value = 1,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:571
        {
            id = "ROD_IGNITION",
            class_id = "OBJ_RODS",
            class_value = 14,
            subtype_value = 2,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:572
        {
            id = "ROD_CLOUDS",
            class_id = "OBJ_RODS",
            class_value = 14,
            subtype_value = 3,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:573
        {
            id = "ROD_DESTRUCTION",
            class_id = "OBJ_RODS",
            class_value = 14,
            subtype_value = 4,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:574
        {
            id = "ROD_INACCURACY",
            class_id = "OBJ_RODS",
            class_value = 14,
            subtype_value = 5,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:575
        {
            id = "ROD_WARDING",
            class_id = "OBJ_RODS",
            class_value = 14,
            subtype_value = 6,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:576
        {
            id = "ROD_SHADOWS",
            class_id = "OBJ_RODS",
            class_value = 14,
            subtype_value = 7,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:577
        {
            id = "ROD_IRON",
            class_id = "OBJ_RODS",
            class_value = 14,
            subtype_value = 8,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:578
        {
            id = "ROD_VENOM",
            class_id = "OBJ_RODS",
            class_value = 14,
            subtype_value = 9,
            explicitly_removed = true,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:380
        {
            id = "RUNE_SWAMP",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 0,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:381
        {
            id = "RUNE_SNAKE",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 1,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:382
        {
            id = "RUNE_SHOALS",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 2,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:383
        {
            id = "RUNE_SLIME",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 3,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:384
        {
            id = "RUNE_ELF",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 4,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:385
        {
            id = "RUNE_VAULTS",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 5,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:386
        {
            id = "RUNE_TOMB",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 6,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:388
        {
            id = "RUNE_DIS",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 7,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:389
        {
            id = "RUNE_GEHENNA",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 8,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:390
        {
            id = "RUNE_COCYTUS",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 9,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:391
        {
            id = "RUNE_TARTARUS",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 10,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:393
        {
            id = "RUNE_ABYSSAL",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 11,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:395
        {
            id = "RUNE_DEMONIC",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 12,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:398
        {
            id = "RUNE_MNOLEG",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 13,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:399
        {
            id = "RUNE_LOM_LOBON",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 14,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:400
        {
            id = "RUNE_CEREBOV",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 15,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:401
        {
            id = "RUNE_GLOORX_VLOQ",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 16,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:403
        {
            id = "RUNE_SPIDER",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 17,
            explicitly_removed = false,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:404
        {
            id = "RUNE_FOREST",
            class_id = "OBJ_RUNES",
            class_value = 15,
            subtype_value = 18,
            explicitly_removed = false,
        },
    },
    aliases = {
        -- Source: crawl-ref/source/item-prop-enum.h:244
        {
            id = "AMU_FIRST_AMULET",
            target_id = "AMU_RAGE",
            class_id = "OBJ_JEWELLERY",
            numeric_value = 35,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:21
        {
            id = "ARM_FIRST_MUNDANE_BODY",
            target_id = "ARM_ROBE",
            class_id = "OBJ_ARMOUR",
            numeric_value = 0,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:48
        {
            id = "ARM_FIRST_SHIELD",
            target_id = "ARM_BUCKLER",
            class_id = "OBJ_ARMOUR",
            numeric_value = 12,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:27
        {
            id = "ARM_LAST_MUNDANE_BODY",
            target_id = "ARM_PLATE_ARMOUR",
            class_id = "OBJ_ARMOUR",
            numeric_value = 5,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:51
        {
            id = "ARM_LAST_SHIELD",
            target_id = "ARM_TOWER_SHIELD",
            class_id = "OBJ_ARMOUR",
            numeric_value = 14,
        },
        -- Source: crawl-ref/source/book-type.h:24
        {
            id = "BOOK_WAR_CHANTS",
            target_id = "BOOK_FEN",
            class_id = "OBJ_BOOKS",
            numeric_value = 15,
        },
        -- Source: crawl-ref/source/book-type.h:63
        {
            id = "MAX_FIXED_BOOK",
            target_id = "BOOK_NECRONOMICON",
            class_id = "OBJ_BOOKS",
            numeric_value = 42,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:296
        {
            id = "MISC_FIRST_DECK",
            target_id = "MISC_DECK_OF_ESCAPE",
            class_id = "OBJ_MISCELLANY",
            numeric_value = 10,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:305
        {
            id = "MISC_LAST_DECK",
            target_id = "MISC_DECK_OF_DEFENCE",
            class_id = "OBJ_MISCELLANY",
            numeric_value = 18,
        },
        -- Source: crawl-ref/source/item-prop-enum.h:206
        {
            id = "RING_FIRST_RING",
            target_id = "RING_PROTECTION",
            class_id = "OBJ_JEWELLERY",
            numeric_value = 1,
        },
    },
    vocabulary = {
        slots = {
            "EQ_ALL_ARMOUR",
            "EQ_AMULET",
            "EQ_BODY_ARMOUR",
            "EQ_BOOTS",
            "EQ_CLOAK",
            "EQ_FIRST_EQUIP",
            "EQ_FIRST_JEWELLERY",
            "EQ_GLOVES",
            "EQ_HELMET",
            "EQ_LAST_JEWELLERY",
            "EQ_LEFT_RING",
            "EQ_MAX_ARMOUR",
            "EQ_MAX_WORN",
            "EQ_MIN_ARMOUR",
            "EQ_NONE",
            "EQ_RIGHT_RING",
            "EQ_RINGS",
            "EQ_RINGS_PLUS",
            "EQ_RING_AMULET",
            "EQ_RING_EIGHT",
            "EQ_RING_FIVE",
            "EQ_RING_FOUR",
            "EQ_RING_ONE",
            "EQ_RING_SEVEN",
            "EQ_RING_SIX",
            "EQ_RING_THREE",
            "EQ_RING_TWO",
            "EQ_SHIELD",
            "EQ_STAFF",
            "EQ_WEAPON",
        },
        skills = {
            "SK_AIR_MAGIC",
            "SK_ARMOUR",
            "SK_AXES",
            "SK_BLANK_LINE",
            "SK_CHARMS",
            "SK_COLUMN_BREAK",
            "SK_CONJURATIONS",
            "SK_CROSSBOWS",
            "SK_DODGING",
            "SK_EARTH_MAGIC",
            "SK_EVOCATIONS",
            "SK_FIGHTING",
            "SK_FIRE_MAGIC",
            "SK_FIRST_MAGIC_SCHOOL",
            "SK_FIRST_SKILL",
            "SK_FIRST_WEAPON",
            "SK_HEXES",
            "SK_ICE_MAGIC",
            "SK_INVOCATIONS",
            "SK_LAST_MAGIC",
            "SK_LAST_MELEE_WEAPON",
            "SK_LAST_MUNDANE",
            "SK_LAST_SKILL",
            "SK_LAST_WEAPON",
            "SK_LONG_BLADES",
            "SK_MACES_FLAILS",
            "SK_NECROMANCY",
            "SK_NONE",
            "SK_POISON_MAGIC",
            "SK_POLEARMS",
            "SK_RANGED_WEAPONS",
            "SK_SHIELDS",
            "SK_SHORT_BLADES",
            "SK_SLINGS",
            "SK_SPELLCASTING",
            "SK_STABBING",
            "SK_STAVES",
            "SK_STEALTH",
            "SK_SUMMONINGS",
            "SK_THROWING",
            "SK_TITLE",
            "SK_TRANSLOCATIONS",
            "SK_TRANSMUTATIONS",
            "SK_TRAPS",
            "SK_UNARMED_COMBAT",
            "SK_WEAPON",
        },
        sizes = {
            "NUM_SIZE_LEVELS",
            "SIZE_CHARACTER",
            "SIZE_GIANT",
            "SIZE_LARGE",
            "SIZE_LITTLE",
            "SIZE_MEDIUM",
            "SIZE_SMALL",
            "SIZE_TINY",
        },
        ammo = {
            "MI_ARROW",
            "MI_BOLT",
            "MI_BOOMERANG",
            "MI_DART",
            "MI_JAVELIN",
            "MI_LARGE_ROCK",
            "MI_NEEDLE",
            "MI_NONE",
            "MI_SLING_BULLET",
            "MI_STONE",
            "MI_THROWING_NET",
        },
        damage_flags = {
            "DAMV_CHOPPING",
            "DAMV_CRUSHING",
            "DAMV_MASK",
            "DAMV_NON_MELEE",
            "DAMV_PIERCING",
            "DAMV_SLASHING",
            "DAMV_SLICING",
            "DAM_BASH",
            "DAM_BLUDGEON",
            "DAM_MASK",
            "DAM_MAX_TYPE",
            "DAM_PIERCE",
            "DAM_SLICE",
            "DAM_WHIP",
            "DVORP_CHOPPING",
            "DVORP_CLAWING",
            "DVORP_CRUSHING",
            "DVORP_NONE",
            "DVORP_PIERCING",
            "DVORP_SLASHING",
            "DVORP_SLICING",
            "DVORP_TENTACLE",
        },
        brands = {
            "SPWPN_ACID",
            "SPWPN_ANTIMAGIC",
            "SPWPN_CHAOS",
            "SPWPN_CONFUSE",
            "SPWPN_DEBUG_RANDART",
            "SPWPN_DISTORTION",
            "SPWPN_DRAGON_SLAYING",
            "SPWPN_DRAINING",
            "SPWPN_ELECTROCUTION",
            "SPWPN_EVASION",
            "SPWPN_FLAME",
            "SPWPN_FLAMING",
            "SPWPN_FORBID_BRAND",
            "SPWPN_FREEZING",
            "SPWPN_FROST",
            "SPWPN_HOLY_WRATH",
            "SPWPN_NORMAL",
            "SPWPN_ORC_SLAYING",
            "SPWPN_PAIN",
            "SPWPN_PENETRATION",
            "SPWPN_PROTECTION",
            "SPWPN_REACHING",
            "SPWPN_REAPING",
            "SPWPN_RETURNING",
            "SPWPN_SPECTRAL",
            "SPWPN_SPEED",
            "SPWPN_VAMPIRISM",
            "SPWPN_VENOM",
            "SPWPN_VORPAL",
            "SPWPN_VULNERABILITY",
            "SPWPN_WEAKNESS",
        },
        armour_flags = {
            "ARMF_LAST_MULTI",
            "ARMF_NO_FLAGS",
            "ARMF_REGENERATION",
            "ARMF_RES_COLD",
            "ARMF_RES_CORR",
            "ARMF_RES_ELEC",
            "ARMF_RES_FIRE",
            "ARMF_RES_NEG",
            "ARMF_RES_POISON",
            "ARMF_RES_STEAM",
            "ARMF_STEALTH",
            "ARMF_VUL_COLD",
            "ARMF_VUL_FIRE",
            "ARMF_WILLPOWER",
        },
    },
    definitions_sha256 = "e9697ab8c518b752365c60b8ca18132b40ba51e82f492c1d835bcbea78548817",
}

return catalog
