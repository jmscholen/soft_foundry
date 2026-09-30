package main

import (
	"os"

	"github.com/jmscholen/soft_foundry/internal/cli"
)

func main() {
	root, _ := os.Getwd()
	os.Exit(cli.New(os.Args[1:], root, os.Stdout, os.Stderr, os.Stdin).Run())
}
