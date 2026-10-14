package main

import (
	"os"
	"path/filepath"
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
