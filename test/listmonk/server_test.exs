defmodule Listmonk.ServerTest do
  use ExUnit.Case, async: true

  alias Listmonk.{Server, Config}

  setup do
    bypass = Bypass.open()

    config = %Config{
      url: "http://localhost:#{bypass.port}",
      username: "test_user",
      password: "test_pass"
    }

    {:ok, pid} = Server.start_link(config: config)

    {:ok, bypass: bypass, server: pid, config: config}
  end

  describe "start_link/1" do
    test "starts server with valid config" do
      bypass = Bypass.open()

      config = %Config{
        url: "http://localhost:#{bypass.port}",
        username: "user",
        password: "pass"
      }

      assert {:ok, pid} = Server.start_link(config: config)
      assert is_pid(pid)
      Server.stop(pid)
    end

    test "starts server with named process" do
      bypass = Bypass.open()

      config = %Config{
        url: "http://localhost:#{bypass.port}",
        username: "user",
        password: "pass"
      }

      assert {:ok, pid} = Server.start_link(config: config, name: :test_named_server)
      assert is_pid(pid)
      assert Process.whereis(:test_named_server) == pid
      Server.stop(:test_named_server)
    end

    test "starts server with keyword config" do
      bypass = Bypass.open()

      config = [
        url: "http://localhost:#{bypass.port}",
        username: "user",
        password: "pass"
      ]

      assert {:ok, pid} = Server.start_link(config: config)
      assert is_pid(pid)
      Server.stop(pid)
    end
  end

  describe "get_config/1" do
    test "returns current config", %{server: server, config: config} do
      retrieved = Server.get_config(server)
      assert retrieved.url == config.url
      assert retrieved.username == config.username
      assert retrieved.password == config.password
    end
  end

  describe "set_config/2" do
    test "updates config", %{server: server} do
      bypass = Bypass.open()

      new_config = %Config{
        url: "http://localhost:#{bypass.port}",
        username: "new_user",
        password: "new_pass"
      }

      assert :ok = Server.set_config(server, new_config)

      retrieved = Server.get_config(server)
      assert retrieved.username == "new_user"
      assert retrieved.password == "new_pass"
    end
  end

  describe "request/4 - GET requests" do
    test "sends GET request to correct path", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "GET", "/api/lists", fn conn ->
        assert Plug.Conn.get_req_header(conn, "authorization") |> List.first() =~
                 "Basic"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": {"results": []}}))
      end)

      assert {:ok, %{"data" => %{"results" => []}}} = Server.request(server, :get, "/api/lists")
    end

    test "sends GET request with query params", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "GET", "/api/subscribers", fn conn ->
        assert conn.query_string =~ "page=1"
        assert conn.query_string =~ "per_page=100"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": {"results": [], "total": 0}}))
      end)

      assert {:ok, _} =
               Server.request(server, :get, "/api/subscribers?page=1&per_page=100")
    end

    test "includes basic auth header", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "GET", "/api/health", fn conn ->
        [auth_header] = Plug.Conn.get_req_header(conn, "authorization")
        assert auth_header =~ "Basic"

        # Decode and verify credentials
        "Basic " <> encoded = auth_header
        decoded = Base.decode64!(encoded)
        assert decoded == "test_user:test_pass"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": true}))
      end)

      assert {:ok, _} = Server.request(server, :get, "/api/health")
    end
  end

  describe "request/4 - POST requests" do
    test "sends POST request with JSON body", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "POST", "/api/subscribers", fn conn ->
        assert Plug.Conn.get_req_header(conn, "content-type") |> List.first() =~
                 "application/json"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        payload = Jason.decode!(body)

        assert payload["email"] == "test@example.com"
        assert payload["name"] == "Test User"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": {"id": 1, "email": "test@example.com"}}))
      end)

      payload = %{"email" => "test@example.com", "name" => "Test User"}

      assert {:ok, %{"data" => %{"id" => 1}}} =
               Server.request(server, :post, "/api/subscribers", json: payload)
    end

    test "sends POST request to transactional endpoint", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "POST", "/api/tx", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        payload = Jason.decode!(body)

        assert payload["subscriber_email"] == "user@example.com"
        assert payload["template_id"] == 3
        assert payload["data"]["name"] == "John"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": true}))
      end)

      payload = %{
        "subscriber_email" => "user@example.com",
        "template_id" => 3,
        "data" => %{"name" => "John"}
      }

      assert {:ok, %{"data" => true}} = Server.request(server, :post, "/api/tx", json: payload)
    end
  end

  describe "request/4 - PUT requests" do
    test "sends PUT request with JSON body", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "PUT", "/api/subscribers/123", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        payload = Jason.decode!(body)

        assert payload["name"] == "Updated Name"
        assert payload["status"] == "enabled"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": {"id": 123, "name": "Updated Name"}}))
      end)

      payload = %{"name" => "Updated Name", "status" => "enabled"}

      assert {:ok, _} = Server.request(server, :put, "/api/subscribers/123", json: payload)
    end

    test "sends PUT request for template default", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "PUT", "/api/templates/5/default", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": true}))
      end)

      assert {:ok, %{"data" => true}} =
               Server.request(server, :put, "/api/templates/5/default")
    end
  end

  describe "request/4 - DELETE requests" do
    test "sends DELETE request to correct path", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "DELETE", "/api/subscribers/456", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": true}))
      end)

      assert {:ok, %{"data" => true}} = Server.request(server, :delete, "/api/subscribers/456")
    end

    test "sends DELETE request for list", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "DELETE", "/api/lists/7", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": true}))
      end)

      assert {:ok, %{"data" => true}} = Server.request(server, :delete, "/api/lists/7")
    end
  end

  describe "error handling" do
    test "returns error for 4xx responses", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "GET", "/api/nonexistent", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(404, ~s({"message": "Not found"}))
      end)

      assert {:error, error} = Server.request(server, :get, "/api/nonexistent")
      assert error.status_code == 404
    end

    test "returns error for 5xx responses", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "GET", "/api/error", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(500, ~s({"message": "Internal server error"}))
      end)

      assert {:error, error} = Server.request(server, :get, "/api/error")
      assert error.status_code == 500
    end

    test "returns error when server is down", %{server: server, bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, error} = Server.request(server, :get, "/api/health")
      assert error.message =~ "Request failed"
    end
  end

  describe "stop/1" do
    test "stops the server process" do
      bypass = Bypass.open()

      config = %Config{
        url: "http://localhost:#{bypass.port}",
        username: "user",
        password: "pass"
      }

      {:ok, pid} = Server.start_link(config: config)
      assert Process.alive?(pid)

      assert :ok = Server.stop(pid)
      refute Process.alive?(pid)
    end
  end
end
