defmodule CcaCollegeBettingWeb.PageController do
  use CcaCollegeBettingWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def faq(conn, _params) do
    render(conn, :faq)
  end
end
