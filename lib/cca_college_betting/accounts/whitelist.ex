defmodule CcaCollegeBetting.Accounts.Whitelist do
  @raw "priv/repo/users.json"
       |> File.read!()
       |> Jason.decode!()

  @emails @raw |> Enum.map(&List.last/1)
  @emails_to_name @raw |> Enum.map(&(&1 |> Enum.reverse() |> List.to_tuple())) |> Map.new()

  def emails(), do: @emails
  def emails_to_name(), do: @emails_to_name
end
