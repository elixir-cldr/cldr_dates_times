defmodule Cldr.DateTime.Format.Match do

  alias Cldr.DateTime.Format.Compiler
  alias Cldr.DateTime.Format
  alias Cldr.LanguageTag

  @locale_preferred_time_symbol %{
    h11: "K",
    h12: "h",
    h23: "H",
    h24: "k"
  }

  @date_fields [
    "G", "y", "Y", "u",  "U", "r", "Q", "q", "M", "L", "W", "w", "d", "D", "F", "g", "E", "e", "c"
  ]

  @time_fields [
    "h", "H", "k", "K", "m", "s", "S", "v", "V", "z", "Z", "x", "X", "O", "a", "b", "B",
  ]

  @doc """
  Find the best match for a requested format.

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

      case candidates do
        [] ->
          try_date_and_time_skeletons(skeleton, original_skeleton, locale, calendar, backend)

        [{format_id, _} | _rest] ->
          {:ok, format_id}
      end
    end
  end

  def try_date_and_time_skeletons(skeleton, original, locale, calendar, backend) do
    with {date_skeleton, time_skeleton} <- separate_date_and_time_fields(skeleton),
         {:ok, date_format} <- best_match(date_skeleton, locale, calendar, backend),
         {:ok, time_format} <- best_match(time_skeleton, locale, calendar, backend) do
      {:ok, {date_format, time_format}}
    else _other ->
      {:error, no_format_resolved_error(original)}
    end
  end

  defp separate_date_and_time_fields(skeleton) do
    {date_fields, time_fields} =
      skeleton
      |> String.graphemes()
      |> Enum.reduce({[], []}, fn char, {date_fields, time_fields} ->
        date_fields = if char in @date_fields, do: [char | date_fields], else: date_fields
        time_fields = if char in @time_fields, do: [char | time_fields], else: time_fields
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

  # https://www.unicode.org/reports/tr35/tr35-dates.html#Matching_Skeletons
  # For skeleton and id fields with symbols representing the same type (year, month, day, etc):
  # Most symbols have a small distance from each other.
  #   M ≅ L; E ≅ c; a ≅ b ≅ B; H ≅ k ≅ h ≅ K; ...
  # Width differences among fields, other than those marking text vs numeric, are given small
  # distance from each other.
  #   MMM ≅ MMMM
  #   MM ≅ M
  # Numeric and text fields are given a larger distance from each other.
  #   MMM ≈ MM
  # Symbols representing substantial differences (week of year vs week of month) are given a much
  # larger distance from each other.
  #   ≋ D; ...

  defp candidates_with_the_same_tokens({_format_id, tokens}, skeleton_keys)
      when length(tokens) == length(skeleton_keys) do
    token_keys =
      tokens
      |> :proplists.get_keys()
      |> canonical_keys()

    token_keys == skeleton_keys
  end

  defp candidates_with_the_same_tokens({_format_id, _tokens}, _skeleton_keys) do
    false
  end

  # Sort the tokesn in canonical order, using
  # the substitution table.
  defp sort_tokens(tokens) do
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

  defp canonical_keys(keys) do
    keys
    |> Enum.map(&canonical_key/1)
    |> Enum.sort()
  end

  defp canonical_key(key) do
    case key do
      "L" -> "M"
      "c" -> "E"
      s when s in ["b", "B"] -> "a"
      s when s in ["k", "h", "K"] -> "H"
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
           when (elem(token_a, 0) in ["L", "M"] and elem(token_b, 0) in ["L", "M"]) or
                  (elem(token_a, 0) in ["c", "E"] and elem(token_b, 0) in ["c", "E"]) or
                  (elem(token_a, 0) in ["a", "b", "B"] and elem(token_b, 0) in ["a", "b", "B"]) or
                  (elem(token_a, 0) in ["k", "h", "K", "H"] and
                     elem(token_b, 0) in ["k", "h", "K", "H"])

  defguard same_types(token_a, token_b)
           when (elem(token_a, 1) in [1, 2] and elem(token_b, 1) in [1, 2]) or
                  (elem(token_a, 1) > 2 and elem(token_b, 1) > 2)

  defguard different_types(token_a, token_b)
           when (elem(token_a, 1) in [1, 2] and elem(token_b, 1) > 2) or
                  (elem(token_a, 1) > 2 and elem(token_b, 1) in [1, 2])

  defp distance_from({token_id, tokens}, skeleton) do
    sorted_tokens = sort_tokens(tokens)

    distance =
      Enum.zip_reduce(sorted_tokens, skeleton, 0, fn
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
          acc + 10
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
        |> assert_am_pm_if_required(preferred_time_symbol)

      {:ok, new_skeleton}
    else
      {:ok, skeleton}
    end
  end

  def locale_specifies_hour_cycle?(%{locale: %{hc: _}}), do: true
  def locale_specifies_hour_cycle?(_locale), do: false

  # If it has one, nothing to do
  defp assert_am_pm_if_required(skeleton, preferred) when preferred in ["h", "K"] do
    if String.contains?(skeleton, ["a", "b", "B"]) do
      skeleton
    else
      "a" <> skeleton
    end
  end

  defp assert_am_pm_if_required(skeleton, _preferred) do
    skeleton
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
  defp replace_time_symbols(<<format_code :: binary-1, rest::binary>>, preferred, allowed)
      when format_code in ["a", "b", "B"] and preferred in ["H", "k"] do
    replace_time_symbols(rest, preferred, allowed)
  end

  # Assert the correct symbol respecting the preference
  defp replace_time_symbols(<<"h", rest::binary>>, "H" = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<"h", rest::binary>>, "k" = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<"k", rest::binary>>, "K" = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<"H", rest::binary>>, "h" = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  defp replace_time_symbols(<<"K", rest::binary>>, "k" = preferred, allowed) do
    preferred <> replace_time_symbols(rest, preferred, allowed)
  end

  # Just pass it through
  defp replace_time_symbols(<<symbol::binary-1, rest::binary>>, preferred, allowed) do
    symbol <> replace_time_symbols(rest, preferred, allowed)
  end

  # Locale's time preference takes priority
  @doc false
  def preferred_time_symbol(%LanguageTag{locale: %{hc: hc}}) when is_atom(hc) do
    Map.fetch!(@locale_preferred_time_symbol, hc)
  end

  # The lookup path is:
  # 1. cldr_locale_name
  # 2. territory
  # 3. 001 ("The world")

  def preferred_time_symbol(%LanguageTag{} = locale) do
    time_preferences(locale).preferred
  end

  @doc false
  def allowed_time_symbols(locale) do
    time_preferences(locale).allowed
  end

  @doc false
  def time_preferences(locale) do
    time_preferences = Cldr.Time.time_preferences()

    Map.get(time_preferences, locale.cldr_locale_name) ||
      Map.get(time_preferences, locale.territory) ||
      Map.fetch!(time_preferences, :"001")
  end

end