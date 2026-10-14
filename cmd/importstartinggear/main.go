package main

import (
	"flag"
	"fmt"
	"os"

	"dcrawl-go/internal/content/startinggearimport"
)

func main() {
	source := flag.String("source", "", "pinned crawl-ref/source directory")
	out := flag.String("out", "", "committed starting gear artifact path")
	check := flag.Bool("check", false, "verify the output is current without writing it")
	flag.Parse()

	if err := startinggearimport.Write(*source, *out, *check); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
