defmodule CcaCollegeBetting.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:colleges, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :name, :string, null: false

      add :test_status, :string

      add :application_total, :integer
      add :application_m, :integer
      add :application_f, :integer
      add :application_x, :integer
      add :application_u, :integer

      add :admission_total, :integer
      add :admission_m, :integer
      add :admission_f, :integer
      add :admission_x, :integer
      add :admission_u, :integer

      add :sat_reading_25p, :integer
      add :sat_reading_50p, :integer
      add :sat_reading_75p, :integer

      add :sat_math_25p, :integer
      add :sat_math_50p, :integer
      add :sat_math_75p, :integer

      add :act_composite_25p, :integer
      add :act_composite_50p, :integer
      add :act_composite_75p, :integer
    end

    create table(:users, primary_key: false) do
      add :id, :citext, primary_key: true
      add :name, :text, null: false
      add :gender, :text, default: "unknown"
      add :email, :citext, null: false
      add :school_email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :school_confirmed_at, :naive_datetime
      add :credits, :integer, default: 0

      add :gpa, :float
      add :weighted_gpa, :float
      add :sat_score, :integer
      add :act_score, :integer

      add :private, :boolean

      timestamps()
    end

    create constraint("users", :sat_score_in_range, check: "sat_score > 0 AND sat_score <= 1600")
    create constraint("users", :act_score_in_range, check: "act_score > 0 AND act_score <= 36")

    create unique_index(:users, [:email])
    create unique_index(:users, [:school_email])

    create table(:markets) do
      add :college_id, references(:colleges, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :citext), null: false
      add :resolution, :boolean
    end

    create index(:markets, [:user_id])
    create unique_index(:markets, [:college_id, :user_id])

    create table(:bets) do
      add :market_id, references(:markets), null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :citext), null: false
      add :volume, :integer, null: false
      add :payout, :integer, null: false

      timestamps()
    end

    create index(:bets, [:market_id])
    create index(:bets, [:user_id])
    # create index(:bets, [:user_id, :market_id])
    create unique_index(:bets, [:market_id, :user_id])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all, type: :citext), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    create table(:user_whitelist_entries) do
      add :user_id, references(:users, on_delete: :delete_all, type: :citext), null: false
      add :member_id, references(:users, on_delete: :delete_all, type: :citext), null: false
      # either requested, accepted, rejected
      add :status, :string, null: false
    end

    create index(:user_whitelist_entries, [:user_id])
    create unique_index(:user_whitelist_entries, [:user_id, :member_id])
  end
end
