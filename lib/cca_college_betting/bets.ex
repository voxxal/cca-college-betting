defmodule CcaCollegeBetting.Bets do
  alias CcaCollegeBetting.Accounts.User
  alias CcaCollegeBetting.Accounts
  alias CcaCollegeBetting.Bets.{Bet, Market}
  alias CcaCollegeBetting.Repo
  import Ecto.Query

  def change_bet(bet, attrs \\ %{}) do
    Bet.changeset(bet, attrs)
  end

  def create_market(user, college_id) do
    Repo.insert(%Market{bets: [], college_id: college_id, user: user})
  end

  def get_market_by_ids!(user_id, college_id) when is_binary(user_id) do
    Repo.get_by(Market, user_id: user_id, college_id: college_id)
  end

  def get_market!(id) do
    Repo.get!(Market, id)
  end

  def update_bet(bet, attrs) do
    changeset =
      bet
      |> Bet.changeset(attrs)

    credits_spent = (changeset |> Ecto.Changeset.get_field(:volume)) - bet.volume
    res = Repo.insert_or_update(changeset)

    case res do
      {:ok, bet} ->
        case Accounts.spend_credits((bet |> Repo.preload(:user)).user, credits_spent) do
          {:ok, _} -> {:ok, bet}
          _ -> {:error, changeset}
        end

      {:error, :bet, changeset, _} ->
        {:error, changeset}
    end
  end

  def resolve_market(market, resolution) when is_atom(resolution) do
    market = market |> Repo.preload([:user, :college, bets: :user])
    changeset = market |> Market.resolution_changeset(resolution)

    case Repo.update(changeset) do
      {:ok, updated_market} ->
        case resolution do
          :accepted ->
            from(u in User,
              join: b in Bet,
              on: u.id == b.user_id and b.market_id == ^market.id,
              update: [inc: [credits: b.payout]]
            )
            |> Repo.update_all([])

          :withdrawn ->
            from(u in User,
              join: b in Bet,
              on: u.id == b.user_id and b.market_id == ^market.id,
              update: [inc: [credits: b.volume]]
            )
            |> Repo.update_all([])
        end

        {:ok, updated_market}

      {:error, :bet, changeset, _} ->
        {:error, changeset}
    end
  end

  def test_fn(market_id) do
    IO.inspect(
      from u in User,
        join: b in Bet,
        on: u.id == b.user_id and b.market_id == ^market_id,
        update: [inc: [credits: b.payout]]
    )
  end
end
