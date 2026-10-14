package sourceparse

import (
	"strings"
	"testing"
)

func TestTag34LinesSelectsNestedAndElseBranches(t *testing.T) {
	input := `start
#if TAG_MAJOR_VERSION == 34
old
#if TAG_MAJOR_VERSION > 34
future
#else
nested_old
#endif
#else
new
#endif
end`
	lines, err := Tag34Lines("job-data.h", []byte(input))

	if err != nil {
		t.Fatal(err)
	}

	joined := strings.Join(lines, "\n")

	for _, text := range []string{
		"start",
		"old",
		"nested_old",
		"end",
	} {
		if !strings.Contains(joined, text) {
			t.Fatalf("missing %q in %q", text, joined)
		}
	}

	for _, text := range []string{"future", "new"} {
		if strings.Contains(joined, text) {
			t.Fatalf("inactive %q in %q", text, joined)
		}
	}
}

func TestTag34LinesRejectsUnsupportedDirective(t *testing.T) {
	_, err := Tag34Lines("job-data.h", []byte("#if FEATURE_X\nold\n#endif\n"))

	if err == nil ||
		!strings.Contains(err.Error(), "job-data.h") ||
		!strings.Contains(err.Error(), "FEATURE_X") {
		t.Fatalf("unsupported directive accepted: %v", err)
	}
}

func TestTag34LinesSelectsElifTag34Branch(t *testing.T) {
	input := `#if TAG_MAJOR_VERSION > 34
future
#elif TAG_MAJOR_VERSION == 34
current
#else
other
#endif`
	lines, err := Tag34Lines("item-prop-enum.h", []byte(input))

	if err != nil {
		t.Fatal(err)
	}

	joined := strings.Join(lines, "\n")

	if !strings.Contains(joined, "current") ||
		strings.Contains(joined, "future") ||
		strings.Contains(joined, "other") {
		t.Fatalf("wrong active branch: %q", joined)
	}
}

func TestActiveEnumIDsRetainsConcreteTag34Members(t *testing.T) {
	ids, err := ActiveEnumIDs(
		"job-type.h",
		[]byte("enum job_type {\n JOB_FIGHTER,\n#if TAG_MAJOR_VERSION == 34\n JOB_PRIEST,\n"+
			"#else\n JOB_FUTURE,\n#endif\n NUM_JOBS,\n JOB_UNKNOWN = 100,\n};\n"),
		"JOB_",
	)

	if err != nil {
		t.Fatal(err)
	}

	if len(ids) != 2 {
		t.Fatalf("active IDs = %v", ids)
	}

	for _, id := range []string{"JOB_FIGHTER", "JOB_PRIEST"} {
		if _, found := ids[id]; !found {
			t.Fatalf("missing %s", id)
		}
	}
}

func TestTag34NumberedLinesPreservesQuotedCommentsAndLocations(t *testing.T) {
	input := "first\n#if TAG_MAJOR_VERSION > 34\nfuture\n#else\n\"rat, // friend\" // " +
		"comment\n/* block\ncomment */ active\n#endif\n"
	lines, err := Tag34NumberedLines("mon-data.h", []byte(input))

	if err != nil {
		t.Fatal(err)
	}

	var got []Line

	for _, line := range lines {
		if strings.TrimSpace(line.Text) != "" {
			got = append(got, line)
		}
	}

	if len(got) != 3 ||
		got[1].Number != 5 ||
		strings.TrimSpace(got[1].Text) != `"rat, // friend"` ||
		got[2].Number != 7 || strings.TrimSpace(got[2].Text) != "active" {
		t.Fatalf("unexpected numbered lines: %#v", got)
	}
}

func TestTag34NumberedLinesRejectsUnknownConditional(t *testing.T) {
	_, err := Tag34NumberedLines("mon-data.h", []byte("#ifdef EXTRA\nrow\n#endif"))

	if err == nil ||
		!strings.Contains(err.Error(), "mon-data.h:1") {
		t.Fatalf("unknown conditional accepted: %v", err)
	}
}
