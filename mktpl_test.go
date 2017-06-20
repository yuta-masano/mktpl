package main

import (
	"regexp"
	"testing"
)

func TestIsValidFlags(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		d       string
		t       string
		isError bool
	}{
		{
			d:       "",
			t:       "",
			isError: true,
		},
		{
			d:       "bar",
			t:       "",
			isError: true,
		},
		{
			d:       "",
			t:       "foo",
			isError: true,
		},
		{
			d:       "bar",
			t:       "foo",
			isError: false,
		},
	}

	for i, c := range testCases {
		dataPath, tplPath = c.d, c.t
		if err := isValidFlags(); (err == nil) == c.isError {
			t.Fatalf("[%d] invalid error state: expected=%t, but got=%t",
				i+1, c.isError, (err == nil) == c.isError)
		}
	}
}

func TestRender(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		inData string
		inTpl  string
		expect string
	}{
		{
			inData: `TEST: aaa . * ? %`,
			inTpl:  `test01 is {{ .TEST }}`,
			expect: `test01 is aaa . * ? %`,
		},
		{
			inData: `TEST: 'aaa . * ? %'
TEST_NEST: '{{ .TEST }} nest'`,
			inTpl:  `test02 is {{ .TEST_NEST }}`,
			expect: `test02 is aaa . * ? % nest`,
		},
		{
			inData: `TEST_NEST: '{{ .TEST }} nest'
TEST: aaa`,
			inTpl:  `test03 is {{ .TEST_NEST }}`,
			expect: `test03 is aaa nest`,
		},
		{
			inData: `TEST: [foo, bar, baz]`,
			inTpl:  `test04 is {{ join .TEST "," }}`,
			expect: `test04 is foo,bar,baz`,
		},
		{
			// 0... は 8 進数として解釈される。
			inData: `TEST: [foo, bar, baz, 1, '%.wer', 'hoge', '0123', 017]
TEST_NEST: '{{ join {{ .TEST }} "," }}'`,
			inTpl:  `test05 is {{ join .TEST "," }}`,
			expect: `test05 is foo,bar,baz,1,%.wer,hoge,0123,15`,
		},
		{
			inData: `TEST: echo -n test06`,
			inTpl:  `test06 is {{ exec .TEST }}`,
			expect: `test06 is test06`,
		},
		{
			inData: `TEST: echo -n 'test07 test07'`,
			inTpl:  `test07 is {{ exec .TEST }}`,
			expect: `test07 is test07 test07`,
		},
		{
			inData: `TEST: ""`,
			inTpl:  `test08 is {{ exec "echo -n 'test08 test08'" }}`,
			expect: `test08 is test08 test08`,
		},
		{
			inData: `TEST: echo -n 'test09'
TEST_NEST: test09 {{ exec .TEST }}`,
			inTpl:  `test09 is {{ .TEST_NEST }} nest`,
			expect: `test09 is test09 test09 nest`,
		},
	}

	for i, c := range testCases {
		tpl, err := parseTemplate(c.inTpl)
		if err != nil {
			t.Fatal(err)
		}
		out, err := render([]byte(c.inData), tpl)
		if err != nil {
			t.Fatal(err)
		}
		if string(out) != c.expect {
			t.Fatalf("[%d] failed in templateing: expected=%s, but got=%s",
				i+1, c.expect, string(out))
		}
	}
}

func BenchmarkSimpleRe(b *testing.B) {
	inData := `TEST: echo -n 'test09'
TEST_NEST: test09 {{ exec .TEST }}`
	inTpl := `test09 is {{ .TEST_NEST }} nest`

	re = regexp.MustCompile(`{{[-.\s\w]+}}`)

	b.ResetTimer()
	for n := 0; n < b.N; n++ {
		tpl, err := parseTemplate(inTpl)
		if err != nil {
			b.Fatal(err)
		}
		_, err = render([]byte(inData), tpl)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkStrictRe(b *testing.B) {
	inData := `TEST: echo -n 'test09'
TEST_NEST: test09 {{ exec .TEST }}`
	inTpl := `test09 is {{ .TEST_NEST }} nest`

	re = regexp.MustCompile(`{{\s*-?\s*(\.?\w+\s*)+-?\s*}}`)

	b.ResetTimer()
	for n := 0; n < b.N; n++ {
		tpl, err := parseTemplate(inTpl)
		if err != nil {
			b.Fatal(err)
		}
		_, err = render([]byte(inData), tpl)
		if err != nil {
			b.Fatal(err)
		}
	}
}
