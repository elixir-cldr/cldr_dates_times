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

Skeleton_j          = j
Skeleton_J          = J
Skeleton_C          = C

Rules.

{Era}+                   : {token,{era,symbol(TokenChars),count(TokenChars)}}.

{YearNumeric}+           : {token,{year,symbol(TokenChars),count(TokenChars)}}.
{YearWeek}+              : {token,{week_aligned_year,symbol(TokenChars),count(TokenChars)}}.
{YearExtended}+          : {token,{extended_year,symbol(TokenChars),count(TokenChars)}}.
{CyclicYear}+            : {token,{cyclic_year,symbol(TokenChars),count(TokenChars)}}.
{RelatedYear}+           : {token,{related_year,symbol(TokenChars),count(TokenChars)}}.

{Quarter}+               : {token,{quarter,symbol(TokenChars),count(TokenChars)}}.
{StandAloneQuarter}+     : {token,{standalone_quarter,symbol(TokenChars),count(TokenChars)}}.

{Month}+                 : {token,{month,symbol(TokenChars),count(TokenChars)}}.
{StandAloneMonth}+       : {token,{standalone_month,symbol(TokenChars),count(TokenChars)}}.

{WeekOfYear}+            : {token,{week_of_year,symbol(TokenChars),count(TokenChars)}}.
{WeekOfMonth}+           : {token,{week_of_month,symbol(TokenChars),count(TokenChars)}}.
{DayOfMonth}+            : {token,{day_of_month,symbol(TokenChars),count(TokenChars)}}.
{DayOfYear}+             : {token,{day_of_year,symbol(TokenChars),count(TokenChars)}}.
{DayOfWeekInMonth}+      : {token,{day_of_week_in_month,symbol(TokenChars),count(TokenChars)}}.

{WeekdayName}+           : {token,{day_name,symbol(TokenChars),count(TokenChars)}}.
{WeekdayNumber}+         : {token,{day_of_week,symbol(TokenChars),count(TokenChars)}}.
{StandAloneDayOfWeek}+   : {token,{standalone_day_of_week,symbol(TokenChars),count(TokenChars)}}.

{Period_am_pm}+          : {token,{period_am_pm,symbol(TokenChars),count(TokenChars)}}.
{Period_noon_mid}+       : {token,{period_noon_midnight,symbol(TokenChars),count(TokenChars)}}.
{Period_flex}+           : {token,{period_flex,symbol(TokenChars),count(TokenChars)}}.

{Hour_1_12}+             : {token,{h12,symbol(TokenChars),count(TokenChars)}}.
{Hour_0_11}+             : {token,{h11,symbol(TokenChars),count(TokenChars)}}.
{Hour_1_24}+             : {token,{h24,symbol(TokenChars),count(TokenChars)}}.
{Hour_0_23}+             : {token,{h23,symbol(TokenChars),count(TokenChars)}}.

{Minute}+                : {token,{minute,symbol(TokenChars),count(TokenChars)}}.
{Second}+                : {token,{second,symbol(TokenChars),count(TokenChars)}}.
{FractionalSecond}+      : {token,{fractional_second,symbol(TokenChars),count(TokenChars)}}.
{Millisecond}+           : {token,{millisecond,symbol(TokenChars),count(TokenChars)}}.

{ShortZone}+             : {token,{zone_short,symbol(TokenChars),count(TokenChars)}}.
{BasicZone}+             : {token,{zone_basic,symbol(TokenChars),count(TokenChars)}}.
{GMT_Zone}+              : {token,{zone_gmt,symbol(TokenChars),count(TokenChars)}}.
{GenericZone}+           : {token,{zone_generic,symbol(TokenChars),count(TokenChars)}}.
{ZoneID}+                : {token,{zone_id,symbol(TokenChars),count(TokenChars)}}.
{ISO_ZoneZ}+             : {token,{zone_iso_z,symbol(TokenChars),count(TokenChars)}}.
{ISO_Zone}+              : {token,{zone_iso,symbol(TokenChars),count(TokenChars)}}.

{Skeleton_j}+            : {token, {skeleton_j, symbol(TokenChars), count(TokenChars)}}.
{Skeleton_J}+            : {token, {skeleton_J, symbol(TokenChars), count(TokenChars)}}.
{Skeleton_C}+            : {token, {skeleton_C, symbol(TokenChars), count(TokenChars)}}.

% These will never match. But without them, Dialyzer will report
% a pattern_match error
{Time}                   : {token,{time,symbol(TokenChars),0}}.
{Date}                   : {token,{date,symbol(TokenChars),0}}.

Erlang code.

count(Chars) -> string:len(Chars).

symbol(Chars) -> list_to_binary([hd(Chars)]).

