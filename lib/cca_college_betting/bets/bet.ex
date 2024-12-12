defmodule CcaCollegeBetting.Bets.Bet do
  alias CcaCollegeBetting.Repo
  alias CcaCollegeBetting.Payout
  alias CcaCollegeBetting.Accounts.User
  alias CcaCollegeBetting.Bets.Market
  use Ecto.Schema
  import Ecto.Changeset

  schema "bets" do
    belongs_to :market, Market
    belongs_to :user, User, type: :string
    field :volume, :integer, default: 0
    field :payout, :integer

    timestamps()
  end

  @doc false
  def changeset(bet, attrs) do
    bet = bet |> Repo.preload([:user, :market])

    changeset =
      bet
      |> cast(attrs, [:volume])
      |> validate_required([:volume])
      |> validate_number(:volume,
        greater_than_or_equal_to: bet.volume,
        message: "Must be greater than previous bet of #{bet.volume / 100}"
      )
      # volume < bet.user.credits + old_volume

      |> validate_number(:volume,
        less_than_or_equal_to: bet.user.credits + bet.volume,
        message: "Not enough credits"
      )
      |> validate_number(:volume, less_than_or_equal_to: 200_00, message: "Max bet of 200")
      |> validate_number(:volume, greater_than_or_equal_to: 10_00, message: "Min bet of 10")
      |> unique_constraint([:market_id, :user_id])

    put_change(
      changeset,
      :payout,
      trunc(
        Payout.payout(
          get_assoc(changeset, :market, :struct),
          get_field(changeset, :volume, 0)
        )
      )
    )
  end
end
