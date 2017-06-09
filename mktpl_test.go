package main

import (
	"testing"
	"text/template"
)

func TestRender(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		inData string
		inTpl  string
		expect string
	}{
		{
			inData: `TEST: test-01 . * ? %`,
			inTpl:  `test = {{ .TEST }}`,
			expect: `test = test-01 . * ? %`,
		},
		{
			inData: `TEST: 'test-02 . * ? %'
TEST_NEST: '{{ .TEST }} nest'`,
			inTpl:  `test = {{ .TEST_NEST }}`,
			expect: `test = test-02 . * ? % nest`,
		},
		{
			inData: `TEST_NEST: '{{ .TEST}} nest'
TEST: test-03`,
			inTpl:  `test = {{ .TEST_NEST }}`,
			expect: `test = test-03 nest`,
		},
	}

	for i, c := range testCases {
		tpl, _ := template.New("").Parse(c.inTpl)
		out, err := render([]byte(c.inData), tpl)
		if err != nil {
			t.Fatal(err)
		}
		if string(out) != c.expect {
			t.Fatalf("failed(%d) expected=%s, but got=%s", i+1, c.expect, string(out))
		}
	}
}
