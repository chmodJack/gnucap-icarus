
%option never-interactive
%option nounput

%{
/*
 * Copyright (c) 2001-2008 Stephen Williams (steve@icarus.com)
 *
 *    This source code is free software; you can redistribute it
 *    and/or modify it in source code form under the terms of the GNU
 *    General Public License as published by the Free Software
 *    Foundation; either version 2 of the License, or (at your option)
 *    any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

# include  "parse_misc.h"
# include  "compile.h"
# include  "parse.h"
# include  <string.h>
# include  <assert.h>
%}

%%

  /* These are some special header/footer keywords. */
^":ivl_version" { return K_ivl_version; }
^":vpi_module" { return K_vpi_module; }
^":vpi_time_precision" { return K_vpi_time_precision; }
^":file_names" { return K_file_names; }


  /* A label is any non-blank text that appears left justified. */
^[.$_a-zA-Z\\][.$_a-zA-Z\\0-9<>/]* {
      yylval.text = strdup(yytext);
      assert(yylval.text);
      return T_LABEL; }

  /* String tokens are parsed here. Return as the token value the
     contents of the string without the enclosing quotes. */
\"([^\"\\]|\\.)*\" {
      yytext[strlen(yytext)-1] = 0;
      yylval.text = strdup(yytext+1);
      assert(yylval.text);
      return T_STRING; }

  /* Binary vector tokens are parsed here. The result of this is a
     string of binary 4-values in the yylval.vect.text string. This is
     preceded by an 's' if the vector is signed. */
[1-9][0-9]*("'b"|"'sb")[01xz]+ {
      yylval.vect.idx = strtoul(yytext, 0, 10);
      yylval.vect.text = (char*)malloc(yylval.vect.idx + 2);
      assert(yylval.vect.text);
      char*dest = yylval.vect.text;

      const char*bits = strchr(yytext, '\'');
      assert(bits);
      bits += 1;

      if (*bits == 's') {
	    *dest++ = 's';
	    bits += 1;
      }

      assert(*bits == 'b');
      bits += 1;
      unsigned pad = 0;
      if (strlen(bits) < yylval.vect.idx)
	    pad = yylval.vect.idx - strlen(bits);

      memset(dest, '0', pad);
      for (unsigned idx = pad ;  idx < yylval.vect.idx ;  idx += 1)
	    dest[idx] = bits[idx-pad];

      dest[yylval.vect.idx] = 0;
      return T_VECTOR; }


  /* These are some keywords that are recognized. */
