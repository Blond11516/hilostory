defmodule Hilostory.Graphql.SubscriptionTest do
  use ExUnit.Case

  alias Hilostory.Graphql.Subscription
  alias Hilostory.Graphql.SubscriptionQuery

  @query %SubscriptionQuery{
    variables: %{},
    operation_name: "foo",
    query: "bar"
  }

  @next_payload %{
    "foo" => "bar"
  }

  test "it connects with the graphql-transport-ws protocol" do
    {_, client_hook} =
      start_server(%{
        on_conn: fn conn ->
          assert Plug.Conn.get_req_header(conn, "sec-websocket-protocol") == ["graphql-transport-ws"]
        end
      })

    start_subscription(client_hook)
  end

  test "it initializes the graphql connection on websocket connection" do
    {socket, client_hook} = start_server(%{handle_init?: false})

    self = self()

    TestServer.websocket_handle(socket,
      match: fn {:text, ~s/{"type":"connection_init"}/}, _state ->
        send(self, :initialized)
      end
    )

    start_subscription(client_hook)

    assert_receive :initialized, 1000
  end

  test "it subscribes after the connection is aknowledged" do
    {socket, client_hook} = start_server(%{handle_init?: false})

    self = self()

    TestServer.websocket_handle(socket,
      match: fn {:text, ~s/{"type":"connection_init"}/}, _state -> true end,
      to: fn _frame, state -> {:reply, {:text, ~s/{"type":"connection_ack"}/}, state} end
    )

    TestServer.websocket_handle(socket,
      match: fn {:text, payload}, _state ->
        expected_message =
          JSON.encode!(%{
            "type" => "subscribe",
            "id" => "0",
            "payload" => %{
              "variables" => @query.variables,
              "operationName" => @query.operation_name,
              "extensions" => %{},
              "query" => @query.query
            }
          })

        assert payload == expected_message
        send(self, :subscribed)
      end
    )

    start_subscription(client_hook, %{query: @query})

    assert_receive :subscribed, 1000
  end

  test "it responds to pings with a pong" do
    {socket, client_hook} = start_server()

    start_subscription(client_hook)

    self = self()

    TestServer.websocket_handle(socket,
      match: fn {:text, ~s/{"type":"pong"}/}, _state ->
        send(self, :ponged)
        true
      end
    )

    TestServer.websocket_info(socket, fn state ->
      {:reply, {:text, ~s/{"type":"ping"}/}, state}
    end)

    assert_receive :ponged, 1000
  end

  test "once subscribed, it handles next messages" do
    {socket, client_hook} = start_server()

    self = self()

    start_subscription(client_hook, %{
      handle_next: fn payload ->
        assert payload == @next_payload
        send(self, :received_next)
      end
    })

    TestServer.websocket_info(socket, fn state ->
      {:reply, {:text, ~s/{"type":"next","payload":#{JSON.encode!(@next_payload)}}/}, state}
    end)

    assert_receive :received_next, 1000
  end

  defp start_server(opts \\ %{}) do
    on_conn = Access.get(opts, :on_conn, fn _conn -> nil end)
    handle_init? = Access.get(opts, :handle_init?, true)

    {:ok, socket} =
      TestServer.websocket_init("/ws",
        to: fn conn ->
          on_conn.(conn)

          conn
        end
      )

    self = self()

    client_hook =
      if handle_init? do
        TestServer.websocket_handle(socket,
          match: fn {:text, ~s/{"type":"connection_init"}/}, _state -> true end,
          to: fn _frame, state ->
            send(self, :initialized)
            {:reply, {:text, ~s/{"type":"connection_ack"}/}, state}
          end
        )

        TestServer.websocket_handle(socket,
          match: fn {:text, message}, _state -> JSON.decode!(message).type == "subscribe" end,
          to: fn _frame, state ->
            send(self, :subscribed)
            {:ok, state}
          end
        )

        fn ->
          assert_receive :initialized, 1000
          assert_receive :subscribed, 1000
        end
      else
        fn -> nil end
      end

    {socket, client_hook}
  end

  defp start_subscription(client_hook, opts \\ %{}) do
    handle_next = Access.get(opts, :handle_next, fn _payload -> nil end)
    query = Access.get(opts, :query, @query)

    start_supervised(
      {Subscription,
       %{
         subscription: query,
         url: URI.parse(TestServer.url("/ws")),
         handle_next: handle_next
       }}
    )

    client_hook.()
  end
end
