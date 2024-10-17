# LumaaiEx

[![hex.pm version](https://img.shields.io/hexpm/v/lumaai_ex.svg?style=flat)](https://hex.pm/packages/lumaai_ex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/lumaai_ex/)
[![hex.pm license](https://img.shields.io/hexpm/l/lumaai_ex.svg)](https://github.com/vitalis/lumaai_ex/blob/master/LICENSE)
[![Build Status](https://github.com/vitalis/lumaai_ex/workflows/tests/badge.svg)](https://github.com/vitalis/lumaai_ex/actions)
[![Last Updated](https://img.shields.io/github/last-commit/vitalis/lumaai_ex.svg)](https://github.com/vitalis/lumaai_ex/commits/master)
[![Coverage Status](https://coveralls.io/repos/github/vitalis/lumaai_ex/badge.svg?branch=main)](https://coveralls.io/github/vitalis/lumaai_ex?branch=main)




A client library for the Luma Labs API, providing a simple and intuitive interface for Elixir applications to interact with Luma Labs services.

## Installation

Add `lumaai_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:lumaai_ex, "~> 0.1.0"}
  ]
end
```

## Usage

To use the Luma Labs API, you need an API key. Sign up for an account on the [Luma Labs website](https://lumalabs.ai/) to obtain your key.

### Authentication

1. Get a key from https://lumalabs.ai/dream-machine/api/keys
2. Pass it to the client SDK by either:
   1. Setting the `LUMAAI_API_KEY` environment variable
   2. Passing `auth_token` to the client

### Setting up the client

Using `LUMAAI_API_KEY` env variable:

```elixir
client = LumaaiEx.new()
```

Using `auth_token` parameter:

```elixir
client = LumaaiEx.new(auth_token: System.get_env("LUMAAI_API_KEY"))
```

### Making API calls

#### Create a new text-to-video generation

```elixir
{:ok, generation} = LumaaiEx.create_generation(client, %{
  prompt: "A teddy bear in sunglasses playing electric guitar and dancing"
})
```

#### Create a generation with loop and aspect ratio

```elixir
{:ok, generation} = LumaaiEx.create_generation(client, %{
  prompt: "A teddy bear in sunglasses playing electric guitar and dancing",
  loop: true,
  aspect_ratio: "3:4"
})
```

#### Create an image-to-video generation with a start frame

```elixir
{:ok, generation} = LumaaiEx.create_generation(client, %{
  prompt: "Low-angle shot of a majestic tiger prowling through a snowy landscape, leaving paw prints on the white blanket",
  keyframes: %{
    frame0: %{
      type: "image",
      url: "https://storage.cdn-luma.com/dream_machine/7e4fe07f-1dfd-4921-bc97-4bcf5adea39a/video_0_thumb.jpg"
    }
  }
})
```

#### Extend a video

```elixir
{:ok, generation} = LumaaiEx.create_generation(client, %{
  prompt: "A teddy bear in sunglasses playing electric guitar and dancing",
  keyframes: %{
    frame0: %{
      type: "generation",
      id: "d1968551-6113-4b46-b567-09210c2e79b0"
    }
  }
})
```

#### Get a specific generation

```elixir
{:ok, generation} = LumaaiEx.get_generation(client, "d1968551-6113-4b46-b567-09210c2e79b0")
```

#### List all generations

```elixir
{:ok, generations} = LumaaiEx.list_generations(client, limit: 100, offset: 0)
```

#### Delete a generation

```elixir
{:ok, _} = LumaaiEx.delete_generation(client, "d1968551-6113-4b46-b567-09210c2e79b0")
```

#### Get available camera motions

```elixir
{:ok, supported_camera_motions} = LumaaiEx.get_camera_motions(client)
```

#### Create a generation with a callback URL

```elixir
{:ok, generation} = LumaaiEx.create_generation(client, %{
  prompt: "A teddy bear in sunglasses playing electric guitar and dancing",
  callback_url: "https://your-api-endpoint.com/callback"
})
```

### How to get the video for a generation

Right now, the only supported way is via polling. The create endpoint returns an id which is a UUID V4. You can use it to poll for updates (you can see the video at `generation.assets.video`).

```elixir
defmodule GenerationPoller do
  def poll_until_completed(client, generation_id) do
    case LumaaiEx.get_generation(client, generation_id) do
      {:ok, %{state: "completed", assets: %{video: video_url}}} ->
        {:ok, video_url}
      {:ok, %{state: "failed", failure_reason: reason}} ->
        {:error, "Generation failed: #{reason}"}
      {:ok, _} ->
        IO.puts("Dreaming...")
        Process.sleep(3000)
        poll_until_completed(client, generation_id)
      {:error, reason} ->
        {:error, reason}
    end
  end
end

{:ok, generation} = LumaaiEx.create_generation(client, %{
  prompt: "A teddy bear in sunglasses playing electric guitar and dancing"
})

case GenerationPoller.poll_until_completed(client, generation.id) do
  {:ok, video_url} ->
    # Download the video
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(video_url)
    File.write!("#{generation.id}.mp4", body)
    IO.puts("File downloaded as " <> generation.id <> ".mp4")
  {:error, reason} ->
    IO.puts("Error: " <> reason)
end
```

For more information on available endpoints and parameters, refer to the [Luma Labs API documentation](https://docs.lumalabs.ai/docs/api).

## Documentation

Full documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc). After installing it, run:

```
mix docs
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.
