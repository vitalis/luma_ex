defmodule LumaaiExTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  setup do
    bypass = Bypass.open()
    config = LumaaiEx.new(auth_token: "test_api_key", base_url: "http://localhost:#{bypass.port}")
    {:ok, config: config, bypass: bypass}
  end

  describe "new/1" do
    test "creates a new config with default base_url" do
      System.put_env("LUMAAI_API_KEY", "env_api_key")
      config = LumaaiEx.new()

      assert %LumaaiEx.Config{auth_token: "env_api_key", base_url: "https://api.lumalabs.ai"} =
               config
    end

    test "creates a new config with explicit auth_token" do
      config = LumaaiEx.new(auth_token: "explicit_api_key")

      assert %LumaaiEx.Config{auth_token: "explicit_api_key", base_url: "https://api.lumalabs.ai"} =
               config
    end

    test "creates a new config with custom base_url" do
      config = LumaaiEx.new(auth_token: "test_api_key", base_url: "https://custom.api.com")

      assert %LumaaiEx.Config{auth_token: "test_api_key", base_url: "https://custom.api.com"} =
               config
    end

    test "raises an error when no auth token is provided" do
      System.delete_env("LUMAAI_API_KEY")

      assert_raise RuntimeError, ~r/No auth token provided/, fn ->
        LumaaiEx.new()
      end
    end
  end

  describe "ping/1" do
    test "successfully pings the API", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/dream-machine/v1/ping", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{message: "pong"}))
      end)

      assert {:ok, %{message: "pong"}} = LumaaiEx.ping(config)
    end

    test "handles API errors", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/dream-machine/v1/ping", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(500, Jason.encode!(%{error: "Internal Server Error"}))
      end)

      assert {:error,
              %{status: 500, message: "HTTP 500", body: %{error: "Internal Server Error"}}} =
               LumaaiEx.ping(config)
    end

    test "handles network errors", %{config: config, bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, %{message: "HTTP Error", details: :econnrefused}} = LumaaiEx.ping(config)
    end

    test "handles invalid responses", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/dream-machine/v1/ping", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, "invalid json")
      end)

      assert {:error, %{message: "JSON decoding error", details: _}} = LumaaiEx.ping(config)
    end
  end

  describe "get_credits/1" do
    test "successfully retrieves credits", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/dream-machine/v1/credits", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{credits: 1000}))
      end)

      assert {:ok, %{credits: 1000}} = LumaaiEx.get_credits(config)
    end

    test "handles API errors", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/dream-machine/v1/credits", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(403, Jason.encode!(%{error: "Unauthorized"}))
      end)

      assert {:error, %{status: 403, message: "HTTP 403", body: %{error: "Unauthorized"}}} =
               LumaaiEx.get_credits(config)
    end

    test "handles invalid responses", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/dream-machine/v1/credits", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, "invalid json")
      end)

      assert {:error, %{message: "JSON decoding error", details: _}} =
               LumaaiEx.get_credits(config)
    end
  end

  describe "create_generation/2" do
    test "successfully creates a generation", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/dream-machine/v1/generations", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body) == %{"prompt" => "a beautiful sunset"}

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(
          201,
          Jason.encode!(%{
            id: "gen_123",
            prompt: "a beautiful sunset",
            status: "pending"
          })
        )
      end)

      assert {:ok, %{id: "gen_123", prompt: "a beautiful sunset", status: "pending"}} =
               LumaaiEx.create_generation(config, %{prompt: "a beautiful sunset"})
    end

    test "handles API errors", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/dream-machine/v1/generations", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, Jason.encode!(%{error: "Invalid prompt"}))
      end)

      assert {:error, %{status: 400, message: "HTTP 400", body: %{error: "Invalid prompt"}}} =
               LumaaiEx.create_generation(config, %{prompt: ""})
    end

    test "handles network errors", %{config: config, bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, %{message: "HTTP Error", details: :econnrefused}} =
               LumaaiEx.create_generation(config, %{prompt: "a beautiful sunset"})
    end

    test "handles JSON encoding errors", %{config: config} do
      assert capture_log(fn ->
               assert {:error,
                       %{message: "JSON encoding error", details: %Protocol.UndefinedError{}}} =
                        LumaaiEx.create_generation(config, %{prompt: {:invalid, :value}})
             end) =~ "Encoding failed with error"
    end
  end

  describe "list_generations/2" do
    test "successfully lists generations", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/dream-machine/v1/generations", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(
          200,
          Jason.encode!(%{generations: [%{id: "gen_123"}, %{id: "gen_456"}]})
        )
      end)

      assert {:ok, %{generations: [%{id: "gen_123"}, %{id: "gen_456"}]}} =
               LumaaiEx.list_generations(config)
    end

    test "successfully lists generations with query params", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/dream-machine/v1/generations", fn conn ->
        assert URI.decode_query(conn.query_string) == %{"limit" => "10", "status" => "completed"}

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{generations: [%{id: "gen_123"}]}))
      end)

      assert {:ok, %{generations: [%{id: "gen_123"}]}} =
               LumaaiEx.list_generations(config, %{limit: 10, status: "completed"})
    end

    test "handles API errors", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/dream-machine/v1/generations", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(500, Jason.encode!(%{error: "Internal Server Error"}))
      end)

      assert {:error,
              %{status: 500, message: "HTTP 500", body: %{error: "Internal Server Error"}}} =
               LumaaiEx.list_generations(config)
    end

    test "handles network errors", %{config: config, bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, %{message: "HTTP Error", details: :econnrefused}} =
               LumaaiEx.list_generations(config)
    end
  end

  describe "get_generation/2" do
    test "successfully retrieves a generation", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/dream-machine/v1/generations/gen_123", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(
          200,
          Jason.encode!(%{
            id: "gen_123",
            prompt: "a beautiful sunset",
            status: "completed"
          })
        )
      end)

      assert {:ok, %{id: "gen_123", prompt: "a beautiful sunset", status: "completed"}} =
               LumaaiEx.get_generation(config, "gen_123")
    end

    test "handles non-existent generation", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/dream-machine/v1/generations/non_existent", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(404, Jason.encode!(%{error: "Generation not found"}))
      end)

      assert {:error, %{status: 404, message: "HTTP 404", body: %{error: "Generation not found"}}} =
               LumaaiEx.get_generation(config, "non_existent")
    end

    test "handles network errors", %{config: config, bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, %{message: "HTTP Error", details: :econnrefused}} =
               LumaaiEx.get_generation(config, "gen_123")
    end
  end

  describe "delete_generation/2" do
    test "successfully deletes a generation", %{config: config, bypass: bypass} do
      Bypass.expect_once(bypass, "DELETE", "/dream-machine/v1/generations/gen_123", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert {:ok, ""} = LumaaiEx.delete_generation(config, "gen_123")
    end

    test "handles deletion of non-existent generation", %{config: config, bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/dream-machine/v1/generations/non_existent",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(404, Jason.encode!(%{error: "Generation not found"}))
        end
      )

      assert {:error, %{status: 404, message: "HTTP 404", body: %{error: "Generation not found"}}} =
               LumaaiEx.delete_generation(config, "non_existent")
    end

    test "handles network errors", %{config: config, bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, %{message: "HTTP Error", details: :econnrefused}} =
               LumaaiEx.delete_generation(config, "gen_123")
    end
  end

  describe "get_camera_motions/1" do
    test "successfully retrieves camera motions", %{config: config, bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/dream-machine/v1/generations/camera_motion/list",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, Jason.encode!(%{camera_motions: ["pan", "zoom", "rotate"]}))
        end
      )

      assert {:ok, %{camera_motions: ["pan", "zoom", "rotate"]}} =
               LumaaiEx.get_camera_motions(config)
    end

    test "handles API errors", %{config: config, bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/dream-machine/v1/generations/camera_motion/list",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(500, Jason.encode!(%{error: "Internal Server Error"}))
        end
      )

      assert {:error,
              %{status: 500, message: "HTTP 500", body: %{error: "Internal Server Error"}}} =
               LumaaiEx.get_camera_motions(config)
    end

    test "handles invalid responses", %{config: config, bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/dream-machine/v1/generations/camera_motion/list",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, "invalid json")
        end
      )

      assert {:error, %{message: "JSON decoding error", details: _}} =
               LumaaiEx.get_camera_motions(config)
    end

    test "handles network errors", %{config: config, bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, %{message: "HTTP Error", details: :econnrefused}} =
               LumaaiEx.get_camera_motions(config)
    end
  end
end
