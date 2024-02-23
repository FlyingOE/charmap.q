//////////////////////////////////////////////////////////////////////////////
// Multilingual text encoding conversion (pure q implementation)
// 多语言文本编码转码（纯q实现）
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// System text I/O conversions
// 系统文本I/O相关转码
\d .io

/ System default codepage
.io.DEFAULT_CP:{
  :$[.z.o like"w*"
      ;{ enc:system"powershell -Command \"[System.Text.Encoding]::Default\" ";
        :"I"$trim last ":"vs first enc where enc like"WindowsCodePage *";
       }[]
    ;.z.o like"l*"
      ;{ loc:system"locale charmap";
        :`$lower ssr[;"-";""] first loc;
       }[]
    /;.z.o like"..."
      ;'"nyi: add support for ",.Q.s1 .z.o;
   ];
 }[];

/ Convert input from system to UTF-8
.io.sys_in: { .text.decode[.text.getEnc .io.DEFAULT_CP;`replace;x] };

/ Convert from UTF-8 to output to system
.io.sys_out:{ .text.encode[.text.getEnc .io.DEFAULT_CP;`throw  ;x] };

//////////////////////////////////////////////////////////////////////////////
// Text encoding conversions
// 文本编码转码
\d .text

.text.BASEDIR: @[value;`.text.BASEDIR;{hsym`$"E:/DEV/CHF.proj/Hibor.com.cn"}];

/ Supported codepages
.text.CODEPAGES:`cp`enc`actual!/:(
  (  936;`gbk    ;`gb18030 )
 ;(52936;`gb2312 ;`gb18030 )
 ;(54936;`gb18030;` )
 ;(65001;`utf8   ;` )
 );

/ Guess the encoding from a codepage or an encoding name
.text.getEnc:{
  enc:first ?[.text.CODEPAGES;;();(^;`enc;`actual)]
    enlist$[
       10h=t:type x  ;(like;`enc;lower x)
     ;-11h=t         ;(like;`enc;lower string x)
     ;t in -5 -6 -7h ;(=;`cp;x)
     ;'"nyi: codepage ",string x ];
  :$[null enc ;`$$[10h=t;x;string x] ;enc ];
 };

/ Encode a Unicode codepoint into a UTF-8 byte sequence
.text.toUTF8:{
  cp:"i"$0x0 sv -8#(7#0x00),$[4h=type(),x;(),x;0x0 vs x]; //Unicode codepoint
  :$[cp<0x0 sv 0x0080     //1-byte seq
     ;-1#0x0 vs cp
   ;cp<0x0 sv 0x0800      //2-byte seq
     ;0b sv/:(110b;10b),'5 10 cut 0b vs"h"$cp
   ;cp<0x0 sv 0x00010000  //3-byte seq
     ;0b sv/:(1110b;10b;10b),'0 4 10 cut -16#0b vs cp
   ;cp<0x0 sv 0x00110000  //4-byte seq
     ;0b sv/:(11110b;10b;10b;10b),'3 6 12 18 cut -24#0b vs cp
   /;default
     ;'"out of range: U+",.text.hexstr cp
   ];
 };

/ Decode all string/symbol occurrences in an object into UTF-8.
/<p>
/ @param cp_enc (short|int|long|symbol) source codepage or encoding.
/ @param err (symbol) error handling when mapping fails:
/   {@code `} (raise exception, default option),
/   {@code `ignore} (ignores the character altogether),
/   {@code `replace} (replace with <tt>U+FFFD</tt>, the replacement character),
/   {@code `escape} (replace as a <tt>"\\x????"</tt> sequence).
/<p>
/ @see .text.encode
.text.decode:{[cp_enc;err;x]
  enc:.text.getEnc cp_enc;
  if[enc~`utf8; :x ];
  tok:.text.TOKENIZER enc;
  if[(::)~tok; '"nyi: no tokenizer for ",string enc ];
  map:{[m;e;c] $[""~r:m c;e c;r] }[
    .text.map.get[enc;`utf8]
   ;$[err~`ignore ;{""}
     ;err~`replace;{y;x} .text.toUTF8 0xFFFD
     ;err~`escape ;{"\\x",.text.hexstr"x"$x}
       ;{'"invalid codepoint ",.text.hexstr"x"$x} ]
   ;];
  :.text.xcode.any[map;tok;x];
 };

/ Encode all string/symbol occurrences in an object into the given codepage.
/<p>
/ @param cp_enc (short|int|long|symbol) target codepage or encoding.
/ @param err (symbol) error handling when mapping fails:
/   {@code `} (raise exception, default option),
/   {@code `ignore} (ignores the character altogether),
/<p>
/ @see .text.decode
.text.encode:{[cp_enc;err;x]
  enc:.text.getEnc cp_enc;
  if[enc~`utf8; :x ];
  tok:.text.TOKENIZER.utf8;
  map:{[m;e;c] $[""~r:m c;e c;r] }[
    .text.map.get[`utf8;enc]
   ;$[err~`ignore ;{""}
       ;{'"invalid UTF-8 byte seq 0x",.text.hexstr"x"$x} ]
   ;];
  :.text.xcode.any[map;tok;x];
 };

//////////////////////////////////////////////////////////////////////////////
// Implementation details

/ Format a codepoint into an uppercase hex string.
.text.hexstr:{ "0123456789ABCDEF" raze 16 vs cp };

/ Cache of charmap data for loaded codepages.
/ @see .text.map.load
.text.CHARMAP  :enlist[`]!enlist[::];

/ Tokenizers that split a string into characters under a given codepage.
/<p>
/ Each tokenizer should follow interface <code>tokenize[str;idx]</code>, where
/ {@code idx} is the character index in {@code str} to start tokenization. It
/ should return the index of the next character in {@code str}.
.text.TOKENIZER:enlist[`]!enlist[::];

/ Obtain a character map between source and target encodings.
/<p>
/ @see .text.map.load
.text.map.get:{[src;tgt]
  enc:$[src~`utf8;tgt ;tgt~`utf8;src ;'"nyi: src or tgt should be `utf8" ];
  if[(::)~map:.text.CHARMAP enc; map:.text.CHARMAP[enc]:.text.map.load enc ];
  :(!). map(src;tgt);
 };

/ Load a character map between Unicode and a given encoding into cache.
/<p>
/ @see .text.CHARMAP
.text.map.load:{[enc]
  :?[.Q.dd[.text.BASEDIR;` sv enc,`charmap];();0b;]
    (`utf8;enc)!((`u#"c"$.text.toUTF8 peach;`Unicode);(`u#"c"$;upper enc))
 };

/ Tokenizer for GB18030 variable-length encoding.
.text.TOKENIZER.gb18030:{[str;idx]
  :idx+$["\200">str idx;1;"\100">str 1+idx;4;2];
 };

/ Tokenizer for UTF-8 variable-length encoding.
.text.TOKENIZER.utf8:{[str;idx]
  :idx+$["\200">c:str idx;1;"\340">c;2;"\360">c;3;"\370">c;4
     ;'"invalid UTF-8 byte seq: \\x",.text.hexstr"h"$c ];
 };

/ Transcode any q object with a character mapper and a character tokenizer.
.text.xcode.any:{[map;tok;x]
  :$[ 0h=t:type x ;.z.s[map;tok;] each x
   ; 10h=t  ;.text.xcode.str[map;tok;] x
   ;-11h=t  ;`$.text.xcode.str[map;tok;] string x
   ; 11h=t  ;.Q.fu[`$.text.xcode.str[map;tok;]peach string@;] x
   ; 99h=t  ;(key x)!.z.s[map;tok;] value x
   ; 98h=t  ;flip .z.s[map;tok;]peach flip x
   ;x ];
 };

/ Transcode a string with a character mapper and a character tokenizer.
.text.xcode.str:{[map;tok;str]
  :"",raze map (-1_tok[str;]\[count[str]>;0]) cut str;
 };

//////////////////////////////////////////////////////////////////////////////
\
__EOD__