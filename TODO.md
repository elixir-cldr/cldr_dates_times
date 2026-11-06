# TODO

Known defects in `ex_cldr_dates_times`. The library is in maintenance mode (see `STATUS.md`): defects users report are fixed and released, while defects found in review are recorded here and deferred, because development time goes to Localize. An item is revived when someone reports it.

## Deferred

* [ ] **Time zone names raise for zones CLDR does not know** — `v`, `vvvv`, `z`, `zzzz`, `V`, `VVV`, `VVVV`, `O`, `OOOO` and `ZZZZ` raise `MatchError` or `CaseClauseError` for a `DateTime` whose `time_zone` is missing from CLDR's zone data (such as `"Mars/Olympus"`), from `{:ok, _} =` matches and error-less `case` expressions in `Cldr.DateTime.Formatter`. Present since v2.25.0; found in review 2026-11-07, not reported.

* [ ] **`O` gives the long localised GMT format** — `O` returns `"GMT-04:00"`, the same as `OOOO`, where CLDR's short form is `"GMT-4"`, because `Cldr.DateTime.Timezone.gmt_format/2` deletes the `:format` option before formatting. Found in review 2026-11-07, not reported.

* [ ] **`V` gives the standard-time abbreviation all year** — `V` returns `"EST"` for New York in summer, because `specific_non_location/5` passes only the zone name, not the datetime; CLDR now defines `V` as the short time zone ID (`"usnyc"`). Found in review 2026-11-07, not reported.

* [ ] **README time zone rows are stale** — the format-symbol table says `vvvv` returns "unk", `VVV` is unsupported and several symbols delegate to `zone_gmt/4`, and "Known restrictions" says time zone names are not localised. Correct it together with the `O` and `V` items, since what it should say depends on them.
