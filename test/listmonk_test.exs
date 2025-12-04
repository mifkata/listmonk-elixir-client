defmodule ListmonkTest do
  use ExUnit.Case, async: true

  alias Listmonk.Config

  setup do
    bypass = Bypass.open()

    config = %Config{
      url: "http://localhost:#{bypass.port}",
      username: "admin",
      password: "secret"
    }

    {:ok, pid} = Listmonk.new(config)

    {:ok, bypass: bypass, server: pid}
  end

  describe "new/1 and new/2" do
    test "creates a new client with config" do
      bypass = Bypass.open()

      config = %Config{
        url: "http://localhost:#{bypass.port}",
        username: "user",
        password: "pass"
      }

      assert {:ok, pid} = Listmonk.new(config)
      assert is_pid(pid)
      Listmonk.stop(pid)
    end

    test "creates a named client with alias" do
      bypass = Bypass.open()

      config = %Config{
        url: "http://localhost:#{bypass.port}",
        username: "user",
        password: "pass"
      }

      assert {:ok, pid} = Listmonk.new(config, :my_test_client)
      assert Process.whereis(:my_test_client) == pid
      Listmonk.stop(:my_test_client)
    end

    test "accepts keyword config" do
      bypass = Bypass.open()

      config = [
        url: "http://localhost:#{bypass.port}",
        username: "user",
        password: "pass"
      ]

      assert {:ok, pid} = Listmonk.new(config)
      assert is_pid(pid)
      Listmonk.stop(pid)
    end
  end

  describe "healthy?/1" do
    test "returns true when API returns healthy", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "GET", "/api/health", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": true}))
      end)

      assert {:ok, true} = Listmonk.healthy?(server)
    end

    test "returns false when API returns unhealthy", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "GET", "/api/health", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": false}))
      end)

      assert {:ok, false} = Listmonk.healthy?(server)
    end
  end

  describe "get_lists/1" do
    test "fetches lists from correct endpoint", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "GET", "/api/lists", fn conn ->
        assert conn.query_string =~ "per_page=1000000"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(
          200,
          ~s({"data": {"results": [{"id": 1, "name": "Newsletter", "type": "public"}]}})
        )
      end)

      assert {:ok, [list]} = Listmonk.get_lists(server)
      assert list.id == 1
      assert list.name == "Newsletter"
    end
  end

  describe "get_subscribers/2" do
    test "fetches subscribers from correct endpoint", %{bypass: bypass, server: server} do
      Bypass.stub(bypass, "GET", "/api/subscribers", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(
          200,
          ~s({"data": {"results": [{"id": 1, "email": "test@example.com", "name": "Test"}], "total": 1}})
        )
      end)

      assert {:ok, [subscriber]} = Listmonk.get_subscribers(server)
      assert subscriber.email == "test@example.com"
    end

    test "passes query parameters", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "GET", "/api/subscribers", fn conn ->
        assert conn.query_string =~ "query="

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": {"results": [], "total": 0}}))
      end)

      assert {:ok, []} =
               Listmonk.get_subscribers(server, query: "subscribers.email LIKE '%@test.com'")
    end
  end

  describe "create_subscriber/2" do
    test "sends POST request with subscriber data", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "POST", "/api/subscribers", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        payload = Jason.decode!(body)

        assert payload["email"] == "new@example.com"
        assert payload["name"] == "New User"
        assert payload["lists"] == [1]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(
          200,
          ~s({"data": {"id": 5, "email": "new@example.com", "name": "New User"}})
        )
      end)

      assert {:ok, subscriber} =
               Listmonk.create_subscriber(server, %{
                 email: "new@example.com",
                 name: "New User",
                 lists: [1]
               })

      assert subscriber.id == 5
      assert subscriber.email == "new@example.com"
    end
  end

  describe "get_campaigns/1" do
    test "fetches campaigns from correct endpoint", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "GET", "/api/campaigns", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(
          200,
          ~s({"data": {"results": [{"id": 1, "name": "Welcome", "subject": "Hello"}]}})
        )
      end)

      assert {:ok, [campaign]} = Listmonk.get_campaigns(server)
      assert campaign.id == 1
      assert campaign.name == "Welcome"
    end
  end

  describe "create_campaign/2" do
    test "sends POST request with campaign data", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "POST", "/api/campaigns", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        payload = Jason.decode!(body)

        assert payload["name"] == "Test Campaign"
        assert payload["subject"] == "Test Subject"
        assert payload["lists"] == [1, 2]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": {"id": 10, "name": "Test Campaign"}}))
      end)

      assert {:ok, campaign} =
               Listmonk.create_campaign(server, %{
                 name: "Test Campaign",
                 subject: "Test Subject",
                 lists: [1, 2]
               })

      assert campaign.id == 10
    end
  end

  describe "get_templates/1" do
    test "fetches templates from correct endpoint", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "GET", "/api/templates", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": [{"id": 1, "name": "Default", "type": "campaign"}]}))
      end)

      assert {:ok, [template]} = Listmonk.get_templates(server)
      assert template.id == 1
      assert template.name == "Default"
    end
  end

  describe "send_transactional_email/2" do
    test "sends POST request to tx endpoint", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "POST", "/api/tx", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        payload = Jason.decode!(body)

        assert payload["subscriber_email"] == "user@example.com"
        assert payload["template_id"] == 3
        assert payload["data"]["code"] == "ABC123"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": true}))
      end)

      assert {:ok, true} =
               Listmonk.send_transactional_email(server, %{
                 subscriber_email: "user@example.com",
                 template_id: 3,
                 data: %{"code" => "ABC123"}
               })
    end
  end

  describe "delete operations" do
    test "delete_subscriber/2 sends DELETE to correct path", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "DELETE", "/api/subscribers/99", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": true}))
      end)

      assert {:ok, true} = Listmonk.delete_subscriber(server, 99)
    end

    test "delete_list/2 checks existence then deletes", %{bypass: bypass, server: server} do
      # First, it checks if list exists
      Bypass.expect_once(bypass, "GET", "/api/lists/5", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": {"id": 5, "name": "Test List"}}))
      end)

      # Then it deletes
      Bypass.expect_once(bypass, "DELETE", "/api/lists/5", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": true}))
      end)

      assert {:ok, true} = Listmonk.delete_list(server, 5)
    end

    test "delete_campaign/2 checks existence then deletes", %{bypass: bypass, server: server} do
      Bypass.expect_once(bypass, "GET", "/api/campaigns/15", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": {"id": 15, "name": "Campaign"}}))
      end)

      Bypass.expect_once(bypass, "DELETE", "/api/campaigns/15", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": true}))
      end)

      assert {:ok, true} = Listmonk.delete_campaign(server, 15)
    end
  end

  describe "using named server" do
    test "all operations work with named server" do
      bypass = Bypass.open()

      config = %Config{
        url: "http://localhost:#{bypass.port}",
        username: "user",
        password: "pass"
      }

      {:ok, _pid} = Listmonk.new(config, :named_test_client)

      Bypass.expect_once(bypass, "GET", "/api/health", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"data": true}))
      end)

      # Use the alias instead of pid
      assert {:ok, true} = Listmonk.healthy?(:named_test_client)

      Listmonk.stop(:named_test_client)
    end
  end
end
