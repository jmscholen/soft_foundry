package internal

import "fmt"

type TargetError struct{ Msg string }

func (e TargetError) Error() string { return e.Msg }

type InternalError struct {
	Component  string
	Msg        string
	Diagnostic []string
}

func (e InternalError) Error() string {
	return fmt.Sprintf("%s: %s", e.Component, e.Msg)
}
