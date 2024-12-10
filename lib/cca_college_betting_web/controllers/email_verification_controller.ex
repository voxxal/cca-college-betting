defmodule CcaCollegeBettingWeb.EmailVerificationController do
  use CcaCollegeBettingWeb, :controller

  def verify(conn, %{"verification_id" => verification_id, "email" => email, "secret" => secret}) do
    # {:ok, email, _conn_details} = Plug.Conn.read_body(conn)
    if secret == System.get_env("EMAIL_VERIFICATION_SECRET") do
      CcaCollegeBettingWeb.Endpoint.broadcast("email_#{verification_id}", "verify", email)

      text(conn, "yay")
    else
      text(conn, "boo") |> put_status(401)
    end
  end
end
