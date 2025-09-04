defmodule CcaCollegeBetting.Cache do
  import Ecto.Query, only: [from: 2]
  alias CcaCollegeBetting.Repo
  @values [colleges: {:fetch_colleges, {1, :days}}, users: {:fetch_users, {10, :mins}}]
  def init() do
    :ets.new(:cache, [:named_table, :public])
  end

  def get(value, force_recache \\ false) when is_atom(value) do
    case :ets.lookup(:cache, value) do
      [{^value, {result, exp}} | _] ->
        if exp <= :os.system_time(:seconds) or force_recache do
          recache(value)
        else
          result
        end

      _ ->
        recache(value)
    end
  end

  defp recache(value) do
    {fun, dur} = @values[value]
    result = apply(CcaCollegeBetting.Cache, fun, [])

    :ets.insert(
      :cache,
      {result, :os.system_time(:seconds) + to_seconds(dur)}
    )

    result
  end

  defp to_seconds({scalar, unit}) do
    scalar *
      case unit do
        :days -> 60 * 60 * 24
        :hours -> 60 * 60
        :mins -> 60
        :secs -> 1
      end
  end

  def fetch_colleges() do
    Repo.all(
      from c in "colleges",
        select: {c.id, c.name, c.application_total}
    )
  end

  def fetch_users() do
    Repo.all(
      from u in "users",
        left_join: m in "markets",
        on: u.id == m.user_id,
        left_join: b in "bets",
        on: m.id == b.market_id,
        group_by: [u.id, u.name],
        select: %{
          id: u.id,
          name: u.name,
          college_count: count(m.college_id, :distinct),
          bet_volume: coalesce(sum(b.volume), 0)
        }
    )
  end
end
