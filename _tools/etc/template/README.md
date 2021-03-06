# {{ .BINARY }}

{{ .BINARY }} は YAML データと [text/template](http://golang-jp.org/pkg/text/template/) の記法に従ったテンプレートを使ってテキストを標準出力にレンダリングするコマンドラインツールです。

## Description

* コマンドオプションで YAML 形式のデータファイルと [text/template](http://golang-jp.org/pkg/text/template/) スタイルのテンプレートファイルのパスを指定すると、テキストが標準出力にレンダリングされる。
* YAML データファイルではハッシュの値にキーを指定することができる。
* 独自のテンプレート関数を実装している。
  * [Masterminds/sprig: Useful template functions for Go templates.](https://github.com/Masterminds/sprig) というテンプレート関数ライブラリを発見したけど、べ、別に泣いてないですよ。

## Demonstration

![demo](https://raw.githubusercontent.com/yuta-masano/mktpl/images/_tools/etc/images/mktpl.gif)

## Motivation

### VS [mustache](https://mustache.github.io/)

* ロジックレスでシンプルなテンプレートエンジンの、[mustache](https://mustache.github.io/) というものがある。
* Bash で実装された CLI もあるが、データの受け渡しがシェル変数または環境変数としてしか渡せず、データが増えてくるとつらい。
* ロジックレスなテンプレートが売りだが、やっぱり多少はロジックを含めたい。

## Installation

[Releases ページ](https://github.com/yuta-masano/{{ .BINARY }}/releases)からダウンロードしてください。

あるいは、Go 1.11 以降で `go get` してください。

```
$ go get github.com/yuta-masano/{{ .BINARY }}
```

## Usage

```
$ {{ .HELP_OUT }}
{{ exec .HELP_OUT -}}
```

## Template Functions

### \{\{ join list separator \}\}

Same as [strings.Join](https://golang.org/pkg/strings/#Join) function.

### \{\{ exec command \[flags\] \[args\] \}\}

Execute **single** external command and return it's stdout output.  
**Single** means that no pipe (|), no redirection (>), no command connection (&, &&, ;, ||).

### \{\{ exclude list string... \}\}

Return a new list which is excluded specified strings from the elements in specified list.

## License

The MIT License (MIT)

## Author

[Yuta MASANO](https://github.com/yuta-masano)
