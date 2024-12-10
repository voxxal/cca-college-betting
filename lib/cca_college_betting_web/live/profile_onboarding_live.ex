defmodule CcaCollegeBettingWeb.ProfileOnboardingLive do
  alias CcaCollegeBetting.Cache
  alias CcaCollegeBetting.Bets
  alias CcaCollegeBetting.Repo
  use CcaCollegeBettingWeb, :live_view

  alias CcaCollegeBetting.Accounts

  def slide(assigns) do
    ~H"""
    <div
      class="w-full overflow-visible transition"
      x-bind:style={"{height: #{@no} === slide ? 'auto': '0', transform: `translateX(-${slide * 100}%)`}"}
    >
      <div class="flex flex-col items-center justify-center min-h-[30rem]  ease-out duration-300 w-full p-2">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div x-data="{ slide: 0 }" id="slides" class="w-full overflow-hidden">
      <div class="flex w-[500%] grid-flow-col">
        <.slide no={0}>
          <div class="font-display">
            <h1 class="text-6xl font-black [text-wrap:balance] mb-2">
              Welcome to CCA College Betting!
            </h1>
            <h2 class="text-3xl font-medium text-zinc-500">Lets get you set up.</h2>
          </div>
        </.slide>
        <.slide no={1}>
          <div class="font-display">
            <h1 class="mb-2 text-4xl font-black">Set your gender</h1>
            <h2 class="mb-8 max-w-[35ch]">This <em>will</em> affect your acceptance chances.</h2>
            <.simple_form for={@profile_form} id="gender_form" phx-change="validate_profile">
              <.input
                field={@profile_form[:gender]}
                type="select"
                options={[Male: :male, Female: :female, Other: :other, "Prefer not to say": :unknown]}
              />
            </.simple_form>
          </div>
        </.slide>
        <.slide no={2}>
          <div class="font-display">
            <h1 class="mb-2 text-4xl font-black">Customize your profile</h1>
            <h2 class="mb-8">
              This <b>will not</b>
              affect your acceptance chances, but will let your peers make more educated bets.
            </h2>
            <.simple_form
              for={@profile_form}
              id="profile_form"
              phx-submit="update_profile"
              phx-change="validate_profile"
            >
              <.input field={@profile_form[:gender]} type="hidden" />

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

              <div class="grid items-center justify-center grid-cols-2 gap-4">
                <div class="m-auto w-fit">
                  <.input type="checkbox" field={@profile_form[:private]} label="Private Account" />
                </div>
                <p>
                  Private accounts do not let everyone view or bet on them. People may request to view or bet, but you must allow them to.
                </p>
              </div>

              <:actions>
                <.button phx-disable-with="Changing..." class="w-full">Update Profile</.button>
              </:actions>
            </.simple_form>
          </div>
        </.slide>
        <.slide no={3}>
          <div class="font-display">
            <h1 class="mb-2 text-4xl font-black">Select your colleges</h1>
            <h2>
              These are colleges your peers will be able to bet on. You can edit these later.
            </h2>
          </div>
          <div class="w-full mb-8">
            <.table id="markets" rows={@user.markets}>
              <:col :let={market} label="College Name"><%= market.college.name %></:col>
              <:col :let={market} label="Acceptance Rate">
                <%= CcaCollegeBetting.Payout.acceptance_rate_formatted(market) %>%
              </:col>
              <:action :let={market}>
                <.button class="bg-red-500" phx-click="delete_market" phx-value-market-id={market.id}>
                  Delete College
                </.button>
              </:action>
            </.table>
          </div>

          <form
            class="w-full"
            phx-change="college_search"
            action=""
            onkeydown="return event.key != 'Enter';"
          >
            <.input value="" label="Add a College" name="college_search" phx-debounce="500" />
          </form>

          <div class="w-full">
            <%= if length(@colleges_filtered) == 0 and @college_search != "" do %>
              <div class="mt-4 text-center text-zinc-500">
                Can't find your college?
                <a href="mailto:contact@ccacollegebetting.com" class="underline">Contact me.</a>
              </div>
            <% else %>
              <.table id="colleges_filtered" rows={@colleges_filtered}>
                <:col :let={college} label=""><%= elem(college, 1) %></:col>
                <:action :let={college}>
                  <.button
                    phx-click={JS.push("create_market")}
                    phx-value-college-id={elem(college, 0)}
                  >
                    Add College
                  </.button>
                </:action>
              </.table>
            <% end %>
          </div>
        </.slide>
        <.slide no={4}>
          <div class="font-display">
            <h1 class="text-6xl font-black [text-wrap:balance] mb-2">
              You are all set up.
            </h1>
            <h2 class="text-3xl font-medium text-zinc-500">
              Start by
              <.link navigate={~p"/search"} class="text-red-500 underline">
                searching for your friends
              </.link>
            </h2>
          </div>
        </.slide>
      </div>
      <div class="flex items-center justify-center">
        <button
          class="p-2 pr-4 border rounded-l-md hover:bg-zinc-50"
          @click="slide = Math.max(0, slide - 1), console.log(slide)"
        >
          <.icon name="hero-chevron-left" /> Prev
        </button>
        <button
          class="p-2 pl-4 border border-l-0 rounded-r-md hover:bg-zinc-50"
          @click="slide = Math.min(4, slide + 1)"
        >
          Next <.icon name="hero-chevron-right" />
        </button>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    profile_changeset = Accounts.change_profile(user)

    socket =
      socket
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:user, user |> Repo.preload(markets: [:college, :user]))
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

  def handle_event("delete_market", %{"market-id" => market_id}, socket) do
    user = socket.assigns.current_user
    # TODO refund everyone
    market = Repo.get!(Bets.Market, market_id) |> Repo.preload([:user])

    if market.user.id == user.id do
      case Repo.delete(market) do
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
    else
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
         |> assign(:user, user |> Repo.preload(markets: :college))
         |> assign(:colleges_filtered, [])
         |> assign(:college_search, "")
         |> put_flash(:info, "College sucessfully added.")}

      {:err, _} ->
        {:noreply,
         socket
         |> assign(:user, user |> Repo.preload(markets: :college))
         |> assign(:colleges_filtered, [])
         |> assign(:college_search, "")
         |> put_flash(:error, "Something went wrong.")}
    end
  end
end
