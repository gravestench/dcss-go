package monsterimport

import (
	"os"
	"regexp"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func TestDecodePinnedRowsWhenRequested(t *testing.T) {
	path := os.Getenv("DCRAWL_MON_DATA")

	if path == "" {
		t.Skip("set DCRAWL_MON_DATA for explicit pinned decode")
	}

	data, err := os.ReadFile(path)

	if err != nil {
		t.Fatal(err)
	}

	rows, err := parseRows(path, data)

	if err != nil {
		t.Fatal(err)
	}

	all := regexp.MustCompile(`[A-Z][A-Z0-9_]+`).FindAllString(string(data), -1)
	makeSet := func() map[string]bool {
		return map[string]bool{}
	}

	s := symbolSets{
		monster:       makeSet(),
		attackType:    makeSet(),
		attackFlavour: makeSet(),
		spellbook:     makeSet(),
		classFlag:     makeSet(),
		resistance:    makeSet(),
		holiness:      makeSet(),
		shout:         makeSet(),
		intelligence:  makeSet(),
		habitat:       makeSet(),
		itemUse:       makeSet(),
		size:          makeSet(),
		shape:         makeSet(),
		colour:        makeSet(),
		tileVariation: makeSet(),
	}

	for _, tok := range all {
		switch {
		case strings.HasPrefix(tok, "MONS_"):
			s.monster[tok] = true

		case strings.HasPrefix(tok, "AT_"):
			s.attackType[tok] = true

		case strings.HasPrefix(tok, "AF_"):
			s.attackFlavour[tok] = true

		case strings.HasPrefix(tok, "MST_"):
			s.spellbook[tok] = true

		case strings.HasPrefix(tok, "MR_"):
			s.resistance[tok] = true

		case strings.HasPrefix(tok, "MH_"):
			s.holiness[tok] = true

		case strings.HasPrefix(tok, "M_"):
			s.classFlag[tok] = true

		case strings.HasPrefix(tok, "S_"):
			s.shout[tok] = true

		case strings.HasPrefix(tok, "I_"):
			s.intelligence[tok] = true

		case strings.HasPrefix(tok, "HT_"):
			s.habitat[tok] = true

		case strings.HasPrefix(tok, "MONUSE_"):
			s.itemUse[tok] = true

		case strings.HasPrefix(tok, "SIZE_"):
			s.size[tok] = true

		case strings.HasPrefix(tok, "MON_SHAPE_"):
			s.shape[tok] = true

		case strings.HasPrefix(tok, "TVARY_"):
			s.tileVariation[tok] = true

		default:
			s.colour[tok] = true
		}
	}

	s.attackType["AT_NONE"] = true
	s.attackFlavour["AF_PLAIN"] = true
	s.tileVariation["TVARY_NONE"] = true
	s.classFlag["M_NO_EXP_GAIN"] = true
	s.classFlag["M_NO_THREAT"] = true

	defs, err := decodeRows(path, rows, s)

	if err != nil {
		t.Fatal(err)
	}

	if len(defs) != 682 {
		t.Fatalf("decoded %d records", len(defs))
	}
}

func testSymbols() symbolSets {
	set := func(values ...string) map[string]bool {
		m := map[string]bool{}

		for _, v := range values {
			m[v] = true
		}

		return m
	}

	return symbolSets{
		monster: set(
			"MONS_RAT",
			"MONS_ORC_WIZARD",
			"MONS_FIRE_DRAGON",
			"MONS_DEMONSPAWN",
			"MONS_SPRIGGAN",
			"MONS_PROGRAM_BUG",
		),
		attackType:    set("AT_NONE", "AT_BITE", "AT_HIT", "AT_CLAW"),
		attackFlavour: set("AF_PLAIN", "AF_FIRE"),
		spellbook:     set("MST_NO_SPELLS", "MST_ORC_WIZARD"),
		classFlag:     set("M_WARM_BLOOD", "M_NO_EXP_GAIN", "M_NO_THREAT", "M_CANT_SPAWN"),
		resistance:    set("MR_NO_FLAGS", "MR_RES_FIRE", "MR_RES_COLD", "MR_RES_POISON", "MR_VUL_COLD", "MR_VUL_POISON"),
		holiness:      set("MH_NATURAL", "MH_DEMONIC"),
		shout:         set("S_SILENT"),
		intelligence:  set("I_ANIMAL"),
		habitat:       set("HT_LAND"),
		itemUse:       set("MONUSE_NOTHING"),
		size:          set("SIZE_TINY"),
		shape:         set("MON_SHAPE_QUADRUPED"),
		colour:        set("BROWN"),
		tileVariation: set("TVARY_NONE", "TVARY_MOD"),
	}
}

func testRow(t *testing.T) sourceRow {
	t.Helper()
	rows, err := parseRows("mon-data.h", []byte("static monsterentry mondata[] = {\n"+row("MONS_RAT", `"rat"`)+"};"))

	if err != nil {
		t.Fatal(err)
	}

	return rows[0]
}

func TestDecodeGoldenRows(t *testing.T) {
	rat := testRow(t)

	wizard := rat
	wizard.ID = "MONS_ORC_WIZARD"
	wizard.Fields = append([]string(nil), rat.Fields...)
	wizard.Fields[0] = wizard.ID
	wizard.Fields[16] = "MST_ORC_WIZARD"

	dragon := rat
	dragon.ID = "MONS_FIRE_DRAGON"
	dragon.Fields = append([]string(nil), rat.Fields...)
	dragon.Fields[0] = dragon.ID
	dragon.Fields[5] = "mrd(MR_RES_FIRE, 2) | MR_VUL_COLD"
	dragon.Fields[11] = "{ {AT_BITE, AF_PLAIN, 30}, {AT_CLAW, AF_PLAIN, 15}, {AT_HIT, AF_FIRE, 10}, AT_NO_ATK }"

	demon := rat
	demon.ID = "MONS_DEMONSPAWN"
	demon.Fields = append([]string(nil), rat.Fields...)
	demon.Fields[0] = demon.ID
	demon.Fields[9] = "MH_NATURAL | MH_DEMONIC"

	spriggan := rat
	spriggan.ID = "MONS_SPRIGGAN"
	spriggan.Fields = append([]string(nil), rat.Fields...)
	spriggan.Fields[0] = spriggan.ID
	spriggan.Fields[22] = "MOVE_ENERGY(6)"

	bug := rat
	bug.ID = "MONS_PROGRAM_BUG"
	bug.Fields = append([]string(nil), rat.Fields...)
	bug.Fields[0] = bug.ID
	bug.Fields[20] = "HT_LAND"
	bug.Fields[21] = "0"
	bug.Fields[13] = "0"
	bug.Fields[4] = "M_NOT_DANGEROUS | M_CANT_SPAWN"

	defs, err := decodeRows("mon-data.h", []sourceRow{
		rat,
		wizard,
		dragon,
		demon,
		spriggan,
		bug,
	}, testSymbols())

	if err != nil {
		t.Fatal(err)
	}

	if len(defs) != 6 ||
		defs[0].Glyph != 'r' ||
		defs[0].AverageHP10x != 25 ||
		defs[0].Attacks[0].Damage != 3 || defs[0].Attacks[3].TypeID != "AT_NONE" {
		t.Fatalf("rat decoded incorrectly: %+v", defs[0])
	}

	if defs[1].SpellbookID != "MST_ORC_WIZARD" {
		t.Fatalf("wizard spellbook: %+v", defs[1])
	}

	if len(defs[2].Resistances) != 2 || defs[2].Resistances[0] != (content.MonsterResistance{
		ID:    "MR_RES_FIRE",
		Level: 2,
	}) || defs[2].Resistances[1] != (content.MonsterResistance{
		ID:    "MR_RES_COLD",
		Level: -1,
	}) || defs[2].Attacks[2].Damage != 10 {
		t.Fatalf("dragon: %+v", defs[2])
	}

	if strings.Join(defs[3].Holiness, ",") != "MH_NATURAL,MH_DEMONIC" {
		t.Fatalf("demon: %+v", defs[3])
	}

	if defs[4].Energy.Move != 6 || defs[4].Energy.Attack != 10 || defs[4].Energy.PickupPercent != 100 {
		t.Fatalf("spriggan: %+v", defs[4])
	}

	if defs[5].Speed != 0 || defs[5].AverageHP10x != 0 ||
		strings.Join(defs[5].Flags, ",") != "M_NO_EXP_GAIN,M_NO_THREAT,M_CANT_SPAWN" {
		t.Fatalf("bug: %+v", defs[5])
	}
}

func TestDecodeRejectsUnknownExpressions(t *testing.T) {
	for _, tc := range []struct {
		name  string
		field int
		value string
	}{
		{
			name:  "flag",
			field: 4,
			value: "M_UNKNOWN",
		},
		{
			name:  "enum",
			field: 16,
			value: "MST_UNKNOWN",
		},
		{
			name:  "energy macro",
			field: 22,
			value: "TURBO_ENERGY(4)",
		},
		{
			name:  "arithmetic",
			field: 12,
			value: "1 + UNKNOWN",
		},
		{
			name:  "attack",
			field: 11,
			value: "{ {AT_FAKE, AF_PLAIN, 3}, AT_NO_ATK, AT_NO_ATK, AT_NO_ATK }",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			row := testRow(t)
			row.Fields[tc.field] = tc.value

			if _, err := decodeRows("mon-data.h", []sourceRow{row}, testSymbols()); err == nil ||
				!strings.Contains(err.Error(), "MONS_RAT") {
				t.Fatalf("unknown expression accepted: %v", err)
			}
		})
	}
}
