defmodule CcaCollegeBetting.Payout do
  alias CcaCollegeBetting.Repo

  def acceptance_rate(market) do
    market = market |> Repo.preload([:college, :user])

    case market.user.gender do
      :male ->
        market.college.admission_m / market.college.application_m

      :female ->
        market.college.admission_f / market.college.application_f

      _ ->
        (market.college.admission_m + market.college.admission_f) /
          (market.college.application_m + market.college.application_f)
    end
  end

  def acceptance_rate_formatted(market, decimal_places \\ 2) do
    (acceptance_rate(market) * 100)
    |> Decimal.from_float()
    |> Decimal.round(decimal_places)
  end

  def total_volume(market) do
    market = market |> Repo.preload(bets: :volume)

    market.bets |> Enum.reduce(fn x, acc -> x + acc end)
  end

  def payout(market, volume) do
    market = market |> Repo.preload([:college, :user, bets: :volume])
    acceptance_chance = acceptance_rate(market)
    market_volume = total_volume(market)

    # TODO weight lower acceptance rate colleges more
    acceptance_factor = max(1.0 / (acceptance_chance * 5) + 1, 1.05)
    # Volume Factor: Based on the volume of the current market, only applies to the first 100 bet
    volume_factor = max(1.0 / max(0.7, (market_volume + 500_00) / 1000_00), 1.0)

    if volume > 100_00 do
      volume_factor * acceptance_factor * 100 + 0.5 * acceptance_factor * (volume - 100)
    else
      volume_factor * acceptance_factor * volume
    end
  end

  def currency_formatted(number) do
    Number.Currency.number_to_currency(number, unit: "")
  end
end
