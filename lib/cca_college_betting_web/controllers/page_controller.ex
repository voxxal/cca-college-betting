defmodule CcaCollegeBettingWeb.PageController do
  use CcaCollegeBettingWeb, :controller

  def home(conn, _params) do
    conn
    |> assign(:page_title, "Home")
    |> render(:home)
  end

  def faq(conn, _params) do
    conn
    |> assign(:page_title, "FAQ")
    |> render(:faq)
  end
end
