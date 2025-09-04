defmodule CcaCollegeBettingWeb.ProfileController do
  alias CcaCollegeBetting.Repo
  alias CcaCollegeBetting.Accounts
  use CcaCollegeBettingWeb, :controller

  def show(conn, %{"user_id" => user_id}) do
    # TODO this is querying user twice, this can be optimized out.
    user =
      Accounts.get_user!(user_id) |> Repo.preload(whitelist: :member)

    me =
      if conn.assigns.current_user do
        conn.assigns.current_user.id == user_id
      else
        false
      end
    conn = assign(conn, :page_title, user.name)


    if Accounts.accepted(user, conn.assigns.current_user) do
      user = user |> Repo.preload(markets: [:college, :user], bets: [market: [:college, :user]])
      render(conn, :show, user: user, me: me)
    else
      render(conn, :private,
        user: user,
        whitelist_entry: Accounts.get_whitelist_entry(user_id, conn.assigns.current_user.id)
      )
    end
  end

  def show_self(conn, _params) do
    redirect(conn, to: ~p"/#{conn.assigns.current_user.id}")
  end

  def request(conn, %{"user_id" => user_id}) do
    if Accounts.get_user!(user_id).private do
      Accounts.create_whitelist_entry(user_id, conn.assigns.current_user.id)
      redirect(conn, to: ~p"/#{user_id}")
    end
  end
end
