defmodule LumaaiEx do
  @moduledoc """
  A client library for the Luma Labs API using HTTPoison.

  This module provides a high-level interface for interacting with the Luma Labs API,
  including functions for authentication, making requests, and handling common operations.
  """
  require Logger

  alias LumaaiEx.Config
  alias LumaaiEx.Generation
  alias LumaaiEx.Client

  @doc """
  Creates a new LumaaiEx client configuration.

  ## Examples

      # Using the LUMAAI_API_KEY environment variable
      iex> System.put_env("LUMAAI_API_KEY", "your_api_key")
      iex> LumaaiEx.new()
      %LumaaiEx.Config{auth_token: "your_api_key", base_url: "https://api.lumalabs.ai"}

      # Explicitly providing the auth_token
      iex> LumaaiEx.new(auth_token: "your_api_key")
      %LumaaiEx.Config{auth_token: "your_api_key", base_url: "https://api.lumalabs.ai"}

      # Overriding the base URL
      iex> LumaaiEx.new(auth_token: "your_api_key", base_url: "https://custom-api.example.com")
      %LumaaiEx.Config{auth_token: "your_api_key", base_url: "https://custom-api.example.com"}
  """
  defdelegate new(opts \\ []), to: Config, as: :new

  @doc """
  Pings the Luma Labs API to check connectivity.

  ## Examples

      iex> client = LumaaiEx.new()
      iex> LumaaiEx.ping(client)
      {:ok, %{"message" => "pong"}}
  """
  @spec ping(Config.t()) :: {:ok, map()} | {:error, map()}
  def ping(client), do: Client.request(client, :get, "/dream-machine/v1/ping")

  @doc """
  Get the number of credits available for the account.

  ## Examples

      iex> client = LumaaiEx.new()
      iex> LumaaiEx.get_credits(client)
      {:ok, %{"credits" => 100}}
  """
  @spec get_credits(Config.t()) :: {:ok, map()} | {:error, map()}
  def get_credits(config), do: Client.request(config, :get, "/dream-machine/v1/credits")

  @doc """
  Lists generations.

  ## Parameters

    - client: A `LumaaiEx.Config` struct containing API configuration.
    - params: Optional query parameters (default: %{}).

  ## Returns

    - `{:ok, response}` on success.
    - `{:error, reason}` on failure.

  ## Examples

      iex> client = LumaaiEx.new()
      iex> {:ok, generations} = LumaaiEx.list_generations(client, limit: 100, offset: 0)
  """
  defdelegate list_generations(client, params \\ %{}), to: Generation, as: :list

  @doc """
  Retrieves a specific generation.

  ## Parameters

    - client: A `LumaaiEx.Config` struct containing API configuration.
    - id: The ID of the generation to retrieve.

  ## Returns

    - `{:ok, response}` on success.
    - `{:error, reason}` on failure.

  ## Examples

      iex> client = LumaaiEx.new()
      iex> {:ok, generation} = LumaaiEx.get_generation(client, "d1968551-6113-4b46-b567-09210c2e79b0")
  """
  defdelegate get_generation(client, id), to: Generation, as: :get

  @doc """
  Deletes a specific generation.

  ## Parameters

    - client: A `LumaaiEx.Config` struct containing API configuration.
    - id: The ID of the generation to delete.

  ## Returns

    - `{:ok, response}` on success.
    - `{:error, reason}` on failure.

  ## Examples

      iex> client = LumaaiEx.new()
      iex> {:ok, _} = LumaaiEx.delete_generation(client, "d1968551-6113-4b46-b567-09210c2e79b0")
  """
  defdelegate delete_generation(client, id), to: Generation, as: :delete

  @doc """
  Retrieves available camera motions.

  ## Parameters

    - client: A `LumaaiEx.Config` struct containing API configuration.

  ## Returns

    - `{:ok, response}` on success.
    - `{:error, reason}` on failure.

  ## Examples

      iex> client = LumaaiEx.new()
      iex> {:ok, supported_camera_motions} = LumaaiEx.get_camera_motions(client)
  """
  defdelegate get_camera_motions(client), to: Generation

  @doc """
  Creates a new generation.

  This function sends a request to the Luma Labs API to create a new video generation
  based on the provided parameters.

  ## Parameters

    - config: A `LumaaiEx.Config` struct containing API configuration.
    - params: A map of parameters for the generation. This can include:
      - prompt: A string describing the desired video content.
      - keyframes: A map of keyframes for image-to-video generation.
      - loop: A boolean indicating whether the video should loop.
      - aspect_ratio: A string specifying the desired aspect ratio (e.g., "16:9").

  ## Returns

    - `{:ok, response}` on success, where `response` is a map containing the generation details.
    - `{:error, reason}` on failure, where `reason` is a map containing error details.

  ## Examples

      config = LumaaiEx.new(auth_token: "your_api_key")
      params = %{
        prompt: "A tiger walking in snow",
        keyframes: %{
          frame0: %{
            type: "image",
            url: "https://example.com/tiger.jpg"
          }
        },
        loop: false,
        aspect_ratio: "16:9"
      }
      case LumaaiEx.create_generation(config, params) do
        {:ok, generation} ->
          IO.puts("Generation created with ID: " <> generation["id"])
        {:error, reason} ->
          IO.puts("Error creating generation: " <> inspect(reason))
      end
  """
  defdelegate create_generation(config, params), to: Generation, as: :create
end
