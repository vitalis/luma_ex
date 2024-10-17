defmodule LumaaiEx.Config do
  @moduledoc """
  Configuration for the LumaaiEx client.

  This module defines the configuration structure used by the LumaaiEx client
  and provides functions to create a new configuration.
  """

  @type t :: %__MODULE__{
          auth_token: String.t(),
          base_url: String.t()
        }

  defstruct [:auth_token, :base_url]

  @base_url "https://api.lumalabs.ai"
  @env_var "LUMAAI_API_KEY"

  @doc """
  Creates a new LumaaiEx configuration.

  This function will attempt to retrieve the auth token in the following order:
  1. From the provided `auth_token` option
  2. From the LUMAAI_API_KEY environment variable
  3. If neither is available, it will raise an error

  ## Parameters

    - opts: Options for configuration (default: []).
      - :auth_token - Explicitly provide an auth token
      - :base_url - Override the default base URL

  ## Returns

    A `LumaaiEx.Config` struct.

  ## Examples

      iex> LumaaiEx.Config.new(auth_token: "your_api_key")
      %LumaaiEx.Config{auth_token: "your_api_key", base_url: "https://api.lumalabs.ai"}

      iex> System.put_env("LUMAAI_API_KEY", "env_api_key")
      iex> LumaaiEx.Config.new()
      %LumaaiEx.Config{auth_token: "env_api_key", base_url: "https://api.lumalabs.ai"}

      iex> LumaaiEx.Config.new(base_url: "https://custom-api.example.com")
      %LumaaiEx.Config{auth_token: "env_api_key", base_url: "https://custom-api.example.com"}

  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    auth_token = get_auth_token(opts)

    %__MODULE__{
      auth_token: auth_token,
      base_url: Keyword.get(opts, :base_url, @base_url)
    }
  end

  defp get_auth_token(opts) do
    case Keyword.get(opts, :auth_token) || System.get_env(@env_var) do
      nil ->
        raise "No auth token provided. Please set the LUMAAI_API_KEY environment variable or provide an :auth_token option."

      token ->
        token
    end
  end
end
