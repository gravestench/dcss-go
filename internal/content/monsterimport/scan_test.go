package monsterimport

import (
	"os"
	"strings"
	"testing"
)

func TestParsePinnedRowsWhenRequested(t *testing.T) {
	path := os.Getenv("DCRAWL_MON_DATA")

	if path == "" {
		t.Skip("set DCRAWL_MON_DATA for an explicit source scan")
	}

	data, err := os.ReadFile(path)

	if err != nil {
		t.Fatal(err)
	}

	rows, err := parseRows(path, data)

	if err != nil {
		t.Fatal(err)
	}

	defined, removed := 0, 0

	for _, row := range rows {
		if row.Removed {
			removed++
		} else {
			defined++
		}
	}

	if defined != 562 || removed != 120 {
		t.Fatalf("source partition defined=%d removed=%d", defined, removed)
	}
}

func row(id, name string) string {
	return "{\n" + id + `, 'r', BROWN, ` + name +
		`, M_WARM_BLOOD, mrd(MR_RES_FIRE |` + "\n" +
		` MR_RES_COLD, 3) | MR_VUL_POISON, 1, ` + id +
		`, ` + id +
		`, MH_NATURAL, 0, { {AT_BITE, AF_PLAIN, 3}, ` +
		`AT_NO_ATK, AT_NO_ATK, AT_NO_ATK }, 1, 25, 1, 10, ` +
		`MST_NO_SPELLS, true, S_SILENT, I_ANIMAL, HT_LAND, 10, ` +
		`DEFAULT_ENERGY, MONUSE_NOTHING, SIZE_TINY, ` +
		`MON_SHAPE_QUADRUPED, {TILEP_MONS_RAT}, TILE_CORPSE_RAT` +
		"\n}, // trailing comment\n"
}

func TestParseRowsNestedAndRemoved(t *testing.T) {
	input := `#define AXED_MON(id, name) \
{ id, name },
static monsterentry mondata[] =
{
#if TAG_MAJOR_VERSION == 34
AXED_MON(MONS_BUMBLEBEE, "bee, // removed")
#endif
` + row("MONS_RAT", `"rat, // \"friend\""`) + `DUMMY(MONS_BEAR, 'h', LIGHTGREY, "bear", TILEP_MONS_BEAR)
};`
	rows, err := parseRows("mon-data.h", []byte(input))

	if err != nil {
		t.Fatal(err)
	}

	if len(rows) != 2 ||
		!rows[0].Removed ||
		rows[0].Line != 6 ||
		rows[0].RemovedName != "bee, // removed" ||
		rows[1].ID != "MONS_RAT" ||
		rows[1].Line != 8 ||
		len(rows[1].Fields) != 28 {
		t.Fatalf("wrong rows: %#v", rows)
	}

	if rows[1].Fields[3] != `"rat, // \"friend\""` ||
		!strings.Contains(rows[1].Fields[5], "MR_RES_COLD, 3") || !strings.Contains(rows[1].Fields[11], "AT_NO_ATK") {
		t.Fatalf("lost nested data: %#v", rows[1].Fields)
	}
}

func TestParseRowsRejectsMalformed(t *testing.T) {
	base := "static monsterentry mondata[] =\n{\n"

	for _, tc := range []struct {
		name string
		body string
	}{
		{
			name: "short row",
			body: "{ MONS_RAT, 'r' },\n};",
		},

		{
			name: "unbalanced",
			body: "{ MONS_RAT, 'r',\n};",
		},

		{
			name: "string",
			body: "{ MONS_RAT, \"unterminated },\n};",
		},

		{
			name: "unknown macro",
			body: "UNKNOWN(MONS_RAT)\n};",
		},

		{
			name: "unknown conditional",
			body: "#if FEATURE\nfoo\n#endif\n};",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			_, err := parseRows("mon-data.h", []byte(base+tc.body))

			if err == nil || !strings.Contains(err.Error(), "mon-data.h") {
				t.Fatalf("malformed source accepted: %v", err)
			}
		})
	}
}
