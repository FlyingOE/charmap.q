# charmap.q

Pure q implementation to map character strings between local encoding and UTF-8.

## License

[Apache v2.0](./LICENSE)

## Usage

```q
.text.BASEDIR:`:path_to_charmaps
\l charmap.q

.text.decode[`gb18030;`replace;any_q_obj]    /all occurrences of strings/symbols will be decoded from GB18030 to UTF-8
.text.encode[`gb18030;`throw  ;any_q_obj]    /all occurrences of strings/symbols will be encoded from UTF-8 to GB18030

.io.sys_in  any_q_obj    /all occurrences of strings/symbols will be decoded from system default encoding to UTF-8
.io.sys_out any_q_obj    /all occurrences of strings/symbols will be encoded from UTF-8 to system default encoding
```

## Charmaps

This library supports the following encodings for now:

- `gb18030`

- `gbk` (not strictly compliant, handled by `gb18030` logic)

- `gb2312` (not strictly compliant, handled by `gb18030` logic)

### Generating a charmap

Take the `gb18030` as an example.

The [`Uncode_GB18030.q`](./Unicode_GB18030.q) script converts the [raw GB18030 codepoint file](./Unicode_GB18030.txt) into [`gb18030.charmap`](./gb18030.charmap) data file, which is loaded by [`charmap.q`](./charmap.q) at runtime when necessary.

The schema of `gb18030.charmap` is:

| `c`       | `t` | `f` | `a` | Remarks                                                                          |
|:---------:|:---:|:---:|:---:| -------------------------------------------------------------------------------- |
| `Unicode` | `j` |     |     | Unicode codepoints                                                               |
| `GB18030` | `X` |     |     | Byte sequences of the respective encoding. Field name must be the encoding name. |