".alias"      { return K_ALIAS; }
".alias/real" { return K_ALIAS_R; }
".alias/s"    { return K_ALIAS_S; }
".abs"          { return K_ARITH_ABS; }
".arith/div"    { return K_ARITH_DIV; }
".arith/div.r"  { return K_ARITH_DIV_R; }
".arith/div.s"  { return K_ARITH_DIV_S; }
".arith/mod"  { return K_ARITH_MOD; }
".arith/mod.r"  { return K_ARITH_MOD_R; }
".arith/mod.s"  { return K_ARITH_MOD_S; }
".arith/mult" { return K_ARITH_MULT; }
".arith/mult.r" { return K_ARITH_MULT_R; }
".arith/pow" { return K_ARITH_POW; }
".arith/pow.r" { return K_ARITH_POW_R; }
".arith/pow.s" { return K_ARITH_POW_S; }
".arith/sub"  { return K_ARITH_SUB; }
".arith/sub.r" { return K_ARITH_SUB_R; }
".arith/sum"  { return K_ARITH_SUM; }
".arith/sum.r"  { return K_ARITH_SUM_R; }
".array" { return K_ARRAY; }
".array/i" { return K_ARRAY_I; }
".array/real" { return K_ARRAY_R; }
".array/s" { return K_ARRAY_S; }
".array/port" { return K_ARRAY_PORT; }
".cast/int" { return K_CAST_INT; }
".cast/real" { return K_CAST_REAL; }
".cast/real.s" { return K_CAST_REAL_S; }
".cmp/eeq"  { return K_CMP_EEQ; }
".cmp/eq"   { return K_CMP_EQ; }
".cmp/eq.r" { return K_CMP_EQ_R; }
".cmp/nee"  { return K_CMP_NEE; }
".cmp/ne"   { return K_CMP_NE; }
".cmp/ne.r" { return K_CMP_NE_R; }
".cmp/ge"   { return K_CMP_GE; }
".cmp/ge.r" { return K_CMP_GE_R; }
".cmp/ge.s" { return K_CMP_GE_S; }
".cmp/gt"   { return K_CMP_GT; }
".cmp/gt.r" { return K_CMP_GT_R; }
".cmp/gt.s" { return K_CMP_GT_S; }
".concat"   { return K_CONCAT; }
".delay"    { return K_DELAY; }
".dff"      { return K_DFF; }
".event"    { return K_EVENT; }
".event/or" { return K_EVENT_OR; }
".export"   { return K_EXPORT; }
".extend/s" { return K_EXTEND_S; }
".functor"  { return K_FUNCTOR; }
".import"   { return K_IMPORT; }
".island"   { return K_ISLAND; }
".modpath" { return K_MODPATH; }
".net"      { return K_NET; }
".net8"     { return K_NET8; }
".net8/s"   { return K_NET8_S; }
".net/real" { return K_NET_R; }
".net/s"    { return K_NET_S; }
".param/l"  { return K_PARAM_L; }
".param/str" { return K_PARAM_STR; }
".param/real" { return K_PARAM_REAL; }
".part"     { return K_PART; }
".part/pv"  { return K_PART_PV; }
".part/v"   { return K_PART_V; }
".port"     { return K_PORT; }
".reduce/and" { return K_REDUCE_AND; }
".reduce/or"  { return K_REDUCE_OR; }
".reduce/xor" { return K_REDUCE_XOR; }
".reduce/nand" { return K_REDUCE_NAND; }
".reduce/nor"  { return K_REDUCE_NOR; }
".reduce/xnor" { return K_REDUCE_XNOR; }
".repeat"   { return K_REPEAT; }
".resolv"   { return K_RESOLV; }
".scope"    { return K_SCOPE; }
".sfunc"    { return K_SFUNC; }
".shift/l"  { return K_SHIFTL; }
".shift/r"  { return K_SHIFTR; }
".shift/rs" { return K_SHIFTRS; }
".thread"   { return K_THREAD; }
".timescale" { return K_TIMESCALE; }
".tran"     { return K_TRAN; }
".tranif0"  { return K_TRANIF0; }
".tranif1"  { return K_TRANIF1; }
".tranvp"   { return K_TRANVP; }
".ufunc"    { return K_UFUNC; }
".var"      { return K_VAR; }
".var/real" { return K_VAR_R; }
".var/s"    { return K_VAR_S; }
".var/i"    { return K_VAR_I; /* integer */ }
".udp"         { return K_UDP; }
".udp/c"(omb)? { return K_UDP_C; }
".udp/s"(equ)? { return K_UDP_S; }
"-debug" { return K_DEBUG; }

  /* instructions start with a % character. The compiler decides what
     kind of instruction this really is. The few exceptions (that have
     exceptional parameter requirements) are listed first. */

"%vpi_call" { return K_vpi_call; }
"%vpi_func" { return K_vpi_func; }
"%vpi_func/r" { return K_vpi_func_r; }
"%disable"  { return K_disable; }
"%fork"     { return K_fork; }

  /* Handle the specialized variable access functions. */

"&A" { return K_A; }
"&PV" { return K_PV; }

"%"[.$_/a-zA-Z0-9]+ {
      yylval.text = strdup(yytext);
      assert(yylval.text);
      return T_INSTR; }

[0-9][0-9]* {
      yylval.numb = strtoul(yytext, 0, 0);
      return T_NUMBER; }

"0x"[0-9a-fA-F]+ {
      yylval.numb = strtoul(yytext, 0, 0);
      return T_NUMBER; }

  /* Handle some specialized constant/literals as symbols. */

"C4<"[01xz]*">" {
      yylval.text = strdup(yytext);
      assert(yylval.text);
      return T_SYMBOL; }

"C8<"[01234567xz]*">" {
      yylval.text = strdup(yytext);
      assert(yylval.text);
      return T_SYMBOL; }

"Cr<m"[a-f0-9]*"g"[a-f0-9]*">" {
      yylval.text = strdup(yytext);
      assert(yylval.text);
      return T_SYMBOL; }

"T<"[0-9]*","[0-9]*","[us]">" {
      yylval.text = strdup(yytext);
      assert(yylval.text);
      return T_SYMBOL; }

"W<"[0-9]*","[r]">" {
      yylval.text = strdup(yytext);
      assert(yylval.text);
      return T_SYMBOL; }

  /* Symbols are pretty much what is left. They are used to refer to
     labels so the rule must match a string that a label would match. */
[.$_a-zA-Z\\]([.$_a-zA-Z\\0-9/]|(\\.))* {
      yylval.text = strdup(yytext);
      assert(yylval.text);
      return T_SYMBOL; }


  /* Accept the common assembler style comments, treat them as white
     space. Of course, also skip white space. The semi-colon is
     special, though, in that it is also a statement terminator. */
";".* { return ';'; }
"#".* { ; }

[ \t\b\r] { ; }

\n { yyline += 1; }

. { return yytext[0]; }

%%

int yywrap()
{
      return -1;
}