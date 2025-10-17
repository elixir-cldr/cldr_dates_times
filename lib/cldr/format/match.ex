defmodule Cldr.DateTime.Format.Match do
  @moduledoc """
  Implements best match for a requested skeleton to an available format ID.

  A “best match” from requested skeleton to the id portion of a `Cldr.DateTime.date_time_available_formats/3`
  map is found using a closest distance match as follows:

  ### Matching process

  * Skeleton symbols requesting a best choice for the locale are replaced. This allows a
    user to specify a desired hour cycle in the locale using the `-u-hc` option and to use the `j`
    and `C` fields in the skeleton itself. For example:

    j → one of {H, k, h, K};
    C → one of {a, b, B}

  * For skeleton and id fields with symbols representing the same type (year, month, day, etc),
    calculate a distance from the desired field to the available field:

    * Most symbols have a small distance from each other. For example:

      M ≅ L; E ≅ c; a ≅ b ≅ B; H ≅ k ≅ h ≅ K; ...

    * Width differences among fields, other than those marking text vs numeric, are given small
      distance from each other. For example:

      MMM ≅ MMMM
      MM ≅ M

    * Numeric and text fields are given a larger distance from each other. For example:

      MMM ≈ MM

    * Symbols representing substantial differences (week of year vs week of month) are
      given a much larger distance from each other.

  * [Stated in the spec, not currently implemented] A requested skeleton that includes both
    seconds and fractional seconds (e.g. “mmssSSS”)  is allowed to match a dateFormatItem
    skeleton that includes seconds but not fractional seconds (e.g. “ms”). In this case the
    requested sequence of ‘S’ characters (or its length)  should be retained separately and
    used when adjusting the pattern.

  * Otherwise, missing or extra fields between requested skeleton and id cause a match to fail. In
    those cases, an attempt is made to separate the skeleton into separate time skeletons and date
    skeletons and an attempt is made to best match each of them independently.

  * See [the specification](https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons)
    for further information.

  ### Deviations from the specification

  Some additional steps post matching are described in the specification that are not currently
  implemented in this library. The relevant sections are reproduced here:

  Once a best match is found between requested skeleton and dateFormatItem id, the
  corresponding dateFormatItem pattern is used, but with adjustments primarily to make
  the pattern field lengths match the skeleton field lengths. However, the pattern field
  lengths should not be matched in some cases:

  * When the best-match dateFormatItem has an alphabetic field (such as MMM or MMMM) that
    corresponds to a numeric field in the pattern (such as M or MM), that numeric field in
    the pattern should not be adjusted to match the skeleton length, and vice versa; i.e.
    adjustments should never convert a numeric element in the pattern to an alphabetic element,
    or the opposite. See the second set of examples below.

  * When the pattern field corresponds to an availableFormats skeleton with a field length
    that matches the field length in the requested skeleton, the pattern field length should
    not be adjusted.

  * Pattern field lengths for hour, minute, and second should by default not be adjusted to
    match the requested field length (i.e. locale data takes priority). However APIs that
    map skeletons to patterns should provide the option to override this behavior for cases
    when a client really does want to force a specific pattern field length.

  """
  alias Cldr.DateTime.Format.Compiler
  alias Cldr.DateTime.Format
  alias Cldr.LanguageTag

  @locale_preferred_time_symbol %{
    h11: "K",
    h12: "h",
    h23: "H",
    h24: "k"
  }

  @hour_cycles Map.keys(@locale_preferred_time_symbol)
  @prefer_cycle_24 ["H", "k"]
  @prefer_cycle_12 ["h", "K"]

  @doc """
  Find the best match format ID for a requested skeleton.

  ### Arguments

  * `skeleton` is a string or atom composed of format fields.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `t:Cldr.LanguageTag.t/0` struct. The default is `Cldr.get_locale/0`.
    The default is `Cldr.get_locale/0`.
  * `calendar` is any CLDR calendar type. The default is `:gregorian`.
    See `Cldr.DateTime.Format.calendars_for/1` for the available calendars.

  ### Returns

  * `{:ok, format_id} or

  * `{:ok, {date_format_id, time_format_id}}`

  * `{:error, reason}`.

  ### Examples

      iex> Cldr.DateTime.Format.Match.best_match("hms", "en", :gregorian, MyApp.Cldr)
      {:ok, :hms}

      iex> Cldr.DateTime.Format.Match.best_match("yMdhms", "en", :gregorian, MyApp.Cldr)
      {:ok, {:yMd, :hms}}

      iex> Cldr.DateTime.Format.Match.best_match("EMdyv", "en", :gregorian, MyApp.Cldr)
      {:error,
       {Cldr.DateTime.UnresolvedFormat, "No available format resolved for \\"EMdyv\\""}}

  """

  # Date/Time format symbols are defined at
  # https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table

  @doc since: "2.19.0"
  @spec best_match(
          skeleton :: Format.format_skeleton(),
          locale :: Locale.locale_reference(),
          calendar :: Cldr.Calendar.calendar(),
          backend :: Cldr.backend()
        ) :: {:ok, Format.format_id()} | {:error, {module(), String.t()}}

  def best_match(
        original_skeleton,
        locale \\ Cldr.get_locale(),
        calendar \\ Cldr.Calendar.default_cldr_calendar(),
        backend \\ Cldr.Date.default_backend()
      ) do
    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         skeleton = to_string(original_skeleton),
         {:ok, skeleton} <- put_preferred_time_symbols(skeleton, locale),
         {:ok, skeleton_tokens} <- Compiler.tokenize_skeleton(skeleton) do
      available_format_tokens =
        Format.date_time_available_format_tokens(locale, calendar, backend)

      skeleton_ordered =
        sort_tokens(skeleton_tokens)

      skeleton_keys =
        skeleton_ordered
        |> :proplists.get_keys()
        |> canonical_keys()

      candidates =
        available_format_tokens
        |> Enum.filter(&candidates_with_the_same_tokens(&1, skeleton_keys))
        |> Enum.map(&distance_from(&1, skeleton_ordered))
        |> Enum.sort(&compare_counts/2)
        # |> IO.inspect(label: "Candidates")

      case candidates do
        [] ->
          try_date_and_time_skeletons(skeleton, original_skeleton, locale, calendar, backend)

        [{format_id, _} | _rest] ->
          {:ok, format_id}
      end
    end
    # |> IO.inspect(label: "Matched to #{inspect original_skeleton}")
  end

  defp try_date_and_time_skeletons(skeleton, original, locale, calendar, backend) do
    with {date_skeleton, time_skeleton} <- separate_date_and_time_fields(skeleton),
         {:ok, date_format} <- best_match(date_skeleton, locale, calendar, backend),
         {:ok, time_format} <- best_match(time_skeleton, locale, calendar, backend) do
      {:ok, {date_format, time_format}}
    else
      _other ->
        {:error, no_format_resolved_error(original)}
    end
  end

  defp separate_date_and_time_fields(skeleton) do
    {date_fields, time_fields} =
      skeleton
      |> String.graphemes()
      |> Enum.reduce({[], []}, fn char, {date_fields, time_fields} ->
        date_fields = if char in Format.date_fields(), do: [char | date_fields], else: date_fields
        time_fields = if char in Format.time_fields(), do: [char | time_fields], else: time_fields
        {date_fields, time_fields}
      end)

    if length(date_fields) > 0 and length(time_fields) > 0 do
      {List.to_string(date_fields), List.to_string(time_fields)}
    else
      nil
    end
  end

  @doc false
  def no_format_resolved_error(skeleton) do
    {
      Cldr.DateTime.UnresolvedFormat,
      "No available format resolved for #{inspect(skeleton)}"
    }
  end

  defp candidates_with_the_same_tokens({_format_id, tokens}, skeleton_keys)
       when length(tokens) == length(skeleton_keys) do
    token_keys =
      tokens
      |> :proplists.get_keys()
      |> canonical_keys()

    token_keys == skeleton_keys
  end

  defp candidates_with_the_same_tokens(_format_tokens, _skeleton_keys) do
    false
  end

  # Sort the tokesn in canonical order, using
  # the substitution table.
  @doc false
  def sort_tokens(tokens) do
    Enum.sort(tokens, fn {symbol_a, _}, {symbol_b, _} ->
      canonical_key(symbol_a) < canonical_key(symbol_b)
    end)
  end

  defp compare_counts({_, count_a}, {_, count_b}) do
    count_a < count_b
  end

  # These are all considered matchable since they are
  # similar. But they will have different distance weights
  # when sorting to find the best match.

  @time_zone ["x", "X", "v", "V", "z", "Z", "O"]
  @hour ["k", "h", "K", "H"]
  @day_period ["a", "b", "B"]
  @month ["L", "M"]
  @day_of_week ["c", "E"]

  defp canonical_keys(keys) do
    keys
    |> Enum.map(&canonical_key/1)
    |> Enum.sort()
  end

  defp canonical_key(key) do
    case key do
      s when s in @month -> "M"
      s when s in @day_of_week -> "E"
      s when s in @day_period -> "a"
      s when s in @hour -> "H"
      s when s in @time_zone -> "v"
      other -> other
    end
  end

  # When comparing distances we want the smallest difference in each
  # token as long as we don't allow numeric symbols (like M and MM) to
  # become alpha tokens (like MMM and MMMM).

  # Note the guarantees at this point:
  # 1. The token list and the skeleton list are the same length
  # 2. The two lists are in the same semantic order. They may not
  #    have the same symbol - but both symbols are considered
  #    substitutable for each other.

  defguard different_but_compatible(token_a, token_b)
           when (elem(token_a, 0) in @month and elem(token_b, 0) in @month) or
                  (elem(token_a, 0) in @day_of_week and elem(token_b, 0) in @day_of_week) or
                  (elem(token_a, 0) in @day_period and elem(token_b, 0) in @day_period) or
                  (elem(token_a, 0) in @hour and elem(token_b, 0) in @hour) or
                  (elem(token_a, 0) in @time_zone and elem(token_b, 0) in @time_zone)

  defguard same_types(token_a, token_b)
           when (elem(token_a, 1) in [1, 2] and elem(token_b, 1) in [1, 2]) or
                  (elem(token_a, 1) > 2 and elem(token_b, 1) > 2)

  defguard different_types(token_a, token_b)
           when (elem(token_a, 1) in [1, 2] and elem(token_b, 1) > 2) or
                  (elem(token_a, 1) > 2 and elem(token_b, 1) in [1, 2])

  defp distance_from({token_id, tokens}, skeleton) do
    distance =
      Enum.zip_reduce(tokens, skeleton, 0, fn
        # Same symbol, both numeric forms so the distance is
        # just the different in their counts
        {symbol_a, count_a}, {symbol_a, count_b}, acc
        when same_types({symbol_a, count_a}, {symbol_a, count_b}) ->
          acc + abs(count_a - count_b)

        # Same symbol, but one is numeric form, the other
        # is alpha form. Assgn a difference of 5.
        {symbol_a, count_a}, {symbol_a, count_b}, acc
        when different_types({symbol_a, count_a}, {symbol_a, count_b}) ->
          acc + 10

        # Different but compatible symbols, both of numeric
        # form.
        {symbol_a, count_a}, {symbol_b, count_b}, acc
        when different_but_compatible({symbol_a, count_a}, {symbol_b, count_b}) and
               same_types({symbol_a, count_a}, {symbol_b, count_b}) ->
          acc + abs(count_a - count_b) + 5

        # Different but compatible symbols, one numeric
        # and one alphabetic form.
        {symbol_a, count_a}, {symbol_b, count_b}, acc
        when different_but_compatible({symbol_a, count_a}, {symbol_b, count_b}) and
               different_types({symbol_a, count_a}, {symbol_b, count_b}) ->
          acc + abs(count_a - count_b) + 10

        _other_a, _other_b, acc ->
          acc + 15
      end)

    {token_id, distance}
  end

  # The time preferences are defined in
  # https://www.unicode.org/reports/tr35/tr35-dates.html#Time_Data

  defp put_preferred_time_symbols(skeleton, locale) do
    if locale_specifies_hour_cycle?(locale) || String.contains?(skeleton, ["j", "J", "C"]) do
      preferred_time_symbol = preferred_time_symbol(locale)
      allowed_time_symbol = hd(allowed_time_symbols(locale))

      new_skeleton =
        skeleton
        |> replace_time_symbols(preferred_time_symbol, allowed_time_symbol)

      {:ok, new_skeleton}
    else
      {:ok, skeleton}
    end
  end

  @doc false
  def locale_specifies_hour_cycle?(%{locale: %{hc: _}}), do: true
  def locale_specifies_hour_cycle?(_locale), do: false

  @doc false
  def time_skeleton?(skeleton) do
    skeleton
    |> String.graphemes()
    |> Enum.all?(&(&1 in Format.time_fields()))
  end

  defp replace_time_symbols("", _preferred, _allowed) do
    ""
  end

  # Requests the preferred hour format for the locale (h, H, K, or k), as determined by
  # the preferred attribute of the hours.
  defp replace_time_symbols(<<"j", rest::binary>>, preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  # Requests the preferred hour format for the locale (h, H, K, or k), as determined by the
  # preferred attribute of the hours element in supplemental data. However, unlike 'j', it
  # requests no dayPeriod marker such as “am/pm” (it is typically used where there is enough
  # context that that is not necessary). For example, with "jmm", 18:00 could appear as
  # “6:00 PM”, while with "Jmm", it would appear as “6:00” (no PM).
  # TODO Does not signal that a day period format code is not required. Therefore is the same
  # as "j".
  defp replace_time_symbols(<<"J", rest::binary>>, preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  # Requests the preferred hour format for the locale. However, unlike 'j', it can also select
  # formats such as hb or hB, since it is based not on the preferred attribute of the hours element
  # in supplemental data, but instead on the first element of the allowed attribute (which is an
  # ordered preferrence list). For example, with "Cmm", 18:00 could appear as “6:00 in the
  # afternoon”.
  defp replace_time_symbols(<<"C", rest::binary>>, preferred, allowed) do
    allowed <> replace_time_symbols(rest, preferred, allowed)
  end

  # Remove "a", "b" and "B" if we want 24 hour (H and k)
  defp replace_time_symbols(<<format_code::binary-1, rest::binary>>, preferred, allowed)
       when format_code in ["a", "b", "B"] and preferred in @prefer_cycle_24 do
    replace_time_symbols(rest, preferred, allowed)
  end

  # Assert the correct symbol respecting the preference: 24 hour
  defp replace_time_symbols(<<"h", rest::binary>>, "H" = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<"K", rest::binary>>, "H" = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<"h", rest::binary>>, "k" = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<"K", rest::binary>>, "k" = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  # Assert the correct symbol respecting the preference: 12 hour
  defp replace_time_symbols(<<"H", rest::binary>>, <<"h", _other::binary>> = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<"k", rest::binary>>, <<"h", _other::binary>> = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<"H", rest::binary>>, <<"K", _other::binary>> = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<"k", rest::binary>>, <<"K", _other::binary>> = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  # Just pass it through
  defp replace_time_symbols(<<format_code::binary-1, rest::binary>>, preferred, allowed) do
    format_code <> replace_time_symbols(rest, preferred, allowed)
  end

  # Locale's time preference takes priority
  defp preferred_time_symbol(%LanguageTag{locale: %{hc: hc}}) when hc in @hour_cycles do
    Map.fetch!(@locale_preferred_time_symbol, hc)
  end

  # Prefer 12-hour cycle
  defp preferred_time_symbol(%LanguageTag{locale: %{hc: :c12}} = locale) do
    case time_preferences(locale) do
      %{preferred: preferred, allowed: allowed} when preferred in @prefer_cycle_24 ->
        find_allowed(allowed, @prefer_cycle_12)

      %{preferred: preferred} ->
        preferred
    end
  end

  # Prefer 24-hour cycle
  defp preferred_time_symbol(%LanguageTag{locale: %{hc: :c24}} = locale) do
    case time_preferences(locale) do
      %{preferred: preferred, allowed: allowed} when preferred in @prefer_cycle_12 ->
        find_allowed(allowed, @prefer_cycle_24)

      %{preferred: preferred} ->
        preferred
    end
  end

  defp preferred_time_symbol(%LanguageTag{} = locale) do
    time_preferences(locale).preferred
  end

  @doc false
  defp allowed_time_symbols(locale) do
    time_preferences(locale).allowed
  end

  # Find the first member of the allowed format list that has
  # the requested format code.
  defp find_allowed(allowed, requested) do
    Enum.find(allowed, &String.contains?(&1, requested))
  end

  # We have a format string and we have the tokens of the *original*
  # skeleton we asked for. The resolved skeleton (and therefore format)
  # may have different field lenghts. ie we asked for MMMM and we got a
  # format that has MMM. This function is the process to resize some fields
  # back to the original requested suze.
  @doc false
  def adjust_field_lengths(format, skeleton_tokens) when is_map(format) do
    revised_formats =
      Enum.map(format, fn
        {style, format_string} when is_binary(format_string) ->
          {:ok, adjusted_format_string} = adjust_field_lengths(format_string, skeleton_tokens)
          {style, adjusted_format_string}

        other ->
          other
      end)
      |> Map.new()

    {:ok, revised_formats}
  end

  def adjust_field_lengths(format, skeleton_tokens) do
    format_tokens = Cldr.DateTime.Format.Compiler.tokenize_format_string(format)

    revised_format =
      Enum.reduce(format_tokens, [], &adjust_field_length(&1, &2, skeleton_tokens))
      |> Enum.reverse()
      |> List.flatten()
      |> List.to_string()

    {:ok, revised_format}
  end

  @doc false
  def tokens_to_string(tokens) do
    Enum.map(tokens, fn {token, count} ->
      String.duplicate(token, count)
    end)
    |> Enum.join()
  end

  @doc false
  # Month, quarter and day of week need special handling so as to not
  # transition from nummber to alphabetic lengths. Ie if the format
  # is "M", its ok to go to "MM", but not to "MMM" or "MMMM".
  @numeric_and_alpha_fields ["M", "L", "e", "q", "Q"]
  def adjust_field_length([char | _rest] = field, acc, skeleton_tokens)
      when char in @numeric_and_alpha_fields do
    requested_length = :proplists.get_value(char, skeleton_tokens)
    field_length = length(field)

    cond do
      field_length == requested_length ->
        [field | acc]

      field_length in [1, 2] and requested_length in [1, 2] ->
        [List.duplicate(char, requested_length) | acc]

      field_length > 2 and requested_length > 2 ->
        [List.duplicate(char, requested_length) | acc]

      true ->
        [field | acc]
    end
  end

  # Substitute back the originally requested zone field and length
  # TODO doing this needs further validation, the spec isn't super clear
  @substitutable_zone_fields ["v", "V", "O", "z", "Z"]
  def adjust_field_length([char | _rest], acc, skeleton_tokens) when char in @substitutable_zone_fields  do
    {replacement_char, requested_length} = find_substitutable_field(@substitutable_zone_fields, skeleton_tokens)
    [List.duplicate(replacement_char, requested_length) | acc]
  end

  # Don't resize hour, minute or second
  @hms_fields ["H", "h", "K", "k", "m", "s", "S"]
  def adjust_field_length([char | _rest] = field, acc, _skeleton_tokens)
      when char in @hms_fields do
    [field | acc]
  end

  # Everything else, resize to the original request
  def adjust_field_length([char | _rest] = field, acc, skeleton_tokens) do
    field_length = length(field)
    requested_length = :proplists.get_value(char, skeleton_tokens, field_length)

    if length(field) == requested_length do
      [field | acc]
    else
      [List.duplicate(char, requested_length) | acc]
    end
  end

  defp find_substitutable_field(fields, skeleton) do
    Enum.reduce_while(fields, {"", 0}, fn field, acc ->
      if count = :proplists.get_value(field, skeleton, nil) do
        {:halt, {field, count}}
      else
        {:cont, acc}
      end
    end)
  end

  @doc false
  # The lookup path is:
  # 1. cldr_locale_name
  # 2. territory
  # 3. 001 ("The world")

  def time_preferences(%LanguageTag{} = locale) do
    time_preferences = Cldr.Time.time_preferences()

    Map.get(time_preferences, locale.cldr_locale_name) ||
      Map.get(time_preferences, locale.territory) ||
      Map.fetch!(time_preferences, :"001")
  end
end
