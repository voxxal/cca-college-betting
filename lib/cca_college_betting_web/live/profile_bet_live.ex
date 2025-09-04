defmodule CcaCollegeBettingWeb.ProfileBetLive do
  alias CcaCollegeBetting.Payout
  alias CcaCollegeBetting.Accounts
  alias CcaCollegeBetting.Bets
  alias CcaCollegeBetting.Repo
  import CcaCollegeBetting.Payout
  use CcaCollegeBettingWeb, :live_view

  def down_arrow(assigns) do
    ~H"""
    <div class="w-8 h-8 text-zinc-300">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="3"
        stroke="currentColor"
        aria-hidden="true"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M19.5 13.5L12 21m0 0l-7.5-7.5M12 21V3"
        />
      </svg>
    </div>
    """
  end

  def acceptance_rate_color(market) do
    rate = acceptance_rate(market)

    cond do
      rate >= 0.8 ->
        "text-green-600"

      rate >= 0.6 ->
        "text-green-300"

      rate >= 0.4 ->
        "text-yellow-600"

      rate >= 0.2 ->
        "text-orange-400"

      rate >= 0 ->
        "text-red-600"
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.back navigate={~p"/#{@market.user.id}"}>Back to profile</.back>
      <div class="grid gap-8 p-8 mb-8 -mx-8 rounded-lg md:grid-cols-2 bg-zinc-100">
        <div class="flex flex-col gap-4 font-display">
          <h1 class="mb-2 text-5xl font-black"><%= @market.user.name %></h1>
          <h2 class="text-4xl font-black"><%= @market.college.name %></h2>
          <h3 class="text-2xl ">
            <%= case @market.resolution do %>
              <% nil -> %>
                Acceptance rate:
                <span class={[acceptance_rate_color(@market), "font-black"]}>
                  <%= acceptance_rate_formatted(@market) %>%
                </span>
              <% :rejected -> %>
                Resolution: <span class="font-black text-red-600 font-display">Rejected</span>
              <% :accepted -> %>
                Resolution: <span class="font-black text-green-600 font-display">Accepted</span>
              <% :withdrawn -> %>
                Resolution: <span class="font-black text-black font-display">Withdrawn</span>
            <% end %>
          </h3>
        </div>
        <%= if @market.user.id != @current_user.id do %>
          <.simple_form
            :if={@market.resolution == nil}
            for={@bet_form}
            id="bet_form"
            name="bet"
            phx-submit="make_bet"
            phx-change="set_bet_size"
            class="[&>div]:flex [&>div]:flex-col"
          >
            <div class="grid grid-cols-[1fr_2fr_1fr] items-center gap-4">
              <div>Bet:</div>
              <div class="flex items-center justify-center gap-2">
                ℂ
                <div class="flex-1 -mt-2">
                  <.input
                    field={@bet_form[:volume]}
                    value={@bet_form[:volume].value / 100}
                    type="number"
                    step="0.01"
                    max="200"
                    min="0"
                    show_errors={false}
                  />
                </div>
              </div>
              <div class="text-green-500">
                (+<%= ((@bet_form[:volume].value - @my_bet.volume) / 100)
                |> max(0)
                |> Payout.currency_formatted() %>)
              </div>
            </div>
            <div class="grid grid-cols-[1fr_2fr_1fr] items-center gap-4">
              <div>Payout:</div>
              <div class="flex items-center justify-center gap-2">
                ℂ
                <div class="flex-1 -mt-2">
                  <.input
                    class="text-zinc-400"
                    disabled
                    field={@bet_form[:payout]}
                    value={@bet_form[:payout].value / 100}
                    type="number"
                  />
                </div>
              </div>
              <div class="text-green-500">
                (+<%= (((@bet_form[:payout].value || 0) - @my_bet.payout) / 100)
                |> max(0)
                |> Payout.currency_formatted() %>)
              </div>
            </div>
            <.error :for={msg <- @bet_form.errors |> Enum.map(&elem(elem(&1, 1), 0))}>
              <%= msg %>
            </.error>
            <div class="flex-1"></div>
            <:actions>
              <.button
                phx-disable-with="Betting.."
                disabled={length(@bet_form.errors) > 0}
                class="w-full"
              >
                <%= "#{if @my_bet.volume > 0, do: "Update", else: "Make"} Bet (Pay ℂ#{((@bet_form[:volume].value - @my_bet.volume) / 100) |> max(0) |> Payout.currency_formatted()})" %>
              </.button>
            </:actions>
          </.simple_form>
        <% else %>
          <div :if={@market.resolution == nil} class="flex flex-col">
            <h2 class="mb-2 text-2xl font-bold font-display">Rejected or Accepted?</h2>
            <p class="text-zinc-700">
              Report that on this page. This action is irreversible, please make sure that what you report is accurate.
            </p>
            <.button
              :if={!@show_resolve_buttons}
              phx-click={JS.push("show_resolve_buttons")}
              class="mt-auto"
            >
              Resolve This Market
            </.button>

            <div :if={@show_resolve_buttons} class="mt-auto">
              <div class="flex gap-2 mb-2">
                <.button
                  phx-click={JS.push("resolve_accepted")}
                  class="flex-1 bg-green-500 hover:bg-green-600"
                >
                  Accepted
                </.button>
                <.button
                  phx-click={JS.push("resolve_rejected")}
                  class="flex-1 bg-red-500 hover:bg-red-600"
                >
                  Rejected
                </.button>
                <.button phx-click={JS.push("resolve_withdrawn")} class="flex-1 bg-black">
                  Withdrawn
                </.button>
              </div>
              <.button phx-click={JS.push("hide_resolve_buttons")} class="w-full">
                Close
              </.button>
            </div>
          </div>
        <% end %>
      </div>
      <%!--

       --%>
      <h2>
        Market Volume:
        <span class="font-bold">
          ℂ<%= (Payout.total_volume(@market) / 100) |> Payout.currency_formatted() %>
        </span>
      </h2>
      <h2>
        Market Cap:
        <span class="font-bold">
          ℂ<%= (Payout.total_payout(@market) / 100) |> Payout.currency_formatted() %>
        </span>
      </h2>

      <.table id="bets" rows={@market.bets}>
        <:col :let={bet} label="Name">
          <.link navigate={~p"/#{bet.user.id}"} class="hover:underline"><%= bet.user.name %></.link>
        </:col>
        <:col :let={bet} label="Volume">
          ℂ<%= (bet.volume / 100) |> Payout.currency_formatted() %>
        </:col>
        <:col :let={bet} label="Expected Payout">
          ℂ<%= (bet.payout / 100) |> Payout.currency_formatted() %>
        </:col>
      </.table>
    </div>
    """
  end

  def mount(%{"user_id" => user_id, "college_id" => college_id}, _session, socket) do
    if Accounts.accepted(
         Accounts.get_user!(user_id) |> Repo.preload(:whitelist),
         socket.assigns.current_user
       ) do
      market =
        Bets.get_market_by_ids!(user_id, college_id)
        |> Repo.preload([:user, :college, bets: :user])

      my_bet =
        market.bets
        |> Enum.find(
          %Bets.Bet{
            user: socket.assigns.current_user,
            user_id: socket.assigns.current_user.id,
            market: market,
            market_id: market.id,
            payout: 0
          },
          &(&1.user_id == socket.assigns.current_user.id)
        )

      bet_changeset = Bets.change_bet(my_bet)

      socket =
        socket
        |> assign(:page_title, "#{market.user.name} · #{market.college.name}")
        |> assign(:bet_form, to_form(bet_changeset))
        |> assign(:market, market)
        |> assign(:my_bet, my_bet)
        |> assign(:show_resolve_buttons, false)

      # |> assign(:my_bet, my_bet)

      {:ok, socket}
    else
      {:ok, redirect(socket, to: ~p"/#{user_id}")}
    end
  end

  def handle_event("set_bet_size", %{"bet" => %{"volume" => ""}}, socket) do
    my_bet = socket.assigns.my_bet |> Bets.change_bet(%{"volume" => 0})

    bet_form =
      my_bet
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, bet_form: bet_form)}
  end

  def handle_event("set_bet_size", %{"bet" => bet_params}, socket) do
    my_bet =
      socket.assigns.my_bet
      |> Bets.change_bet(%{
        "volume" => trunc((Decimal.new(bet_params["volume"]) |> Decimal.to_float()) * 100)
      })

    bet_form =
      my_bet
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, bet_form: bet_form)}
  end

  def handle_event("make_bet", %{"bet" => bet_params}, socket) do
    my_bet = socket.assigns.my_bet

    market =
      Repo.reload(socket.assigns.market) |> Repo.preload([:user, :college, bets: :user])

    cond do
      market.user.id == socket.assigns.current_user ->
        {:noreply, socket |> put_flash(:error, "Cannot bet on own market.")}

      market.resolution != nil ->
        {:noreply,
         socket |> assign(:market, market) |> put_flash(:error, "Market has already resolved.")}

      my_bet.volume == bet_params["volume"] ->
        {:noreply, socket}

      true ->
        volume = trunc((Decimal.new(bet_params["volume"]) |> Decimal.to_float()) * 100)

        case Bets.update_bet(my_bet, %{"volume" => volume}) do
          {:ok, new_bet} ->
            {:noreply,
             socket
             |> put_flash(:info, "Bet sucessfully updated.")
             |> assign(
               :market,
               Repo.reload(market)
               |> Repo.preload([:user, :college, bets: :user])
             )
             |> assign(:current_user, Repo.reload(socket.assigns.current_user))
             |> assign(:my_bet, new_bet)}

          {:error, changeset} ->
            {:noreply,
             assign(socket, :bet_form, changeset |> Map.put(:action, :insert) |> to_form)}
        end
    end
  end

  def handle_event("show_resolve_buttons", _params, socket) do
    {:noreply, assign(socket, :show_resolve_buttons, true)}
  end

  def handle_event("hide_resolve_buttons", _params, socket) do
    {:noreply, assign(socket, :show_resolve_buttons, false)}
  end

  def handle_event("resolve_" <> atom, _params, socket) do
    market = socket.assigns.market
    owner = market.user
    resolution = String.to_existing_atom(atom)

    if owner == socket.assigns.current_user do
      case Bets.resolve_market(market, resolution) do
        {:ok, updated_market} ->
          {:noreply,
           socket
           |> put_flash(
             :info,
             case resolution do
               :rejected -> "Market resolved, nice try :("
               :accepted -> "Market resolved, congrats on getting in!"
               :withdrawn -> "Market resolved."
             end
           )
           |> assign(:market, updated_market)}
      end
    end
  end
end
