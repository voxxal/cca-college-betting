defmodule CcaCollegeBetting.College do
  use Ecto.Schema
  import Ecto.Changeset

  schema "colleges" do
    field :name, :string

    field :test_status, Ecto.Enum, values: [:required, :optional, :blind, :unknown]

    field :application_total, :integer
    field :application_m, :integer
    field :application_f, :integer
    field :application_x, :integer
    field :application_u, :integer

    field :admission_total, :integer
    field :admission_m, :integer
    field :admission_f, :integer
    field :admission_x, :integer
    field :admission_u, :integer

    field :sat_reading_25p, :integer
    field :sat_reading_50p, :integer
    field :sat_reading_75p, :integer

    field :sat_math_25p, :integer
    field :sat_math_50p, :integer
    field :sat_math_75p, :integer

    field :act_composite_25p, :integer
    field :act_composite_50p, :integer
    field :act_composite_75p, :integer
  end

  @doc false
  def changeset(college, attrs) do
    college
    |> cast(attrs, [
      :id,
      :name,
      :application_total,
      :application_m,
      :application_f,
      :application_x,
      :application_u,
      :admission_total,
      :admission_m,
      :admission_f,
      :admission_x,
      :admission_u,
      :sat_reading_25p,
      :sat_reading_50p,
      :sat_reading_75p,
      :sat_math_25p,
      :sat_math_50p,
      :sat_math_75p,
      :act_composite_25p,
      :act_composite_50p,
      :act_composite_75p
    ])
    |> validate_required([:name])
  end
end
