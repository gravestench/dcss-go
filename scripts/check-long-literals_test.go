package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const longLiteralSource = `package example

type Input struct {
	A int
	B int
	C int
	D int
	E int
	F int
	G int
	H int
	I int
	J int
}

func sample() Input {
	return Input{
		A: 1,
		B: 2,
		C: 3,
		D: 4,
		E: 5,
		F: 6,
		G: 7,
		H: 8,
		I: 9,
		J: 10,
	}
}
`

func TestLongCompositeLiteralGrouping(t *testing.T) {
	tests := []struct {
		name   string
		source string
		want   int
	}{
		{
			name:   "uninterrupted struct",
			source: longLiteralSource,
			want:   1,
		},
		{
			name: "blank line groups fields",
			source: strings.Replace(
				longLiteralSource,
				"\t\tF: 6,",
				"\n\t\tF: 6,",
				1,
			),
			want: 0,
		},
		{
			name: "comment alone does not group fields",
			source: strings.Replace(
				longLiteralSource,
				"\t\tF: 6,",
				"\t\t// Second set\n\t\tF: 6,",
				1,
			),
			want: 1,
		},
		{
			name: "generic struct",
			source: strings.NewReplacer(
				"type Input struct", "type Input[T any] struct",
				"Input {", "Input[int] {",
				"Input{", "Input[int]{",
			).Replace(longLiteralSource),
			want: 1,
		},
		{
			name: "unknown qualified map stays unrestricted",
			source: strings.Replace(
				longLiteralSource,
				"Input{",
				"outside.Lookup{",
				1,
			),
			want: 0,
		},
		{
			name: "imported project struct",
			source: strings.NewReplacer(
				"package example\n\n",
				"package example\n\nimport \"dcrawl-go/internal/content\"\n\n",
				"Input{",
				"content.SpellDef{",
			).Replace(longLiteralSource),
			want: 1,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			path := filepath.Join(t.TempDir(), "sample.go")

			if err := os.WriteFile(path, []byte(test.source), 0600); err != nil {
				t.Fatal(err)
			}

			issues, err := checkFile(path)

			if err != nil {
				t.Fatal(err)
			}

			if issues != test.want {
				t.Fatalf("issues = %d, want %d", issues, test.want)
			}
		})
	}
}
