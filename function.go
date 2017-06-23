package main

import (
	"fmt"
	"os/exec"
	"strings"
	"text/template"

	"github.com/mattn/go-shellwords"
)

var tplFuncMap = template.FuncMap{
	"join":    tplJoin,
	"exec":    tplExec,
	"exclude": tplExclude,
}

func tplJoin(a []interface{}, sep string) string {
	var s []string
	for _, v := range a {
		s = append(s, fmt.Sprint(v))
	}
	return strings.Join(s, sep)
}

func tplExec(a interface{}) string {
	execs, err := shellwords.Parse(fmt.Sprint(a))
	if err != nil {
		return err.Error()
	}
	cmd := exec.Command(execs[0], execs[1:]...)
	out, err := cmd.Output()
	if err != nil {
		return err.Error()
	}
	return string(out)
}

func tplExclude(a []interface{}, s ...string) []interface{} {
	var n []interface{}
LOOP:
	for _, v := range a {
		for _, w := range s {
			if fmt.Sprint(v) == w {
				continue LOOP
			}
		}
		n = append(n, v)
	}
	return n
}
