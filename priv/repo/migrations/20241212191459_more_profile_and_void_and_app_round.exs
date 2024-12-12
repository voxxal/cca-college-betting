defmodule CcaCollegeBetting.Repo.Migrations.MoreProfileAndVoidAndAppRound do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :major, :text
      add :supplements, :text
    end

    alter table(:markets) do
      modify :resolution, :text
      add :early, :boolean, default: false
    end

    execute "UPDATE markets SET resolution = 'accepted' WHERE resolution = 'true'"
    execute "UPDATE markets SET resolution = 'rejected' WHERE resolution = 'false'"
  end
end
