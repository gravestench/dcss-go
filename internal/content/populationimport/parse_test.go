package populationimport

import "testing"

func TestParseDungeonRowsKeepsDuplicatesAndSourceLines(t *testing.T) {
	source := []byte("static const vector<pop_entry> population[] =\n{\n{ // Dungeon\n  { 1, 3, 1000, " +
		"FLAT, MONS_RAT },\n  { 4, 5, 500, FALL, MONS_RAT },\n},\n{ // Temple\n},\n};\n")
	rows, err := parseDungeonRows(source)

	if err != nil || len(rows) != 2 || rows[0].MonsterID != "MONS_RAT" ||
		rows[1].MonsterID != "MONS_RAT" || rows[0].SourceLine != 4 || rows[1].SourceLine != 5 {
		t.Fatalf("parsed rows %+v, %v", rows, err)
	}

	for _, bad := range []string{
		"static const vector<pop_entry> population[] =\n{\n{ // Dungeon\n  { 1, bad, 1000, FLAT, MONS_RAT },\n},\n};\n",
		"static const vector<pop_entry> population[] =\n{\n{ // Dungeon\n  { 1, 3, " +
			"999999999999999999999999, FLAT, MONS_RAT },\n},\n};\n",
		"static const vector<pop_entry> population[] =\n{\n{ // Dungeon\n  { 1, 3, 1000, FLAT, MONS_RAT },\n};\n",
	} {
		if _, err := parseDungeonRows([]byte(bad)); err == nil {
			t.Fatalf("malformed table accepted: %q", bad)
		}
	}
}
