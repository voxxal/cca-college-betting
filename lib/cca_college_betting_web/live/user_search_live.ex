defmodule CcaCollegeBettingWeb.UserSearchLive do
  alias CcaCollegeBetting.Cache
  use CcaCollegeBettingWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <form
        phx-change="user_search"
        phx-debounce="500"
        action=""
        onkeydown="return event.key != 'Enter';"
      >
        <.input value="" placeholder="Search for someone..." name="user_search" />
      </form>

      <.table
        id="users_filtered"
        rows={@users_filtered}
        row_click={fn {id, _} -> JS.navigate(~p"/#{id}") end}
      >
        <:col :let={user} label="Name"><%= elem(user, 1) %></:col>
      </.table>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    users_list = Cache.get(:users)

    socket =
      socket
      |> assign(:page_title, "Search")
      |> assign(:users_list, users_list)
      |> assign(:users_filtered, users_list)

    {:ok, socket}
  end

  def handle_event("user_search", %{"user_search" => ""}, socket) do
    {:noreply, socket |> assign(:users_filtered, socket.assigns.users_list)}
  end

  def handle_event("user_search", %{"user_search" => user_search}, socket) do
    users_filtered =
      socket.assigns.users_list
      |> Seqfuzz.filter(user_search, &elem(&1, 1))

    {:noreply,
     socket
     |> assign(
       :users_filtered,
       users_filtered |> Enum.take(20)
     )}
  end
end
