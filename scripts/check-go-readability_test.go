package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestStructMapKeySpacing(t *testing.T) {
	tests := []struct {
		name   string
		source string
		want   int
	}{
		{
			name: "fields sharing a line",
			source: `package example

type Key struct {
	ClassID string
	SubtypeID string
}


func sample() {
	_ = map[Key]int{
		{
			"class", "subtype",
		}: 1,
	}
}
`,
			want: 1,
		},

		{
			name: "named array key",
			source: `package example

type Coord [2]int

func sample() {
	_ = map[Coord]int{
		{1, 2}: 1,
	}
}
`,
			want: 0,
		},

		{
			name: "named map with struct key",
			source: `package example

type Key struct {
	ClassID string
	SubtypeID string
}

type Rows map[Key]int

func sample() {
	_ = Rows{
		{"class", "subtype"}: 1,
	}
}
`,
			want: 1,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			path := filepath.Join(t.TempDir(), "sample.go")

			if err := os.WriteFile(path, []byte(test.source), 0600); err != nil {
				t.Fatal(err)
			}

			got, err := checkFile(path)

			if err != nil {
				t.Fatal(err)
			}

			if got != test.want {
				t.Fatalf("issues = %d, want %d", got, test.want)
			}
		})
	}
}

func TestStructCollectionValueSpacing(t *testing.T) {
	tests := []struct {
		name   string
		source string
		want   int
	}{
		{
			name: "positional struct in slice",
			source: `package example

type Point struct {
	X int
	Y int
}

func sample() {
	_ = []Point{
		{1, 2},
	}
}
`,
			want: 1,
		},

		{
			name: "anonymous struct in array",
			source: `package example

func sample() {
	_ = [...]struct{ X, Y int }{
		{1, 2},
	}
}
`,
			want: 2,
		},

		{
			name: "fixed array pair stays compact",
			source: `package example

func sample() {
	_ = [][2]int{
		{1, 2},
	}
}
`,
			want: 0,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			path := filepath.Join(t.TempDir(), "sample.go")

			if err := os.WriteFile(path, []byte(test.source), 0600); err != nil {
				t.Fatal(err)
			}

			got, err := checkFile(path)

			if err != nil {
				t.Fatal(err)
			}

			if got != test.want {
				t.Fatalf("issues = %d, want %d", got, test.want)
			}
		})
	}
}

func TestCrowdedIfCondition(t *testing.T) {
	tests := []struct {
		name   string
		source string
		want   int
	}{
		{
			name: "four checks on one line",
			source: `package example
func sample(a, b, c, d bool) {
	if a || b || c || d {
		return
	}
}
`,
			want: 1,
		},

		{
			name: "one check per line",
			source: `package example
func sample(a, b, c, d bool) {
	if a ||
		b ||
		c ||
		d {
		return
	}
}
`,
			want: 0,
		},

		{
			name: "ignore conditions inside a function literal",
			source: `package example
func sample(a, b, c, d bool) {
	if func() bool {
		return a || b || c || d
	}() {
		return
	}
}
`,
			want: 0,
		},

		{
			name: "count a nested if only once",
			source: `package example
func sample(a, b, c, d bool) {
	if func() bool {
		if a || b || c || d {
			return true
		}

		return false
	}() {
		return
	}
}
`,
			want: 1,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			path := filepath.Join(t.TempDir(), "sample.go")

			if err := os.WriteFile(path, []byte(test.source), 0600); err != nil {
				t.Fatal(err)
			}

			got, err := checkFile(path)

			if err != nil {
				t.Fatal(err)
			}

			if got != test.want {
				t.Fatalf("issues = %d, want %d", got, test.want)
			}
		})
	}
}

func TestLongBooleanCondition(t *testing.T) {
	tests := []struct {
		name   string
		source string
		want   int
	}{
		{
			name: "long if condition",
			source: `package example
func sample() {
	if thisConditionNameIsLongEnoughToMakeTheWholeExpressionHardToReadForHumans || b {
		return
	}
}
`,
			want: 1,
		},

		{
			name: "long for condition",
			source: `package example
func sample() {
	for thisConditionNameIsLongEnoughToMakeTheWholeExpressionHardToReadForHumans || b {
		return
	}
}
`,
			want: 1,
		},

		{
			name: "broken condition",
			source: `package example
func sample() {
	if thisConditionNameIsLongEnoughToMakeTheWholeExpressionHardToReadForHumans ||
		b {
		return
	}
}
`,
			want: 0,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			file := filepath.Join(t.TempDir(), "sample.go")

			if err := os.WriteFile(file, []byte(test.source), 0600); err != nil {
				t.Fatal(err)
			}

			got, err := checkFile(file)

			if err != nil {
				t.Fatal(err)
			}

			if got != test.want {
				t.Fatalf("issues = %d, want %d", got, test.want)
			}
		})
	}
}

func TestMultilineLiteralEntrySpacing(t *testing.T) {
	path := filepath.Join(t.TempDir(), "sample.go")
	source := `package example

type Row struct {
	Name string
	Value int
}

func sample() {
	_ = []Row{
		{
			Name: "first",
			Value: 1,
		},
		{
			Name: "second",
			Value: 2,
		},
	}
}
`

	if err := os.WriteFile(path, []byte(source), 0600); err != nil {
		t.Fatal(err)
	}

	crowded, err := checkFile(path)

	if err != nil {
		t.Fatal(err)
	}

	if crowded != 1 {
		t.Fatalf("crowded table issues = %d, want 1", crowded)
	}

	separated := strings.Replace(source, "},\n\t\t{", "},\n\n\t\t{", 1)

	if err := os.WriteFile(path, []byte(separated), 0600); err != nil {
		t.Fatal(err)
	}

	issues, err := checkFile(path)

	if err != nil {
		t.Fatal(err)
	}

	if issues != 0 {
		t.Fatalf("separated table issues = %d, want 0", issues)
	}
}
