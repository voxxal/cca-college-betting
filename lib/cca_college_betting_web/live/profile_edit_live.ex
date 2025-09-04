defmodule CcaCollegeBettingWeb.ProfileEditLive do
  alias CcaCollegeBetting.Cache
  alias CcaCollegeBetting.Bets
  alias CcaCollegeBetting.Repo
  use CcaCollegeBettingWeb, :live_view

  alias CcaCollegeBetting.Accounts

  def render(assigns) do
    ~H"""
    <div>
      <.back navigate={~p"/profile"}>Back to profile</.back>
      <.header class="text-center">
        Edit your profile
        <:subtitle>Consider reading the FAQ</:subtitle>
      </.header>

      <div class="space-y-12 divide-y">
        <div>
          <.simple_form
            for={@profile_form}
            id="profile_form"
            phx-submit="update_profile"
            phx-change="validate_profile"
          >
            <.input
              field={@profile_form[:gender]}
              type="select"
              label="Gender"
              options={[Male: :male, Female: :female, Other: :other, "Prefer not to say": :unknown]}
            />
            <div class="text-center text-zinc-500">
              <.icon name="hero-arrow-down" class="w-5 h-5 mr-2" />
              These will not affect acceptance rates/betting odds
              <.icon name="hero-arrow-down" class="w-5 h-5 ml-2" />
            </div>

            <div class="grid grid-cols-2 gap-4">
              <.input field={@profile_form[:gpa]} type="number" label="Unweighted GPA" step="0.01" />
              <.input
                field={@profile_form[:weighted_gpa]}
                type="number"
                label="Weighted GPA"
                step="0.01"
              />
            </div>
            <div class="grid grid-cols-2 gap-4">
              <.input field={@profile_form[:sat_score]} type="number" label="SAT Score (total)" />
              <.input field={@profile_form[:act_score]} type="number" label="ACT Composite Score" />
            </div>

            <div class="grid grid-cols-2 gap-4">
              <.input field={@profile_form[:major]} type="text" label="Planned Major" />
              <.input
                field={@profile_form[:supplements]}
                type="text"
                label="Link to supplemental materials"
              />
            </div>

            <div class="grid items-center justify-center gap-4 md:grid-cols-2">
              <p>
                Private accounts do not let everyone view or bet on them. People may request to view or bet, but you must allow them to.
              </p>
              <div class="m-auto w-fit">
                <.input type="checkbox" field={@profile_form[:private]} label="Private Account" />
              </div>
              <div class="self-start mt-6 [text-wrap:pretty]">
                <h2 class="font-bold">Your Whitelist</h2>
                <p class="mt-3">Anyone who requested to view your profile will show up here.</p>
              </div>
              <div class="-mt-11">
                <.table id="your_whitelist" rows={@user.whitelist}>
                  <:col :let={entry} label=""><%= entry.member.name %></:col>
                  <:action :let={entry}>
                    <.button
                      onclick="event.preventDefault();"
                      phx-click={JS.push("whitelist_accept")}
                      phx-value-member-id={entry.member.id}
                      disabled={entry.status == :accepted}
                      class={"bg-green-500 hover:bg-green-600 #{entry.status == :accepted && "!bg-green-900 cursor-not-allowed"}"}
                    >
                      <%= if entry.status == :accepted do
                        "Accepted"
                      else
                        "Accept"
                      end %>
                    </.button>
                    <.button
                      onclick="event.preventDefault();"
                      phx-click={JS.push("whitelist_reject")}
                      phx-value-member-id={entry.member.id}
                      disabled={entry.status == :rejected}
                      class={"bg-red-500 hover:bg-red-600 #{entry.status == :rejected && "!bg-red-900 cursor-not-allowed"}"}
                    >
                      <%= if entry.status == :rejected do
                        "Rejected"
                      else
                        "Reject"
                      end %>
                    </.button>
                  </:action>
                </.table>
              </div>
            </div>
            <:actions>
              <.button phx-disable-with="Changing..." class="m-auto">Update Profile</.button>
            </:actions>
          </.simple_form>
        </div>
      </div>

      <.table id="markets" rows={@user.markets}>
        <:col :let={market} label="College Name"><%= market.college.name %></:col>
        <:action :let={market}>
          <.button
            class="bg-red-500 hover:bg-red-600"
            phx-click={JS.push("confirm_delete") |> show_modal("confirm_delete")}
            phx-value-market-id={market.id}
          >
            Delete College
          </.button>
        </:action>
      </.table>
      <.modal
        id="confirm_delete"
        on_confirm={JS.push("delete_market") |> hide_modal("confirm_delete")}
      >
        Are you sure you want to remove this college? Any bets made will NOT be refunded.
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>

      <form phx-change="college_search" action="" onkeydown="return event.key != 'Enter';">
        <.input value="" label="Add a College" name="college_search" phx-debounce="500" />
      </form>

      <%= if length(@colleges_filtered) == 0 and @college_search != "" do %>
        <div class="mt-4 text-center text-zinc-500">
          Can't find your college?
          <a href="mailto:contact@ccacollegebetting.com" class="underline">Contact me.</a>
        </div>
      <% else %>
        <.table id="colleges_filtered" rows={@colleges_filtered}>
          <:col :let={college} label=""><%= elem(college, 1) %></:col>
          <:action :let={college}>
            <.button phx-click={JS.push("create_market")} phx-value-college-id={elem(college, 0)}>
              Add College
            </.button>
          </:action>
        </.table>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user |> Repo.preload(whitelist: :member, markets: :college)
    profile_changeset = Accounts.change_profile(user)

    socket =
      socket
      |> assign(:page_title, "Profile Settings")
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:user, user)
      |> assign(:college_list, Cache.get(:colleges))
      |> assign(:college_search, "")
      |> assign(:colleges_filtered, [])

    {:ok, socket}
  end

  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    profile_form =
      socket.assigns.current_user
      |> Accounts.change_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_profile(user, user_params) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Details sucessfully updated.")}

      {:error, changeset} ->
        {:noreply,
         assign(socket, :profile_form, changeset |> Map.put(:action, :insert) |> to_form)}
    end
  end

  def handle_event("confirm_delete", %{"market-id" => market_id}, socket) do
    {:noreply, assign(socket, :market_to_delete, market_id)}
  end

  def handle_event("delete_market", _params, socket) do
    user = socket.assigns.current_user
    # TODO refund everyone
    market = Repo.get!(Bets.Market, socket.assigns.market_to_delete) |> Repo.preload([:user])

    cond do
      market.user.id == user.id && market.resolution == nil ->
        case Bets.resolve_market(market, :withdrawn) do
          {:ok, updated_market} ->
            case Repo.delete(updated_market) do
              {:ok, _} ->
                {:noreply,
                 socket
                 |> assign(:user, user |> Repo.preload(markets: :college))
                 |> put_flash(:info, "College sucessfully deleted.")}

              {:err, _} ->
                {:noreply,
                 socket
                 |> assign(:user, user |> Repo.preload(markets: :college))
                 |> put_flash(:error, "Failed to delete college, does it still exist?")}
            end
        end

      market.resolution != nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Cannot delete market that has already resolved.")}

      market.user.id != user.id ->
        {:noreply,
         socket
         |> put_flash(:error, "Cannot delete market not owned by you.")
         |> redirect(~p"/profile")}
    end
  end

  def handle_event("college_search", %{"college_search" => ""}, socket) do
    {:noreply, socket |> assign(:college_search, "") |> assign(:colleges_filtered, [])}
  end

  def handle_event("college_search", %{"college_search" => college_search}, socket) do
    user = socket.assigns.user
    user_college_ids = Enum.map(user.markets, & &1.college.id)

    colleges_filtered =
      socket.assigns.college_list
      |> Seqfuzz.filter(college_search, &elem(&1, 1))
      |> Enum.filter(fn {id, _, _} -> not Enum.member?(user_college_ids, id) end)
      |> Enum.sort_by(&elem(&1, 2), :desc)

    {:noreply,
     socket
     |> assign(:college_search, college_search)
     |> assign(
       :colleges_filtered,
       colleges_filtered |> Enum.take(20)
     )}
  end

  def handle_event("create_market", %{"college-id" => college_id}, socket) do
    user = socket.assigns.current_user

    case Bets.create_market(user, String.to_integer(college_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:user, user |> Repo.preload(whitelist: :member, markets: :college))
         |> assign(:colleges_filtered, [])
         |> assign(:college_search, "")
         |> put_flash(:info, "College sucessfully added.")}

      {:err, _} ->
        {:noreply,
         socket
         |> assign(:user, user |> Repo.preload(whitelist: :member, markets: :college))
         |> assign(:colleges_filtered, [])
         |> assign(:college_search, "")
         |> put_flash(:error, "Something went wrong.")}
    end
  end

  def handle_event("whitelist_accept", %{"member-id" => member_id}, socket) do
    user = socket.assigns.current_user

    Accounts.set_whitelist_entry(user.id, member_id, :accepted)

    {:noreply,
     socket
     |> assign(:user, user |> Repo.preload(whitelist: :member, markets: :college))}
  end

  def handle_event("whitelist_reject", %{"member-id" => member_id}, socket) do
    user = socket.assigns.current_user

    Accounts.set_whitelist_entry(user.id, member_id, :rejected)

    {:noreply,
     socket
     |> assign(:user, user |> Repo.preload(whitelist: :member, markets: :college))}
  end
end
