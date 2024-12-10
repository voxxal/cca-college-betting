# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CcaCollegeBetting.Repo.insert!(%CcaCollegeBetting.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias NimbleCSV.RFC4180, as: CSV
alias CcaCollegeBetting, as: CCB

# Data from https://nces.ed.gov/ipeds/datacenter/CDSPreview.aspx

defmodule SeedHelper do
  def parse_test_status("Required to be considered for admission") do
    :required
  end

  def parse_test_status("Not required for admission, but considered if submitted (Test Optional)") do
    :optional
  end

  def parse_test_status("Not considered for admission, even if submitted (Test Blind)") do
    :blind
  end

  def parse_test_status(_) do
    :unknown
  end

  def parse_num("") do
    nil
  end

  def parse_num(str) do
    String.to_integer(str)
  end

  def parse() do
    "priv/repo/college_data.csv"
    |> File.stream!()
    |> CSV.parse_stream()
    |> Stream.filter(fn [_, _, _, test_status | _] -> test_status != "" end)
    |> Enum.map(fn [
                     id,
                     name,
                     _,
                     test_status,
                     application_total,
                     application_m,
                     application_f,
                     application_x,
                     application_u,
                     admissions_total,
                     admissions_m,
                     admissions_f,
                     admissions_x,
                     admissions_u,
                     sat_reading_25p,
                     sat_reading_50p,
                     sat_reading_75p,
                     sat_math_25p,
                     sat_math_50p,
                     sat_math_75p,
                     act_composite_25p,
                     act_composite_50p,
                     act_composite_75p
                   ] ->
      %{
        id: String.to_integer(id),
        name: :binary.copy(name),
        test_status: parse_test_status(:binary.copy(test_status)),
        application_total: parse_num(application_total),
        application_m: parse_num(application_m),
        application_f: parse_num(application_f),
        application_x: parse_num(application_x),
        application_u: parse_num(application_u),
        admission_total: parse_num(admissions_total),
        admission_m: parse_num(admissions_m),
        admission_f: parse_num(admissions_f),
        admission_x: parse_num(admissions_x),
        admission_u: parse_num(admissions_u),
        sat_reading_25p: parse_num(sat_reading_25p),
        sat_reading_50p: parse_num(sat_reading_50p),
        sat_reading_75p: parse_num(sat_reading_75p),
        sat_math_25p: parse_num(sat_math_25p),
        sat_math_50p: parse_num(sat_math_50p),
        sat_math_75p: parse_num(sat_math_75p),
        act_composite_25p: parse_num(act_composite_25p),
        act_composite_50p: parse_num(act_composite_50p),
        act_composite_75p: parse_num(act_composite_75p)
      }
    end)
    |> Enum.to_list
    |> (&CCB.Repo.insert_all(CCB.College, &1, on_conflict: :replace_all, conflict_target: :id)).()
  end
end

SeedHelper.parse()
