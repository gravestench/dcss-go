package spellimport

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestGenerateAndCheckUseOnlyExplicitSourceFiles(t *testing.T) {
	root := t.TempDir()
	files := map[string]string{
		"tag-version.h": "#define TAG_MAJOR_VERSION 34\n",
		"spell-type.h":  "enum spell_type : int {\n SPELL_NO_SPELL,\n NUM_SPELLS\n};\n",
		"spl-data.h": `static const struct spell_desc spelldata[] = {
{
 SPELL_NO_SPELL, "nonexistent spell", spschool::none, spflag::testing,
 1, 0, -1, -1, 1, 0, TILEG_ERROR,
},
};`,
		"spl-util.cc": "const set<spell_type> removed_spells =\n{\n};\n",
		"spl-util.h":  "enum class spschool {\n none = 0,\n};\n",
		"spl-cast.h":  "enum class spflag {\n none = 0,\n testing = 1,\n};\n",
	}

	for name, body := range files {
		if err := os.WriteFile(filepath.Join(root, name), []byte(body), 0600); err != nil {
			t.Fatal(err)
		}
	}

	out := filepath.Join(root, "spells.json")

	if err := Write(root, out, false); err != nil {
		t.Fatal(err)
	}

	if err := Write(root, out, true); err != nil {
		t.Fatal(err)
	}

	original, err := os.ReadFile(out)

	if err != nil {
		t.Fatal(err)
	}

	if !strings.Contains(string(original), `"id": "SPELL_NO_SPELL"`) {
		t.Fatal("missing generated sentinel")
	}

	if err := os.WriteFile(out, []byte("corrupt"), 0600); err != nil {
		t.Fatal(err)
	}

	if err := Write(root, out, true); err == nil {
		t.Fatal("check accepted changed committed artifact")
	}
}
