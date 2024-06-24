% Tokenizes CLDR date and time formats which are described at
% http://unicode.org/reports/tr35/tr35-dates.html

Definitions.

Era                 = G

YearNumeric         = y
YearWeek            = Y
YearExtended        = u
CyclicYear          = U
RelatedYear         = r

Quarter             = q
StandAloneQuarter   = Q

Month               = M
StandAloneMonth     = L

WeekOfYear          = w
WeekOfMonth         = W

DayOfMonth          = d
DayOfYear           = D
DayOfWeekInMonth    = F

WeekdayName         = E
WeekdayNumber       = e
StandAloneDayOfWeek = c

Period_am_pm        = a
Period_noon_mid     = b
Period_flex         = B

Hour_0_11           = K
Hour_1_12           = h
Hour_0_23           = H
Hour_1_24           = k

Minute              = m

Second              = s
FractionalSecond    = S
Millisecond         = A

ShortZone           = z
BasicZone           = Z
GMT_Zone            = O
GenericZone         = v
ZoneID              = V
ISO_ZoneZ           = X
ISO_Zone            = x

Skeleton_a          = a
Skeleton_b          = b
Skeleton_B          = B

Rules.

{Era}+                   : {token, {symbol(TokenChars), count(TokenChars)}}.

{YearNumeric}+           : {token, {symbol(TokenChars), count(TokenChars)}}.
{YearWeek}+              : {token, {symbol(TokenChars), count(TokenChars)}}.
{YearExtended}+          : {token, {symbol(TokenChars), count(TokenChars)}}.
{CyclicYear}+            : {token, {symbol(TokenChars), count(TokenChars)}}.
{RelatedYear}+           : {token, {symbol(TokenChars), count(TokenChars)}}.

{Quarter}+               : {token, {symbol(TokenChars), count(TokenChars)}}.
{StandAloneQuarter}+     : {token, {symbol(TokenChars), count(TokenChars)}}.

{Month}+                 : {token, {symbol(TokenChars), count(TokenChars)}}.
{StandAloneMonth}+       : {token, {symbol(TokenChars), count(TokenChars)}}.

{WeekOfYear}+            : {token, {symbol(TokenChars), count(TokenChars)}}.
{WeekOfMonth}+           : {token, {symbol(TokenChars), count(TokenChars)}}.
{DayOfMonth}+            : {token, {symbol(TokenChars), count(TokenChars)}}.
{DayOfYear}+             : {token, {symbol(TokenChars), count(TokenChars)}}.
{DayOfWeekInMonth}+      : {token, {symbol(TokenChars), count(TokenChars)}}.

{WeekdayName}+           : {token, {symbol(TokenChars), count(TokenChars)}}.
{WeekdayNumber}+         : {token, {symbol(TokenChars), count(TokenChars)}}.
{StandAloneDayOfWeek}+   : {token, {symbol(TokenChars), count(TokenChars)}}.

{Period_am_pm}+          : {token, {symbol(TokenChars), count(TokenChars)}}.
{Period_noon_mid}+       : {token, {symbol(TokenChars), count(TokenChars)}}.
{Period_flex}+           : {token, {symbol(TokenChars), count(TokenChars)}}.

{Hour_1_12}+             : {token, {symbol(TokenChars), count(TokenChars)}}.
{Hour_0_11}+             : {token, {symbol(TokenChars), count(TokenChars)}}.
{Hour_1_24}+             : {token, {symbol(TokenChars), count(TokenChars)}}.
{Hour_0_23}+             : {token, {symbol(TokenChars), count(TokenChars)}}.

{Minute}+                : {token, {symbol(TokenChars), count(TokenChars)}}.
{Second}+                : {token, {symbol(TokenChars), count(TokenChars)}}.
{FractionalSecond}+      : {token, {symbol(TokenChars), count(TokenChars)}}.
{Millisecond}+           : {token, {symbol(TokenChars), count(TokenChars)}}.

{ShortZone}+             : {token, {symbol(TokenChars), count(TokenChars)}}.
{BasicZone}+             : {token, {symbol(TokenChars), count(TokenChars)}}.
{GMT_Zone}+              : {token, {symbol(TokenChars), count(TokenChars)}}.
{GenericZone}+           : {token, {symbol(TokenChars), count(TokenChars)}}.
{ZoneID}+                : {token, {symbol(TokenChars), count(TokenChars)}}.
{ISO_ZoneZ}+             : {token, {symbol(TokenChars), count(TokenChars)}}.
{ISO_Zone}+              : {token, {symbol(TokenChars), count(TokenChars)}}.

{Skeleton_a}+            : {token, {symbol(TokenChars), count(TokenChars)}}.
{Skeleton_b}+            : {token, {symbol(TokenChars), count(TokenChars)}}.
{Skeleton_B}+            : {token, {symbol(TokenChars), count(TokenChars)}}.

Erlang code.

-import('Elixir.List', [to_string/1]).

count(Chars) -> string:len(Chars).

symbol(Chars) -> to_string([hd(Chars)]).

