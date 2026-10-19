package main

import (
	"flag"
	"reflect"
	"testing"
)

func TestRepeatedModDirFlag(t *testing.T) {
	var dirs modDirs

	flags := flag.NewFlagSet("crawl", flag.ContinueOnError)
	flags.Var(&dirs, "mod-dir", "ordered Lua mod directory")

	arguments := []string{
		"--mod-dir",
		"first",
		"--mod-dir",
		"second",
	}

	if err := flags.Parse(arguments); err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual([]string(dirs), []string{"first", "second"}) {
		t.Fatalf("mod directories = %q", dirs)
	}

	if err := flags.Parse([]string{"--mod-dir="}); err == nil {
		t.Fatal("empty mod directory accepted")
	}
}
