# Changelog

## Cldr_Dates_Times v0.3.0 Octoebr 25th, 2017

### Enhancements

* Update to `ex_cldr` version 0.8.1

* Reflect that `Cldr.territory_from_locale/1` is now `Cldr.region_from_locale/1`

## Cldr_Dates_Times v0.1.1 September 18th, 2017

### Enhancements

* Updated to `ex_cldr` version 0.7.0 and add new package `ex_cldr_numbers` which has now been extracted into its own package.

## Cldr_Dates_Times v0.1.0 September 4th, 2017

### Enhancements

* Initial release

### Known limitations

Although largely complete (with respect to the CLDR data), there are some known limitations as of release 0.1.0.  These limitations will be removed before version 1.0.

* *Week of year*  The week of year is returned for the format symbol `w`.  Currently it considers weeks of the year to be those defined for the `ISOWeek` calendar.  This means that January 1st may not be the start of the first week of the year and December 31st may not be the last day of the last week of the year.

* *Week of month*  The week of the mornth is returned for format symbole `W`.  Currently it considers weeks of the month to start on the first day of the month which is inconsistent with the ISOWeek standard and different from the `week_of_year` calculation.

* *Timezones*  Although the timezone format codes are supported (formatting symbols `v`, `V`, `x`, `X`, `z`, `Z`, `O`) not all localisations are performed.  Only that data available within a `DateTime` struct is use to format timezone data.

* *First day of week is always Monday*  All formatting is done with Monday as the first day of the week.  In several territories this is not a reasonable assumption.  CLDR provides data to support a different starting day for the week.  This will be implemented before version 1.0

* *Only calendar is Gregorian (Calendar.ISO)* CLDR defines many calendar systems (see `Cldr.Calendar.known_calendars/0`) however only Calendar.ISO (proleptic Gregorian calendar) is supported in this release.

* *Variants*  Some formats defines variants in the CLDR data.  For example, formatting an Era in the gregorian calendar is, by default, returned as `AD` or `BC`.  CLDR also defines the variants `CE` and `BCE`.  Currently the API does not provide a way to specify these variants.