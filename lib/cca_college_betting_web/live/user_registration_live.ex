defmodule CcaCollegeBettingWeb.UserRegistrationLive do
  use CcaCollegeBettingWeb, :live_view

  alias CcaCollegeBetting.Accounts
  alias CcaCollegeBetting.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="max-w-sm mx-auto">
      <.header class="text-center">
        Register for an account
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-red-500 hover:underline">
            Log in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
        class="mt-10"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:email]} type="email" label="Personal Email" required />
        <.input field={@form[:school_email]} type="email" label="School Email" required />
        <div class="p-8 rounded-lg md:-mx-24 bg-zinc-100">
          <h2 class="mb-2 text-xl font-bold font-display">Verify your school email</h2>
          <p>
            Send an email <strong>with your school email</strong>
            to the following email address to verify your email
          </p>
          <div class="p-2 overflow-x-scroll font-mono bg-white border rounded-md border-zinc-200">
            <%= @verification_id %>@ccacollegebetting.com
          </div>
          <div class="mt-2">
            <%= if @emails_verified == []  do %>
              <div class="text-zinc-400">
                <.icon name="hero-arrow-path animate-spin [animation-duration:5s]" /> Waiting on email
              </div>
            <% else %>
              <div class="text-zinc-500">
                Verified Emails: <%= @emails_verified |> Enum.join(", ") %>
              </div>
            <% end %>
          </div>
        </div>

        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})
    verification_id = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)
      |> assign(emails_verified: [])
      |> assign(verification_id: verification_id)

    if connected?(socket) do
      CcaCollegeBettingWeb.Endpoint.subscribe("email_#{verification_id}")
    end

    IO.puts(verification_id)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params, socket.assigns[:emails_verified]) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        Accounts.distribute_credits(user)
        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      Accounts.change_user_registration(%User{}, user_params, socket.assigns[:emails_verified])

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate)) |> assign(:page_title, "Register")}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end

  def handle_info(msg, socket) do
    IO.inspect([msg.payload | socket.assigns[:emails_verified]])

    {:noreply,
     socket |> assign(emails_verified: [msg.payload | socket.assigns[:emails_verified]])}
  end
end
