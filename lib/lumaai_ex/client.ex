defmodule LumaaiEx.Client do
  @moduledoc """
  HTTP client for making requests to the Luma Labs API.

  This module provides a low-level interface for sending HTTP requests
  to the Luma Labs API. It handles authentication and basic error handling.
  """

  @doc """
  Sends a request to the Luma Labs API.

  ## Parameters

    - config: A `LumaaiEx.Config` struct containing API configuration.
    - method: The HTTP method as an atom (e.g., :get, :post).
    - path: The API endpoint path.
    - body: The request body (default: "").
    - headers: Additional headers (default: []).
    - opts: Additional options for HTTPoison (default: []).

  ## Returns

    - `{:ok, response}` on success.
    - `{:error, reason}` on failure.
  """

  @spec request(LumaaiEx.Config.t(), atom(), String.t(), String.t(), keyword(), keyword()) ::
          {:ok, map()} | {:error, map()}
  def request(client, method, path, body \\ "", headers \\ [], opts \\ []) do
    url = client.base_url <> path

    headers = [
      {"Authorization", "Bearer #{client.auth_token}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
      | headers
    ]

    case HTTPoison.request(method, url, body, headers, opts) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: ""}}
      when status_code in 200..299 ->
        {:ok, ""}

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}}
      when status_code in 200..299 ->
        case Jason.decode(response_body, keys: :atoms) do
          {:ok, decoded_body} -> {:ok, decoded_body}
          {:error, _} -> {:error, %{message: "JSON decoding error", details: response_body}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        case Jason.decode(response_body, keys: :atoms) do
          {:ok, decoded_body} ->
            {:error, %{status: status_code, body: decoded_body, message: "HTTP #{status_code}"}}

          {:error, _} ->
            {:error, %{status: status_code, body: response_body, message: "HTTP #{status_code}"}}
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{message: "HTTP Error", details: reason}}
    end
  end
end
