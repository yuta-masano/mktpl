package main

import (
	"fmt"
	"os/exec"
	"strings"
	"text/template"

	"github.com/mattn/go-shellwords"
)

var tplFuncMap = template.FuncMap{
	"implode": tplImplode,
	"exec":    tplExec,
	"exclude": tplExclude,
}

func tplImplode(a []interface{}, sep string) string {
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
	var excluded []interface{}
LOOP:
	for _, value := range a {
		for _, w := range s {
			if fmt.Sprint(value) == w {
				continue LOOP
			}
		}
		excluded = append(excluded, value)
	}

	return excluded
}

// mergeTemplateFuncMaps は複数の template.FuncMap をマージして返す。
func mergeTemplateFuncMaps(templateFuncMaps ...template.FuncMap) template.FuncMap {
	merged := make(template.FuncMap)

	for _, tfm := range templateFuncMaps {
		for k, v := range tfm {
			merged[k] = v
		}
	}

	return merged
}
