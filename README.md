# Elixir Cldr: Dates, Times & DateTimes
![Build Status](http://sweatbox.noexpectations.com.au:8080/buildStatus/icon?job=cldr_dates_times)
![Deps Status](https://beta.hexfaktor.org/badge/all/github/kipcole9/cldr_dates_times.svg)
[![Hex pm](http://img.shields.io/hexpm/v/ex_cldr_dates_times.svg?style=flat)](https://hex.pm/packages/ex_cldr_dates_times)
[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://github.com/kipcole9/cldr_dates_times/blob/master/LICENSE)


## Introduction & Getting Started

`ex_cldr_dates_times` is an addon library for [ex_cldr](https://hex.pm/packages/ex_cldr) that provides localisation and formatting for dates, times and date_times.

The primary api is `Cldr.Date.to_string/2`, `Cldr.Time.to_string/2` and `Cldr.DateTime.to_string/2`.  The following examples demonstrate:

```elixir
iex> Cldr.Date.to_string Date.utc_today()
{:ok, "Aug 18, 2017"}

iex> Cldr.Time.to_string Time.utc_now
{:ok, "11:38:55 AM"}

iex> Cldr.DateTime.to_string DateTime.utc_now
{:ok, "Aug 18, 2017, 11:39:08 AM"}
```

For help in `iex`:

```elixir
iex> h Cldr.Date.to_string
iex> h Cldr.Time.to_string
iex> h Cldr.DateTime.to_string
```
## Documentation

Primary documentation is available at https://hexdocs.pm/ex_cldr/1_getting_started.html#localizing-dates-datetimes

## Installation

Note that `:ex_cldr_dates_times` requires Elixir 1.5 or later.

Add `ex_cldr_dates_time` as a dependency to your `mix` project:

    defp deps do
      [
        {:ex_cldr_dates_times, "~> 0.1.0"}
      ]
    end

then retrieve `ex_cldr_dates_times` from [hex](https://hex.pm/packages/ex_cldr_dates_times):

    mix deps.get
    mix deps.compile


