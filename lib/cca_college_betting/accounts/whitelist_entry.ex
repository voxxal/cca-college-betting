defmodule CcaCollegeBetting.Accounts.WhitelistEntry do
  alias CcaCollegeBetting.Repo
  alias CcaCollegeBetting.Accounts.User
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_whitelist_entries" do
    belongs_to :user, User, type: :string
    belongs_to :member, User, type: :string

    field :status, Ecto.Enum, values: [:requested, :accepted, :rejected]
  end

  def status_changeset(whitelist_entry, status) do
    whitelist_entry |> change(status: status)
  end
end
