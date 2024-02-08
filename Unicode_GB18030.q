BASEDIR:hsym`.;

//////////////////////////////////////////////////////////////////////////////

bytes_c2b:{ 0x0^"X"$(reverse') reverse 2 cut reverse 2_x };

bytes_cp:{ 0x0 sv neg[x]#(x#0x00),y };

ucs_utf8:{
  cp:0x0 sv -8#(7#0x00),x;
  u8:$[
    cp<128      /0x0080
     ;enlist last x
   ;cp<2048     /0x0800
     ;0b sv/:(110b;10b),'sums[5 5]cut raze 0b vs/:x
   ;cp<65536    /0x010000
     ;0b sv/:(1110b;10b;10b),'sums[0 4 6]cut raze 0b vs/:x
   ;cp<1114112  /0x110000
     ;0b sv/:(11110b;10b;10b;10b),'sums[3 3 6 6]cut raze 0b vs/:x
   /;default
     ;'"out of range: 0x",("0123456789ABCDEF"raze flip 16 vs x)
   ];
  :u8;
 };

//////////////////////////////////////////////////////////////////////////////

raw:("***";1#"\t")0:1_read0 .Q.dd[BASEDIR;`Unicode_GB18030.txt];

map:update UTF8:`u#(ucs_utf8')Unicode from
    select `u#(bytes_c2b')Unicode, (bytes_c2b')GB18030 from raw;

/`G_len xdesc update G_len:(count')GB18030 from map

/select (bytes_cp/:[8;])Unicode, (bytes_cp/:[8;])GB18030 from map where 0<(count')GB18030

/(.Q.dd[BASEDIR;`Unicode_GB18030.map];17;2;6) set map

(.Q.dd[BASEDIR;`gb18030.charmap];17;2;9) set
  select (bytes_cp/:[8;])Unicode, GB18030 from map where 0<(count')GB18030

//////////////////////////////////////////////////////////////////////////////
\
__EOD__
