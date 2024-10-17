defmodule LumaaiEx.Generation do
  @moduledoc """
  Functions for interacting with the Luma Labs Generation API.

  This module provides high-level functions for creating, listing, retrieving,
  and deleting generations, as well as fetching available camera motions.
  """
  require Logger

  alias LumaaiEx.Client

  @doc """
  Creates a new generation.

  ## Parameters

    - client: A `LumaaiEx.Config` struct containing API configuration.
    - params: A map of parameters for the generation.

  ## Returns

    - `{:ok, response}` on success.
    - `{:error, reason}` on failure.
  """
  @spec create(LumaaiEx.Config.t(), map()) :: {:ok, map()} | {:error, map()}
  def create(config, params) do
    case Jason.encode(params) do
      {:ok, body} ->
        Client.request(config, :post, "/dream-machine/v1/generations", body)

      {:error, error} ->
        Logger.error("Encoding failed with error: #{inspect(error)}")
        {:error, %{message: "JSON encoding error", details: error}}
    end
  end

  @doc """
  Lists generations.

  ## Parameters

    - client: A `LumaaiEx.Config` struct containing API configuration.
    - params: Optional query parameters (default: %{}).

  ## Returns

    - `{:ok, response}` on success.
    - `{:error, reason}` on failure.
  """
  @spec list(LumaaiEx.Config.t(), map()) :: {:ok, map()} | {:error, map()}
  def list(client, params \\ %{}) do
    Client.request(client, :get, "/dream-machine/v1/generations?" <> URI.encode_query(params))
  end

  @doc """
  Retrieves a specific generation.

  ## Parameters

    - client: A `LumaaiEx.Config` struct containing API configuration.
    - id: The ID of the generation to retrieve.

  ## Returns

    - `{:ok, response}` on success.
    - `{:error, reason}` on failure.
  """
  @spec get(LumaaiEx.Config.t(), String.t()) :: {:ok, map()} | {:error, map()}
  def get(client, id) do
    Client.request(client, :get, "/dream-machine/v1/generations/#{id}")
  end

  @doc """
  Deletes a specific generation.

  ## Parameters

    - client: A `LumaaiEx.Config` struct containing API configuration.
    - id: The ID of the generation to delete.

  ## Returns

    - `{:ok, response}` on success.
    - `{:error, reason}` on failure.
  """
  @spec delete(LumaaiEx.Config.t(), String.t()) :: {:ok, map()} | {:error, map()}
  def delete(client, id) do
    Client.request(client, :delete, "/dream-machine/v1/generations/#{id}")
  end

  @doc """
  Retrieves available camera motions.

  ## Parameters

    - client: A `LumaaiEx.Config` struct containing API configuration.

  ## Returns

    - `{:ok, response}` on success.
    - `{:error, reason}` on failure.
  """
  @spec get_camera_motions(LumaaiEx.Config.t()) :: {:ok, map()} | {:error, map()}
  def get_camera_motions(client) do
    Client.request(client, :get, "/dream-machine/v1/generations/camera_motion/list")
  end
end
