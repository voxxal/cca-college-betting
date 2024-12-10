defmodule CcaCollegeBetting.Bets.Market do
  alias CcaCollegeBetting.{Accounts.User, College, Bets.Bet}
  use Ecto.Schema
  import Ecto.Changeset

  schema "markets" do
    belongs_to :college, College
    belongs_to :user, User, type: :string
    has_many :bets, Bet

    field :resolution, :boolean, default: nil
  end

  def resolution_changeset(market, resolution) when is_boolean(resolution) do
    market |> change() |> put_change(:resolution, resolution)
  end

  # @doc false
  # def changeset(market, attrs) do
  #   market
  #   |> cast(attrs, [:college, :user])
  #   |> unique_constraint([:college, :user], name: "markets_college_id_user_id_index")
  # end
end
