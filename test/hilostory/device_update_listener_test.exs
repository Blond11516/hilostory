defmodule Hilostory.DeviceUpdateListenerTest do
  use ExUnit.Case
  use Patch

  alias Hilostory.DeviceUpdateListener
  alias Hilostory.DeviceValue
  alias Hilostory.DeviceValue.Reading
  alias Hilostory.Fixture
  alias Hilostory.Graphql.Subscription
  alias Hilostory.Infrastructure.DeviceValueRepository
  alias Hilostory.Infrastructure.OauthTokensRepository
  alias Hilostory.Schema.OauthTokensSchema

  @subscription_base_uri URI.parse("wss://platform.hiloenergie.com/api/digital-twin/v3/graphql")

  setup do
    patch(DeviceValueRepository, :upsert, nil)

    :ok
  end

  test "given no access tokens are available, start_link returns an error" do
    patch(OauthTokensRepository, :get, nil)

    assert {:error, _} = DeviceUpdateListener.start_link(nil)
  end

  test "it starts a ghaphql subscription and returns the subscription pid" do
    given_tokens()
    expected_pid = given_subscription_starts()

    assert {:ok, ^expected_pid} = DeviceUpdateListener.start_link(nil)
  end

  test "it subscribes to the correct url with the access token as query param" do
    tokens = given_tokens()
    given_subscription_starts()

    DeviceUpdateListener.start_link(nil)

    expected_url =
      URI.append_query(
        @subscription_base_uri,
        URI.encode_query(%{"access_token" => tokens.access_token})
      )

    assert_called Subscription.start_link(%{url: ^expected_url})
  end

  test "when receiving a malformed device update, it raises" do
    handle_next = given_listener_is_started()

    assert catch_error(handle_next.("some malformed payload"))
  end

  test "it can handle a device update with a power value" do
    handle_next = given_listener_is_started()
    payload = Fixture.json("hilo/device_update_payloads/power-update.json")

    handle_next.(payload)

    {:ok, expected_timestamp, _} = DateTime.from_iso8601("2025-12-20T15:11:21.197Z")

    assert_reading_upsert(expected_timestamp, "urn:hilo:philo:0xc0619a400000d287-smart_meter:0", [
      %DeviceValue{
        type: :power,
        value: 1.132,
        kind: "KILOWATT"
      }
    ])
  end

  test "it can handle a device update with multiple values" do
    given_listener_is_started()
    [{:start_link, [%{handle_next: handle_next}]}] = history(Subscription)
    payload = Fixture.json("hilo/device_update_payloads/multiple-value-update.json")

    handle_next.(payload)

    {:ok, expected_timestamp, _} = DateTime.from_iso8601("2025-12-20T15:11:02.045Z")

    assert_reading_upsert(expected_timestamp, "urn:hilo:philo:5cc7c1fffeeab2c1:0", [
      %DeviceValue{
        type: :ambient_temperature,
        value: 20.0,
        kind: "DEGREE_CELSIUS"
      },
      %DeviceValue{
        type: :ambient_temperature_setpoint,
        value: 5.0,
        kind: "DEGREE_CELSIUS"
      },
      %DeviceValue{
        type: :power,
        value: 0.0,
        kind: "WATT"
      }
    ])
  end

  defp assert_reading_upsert(expected_timestamp, expected_device_id, expected_values) do
    [{:upsert, [readings, ^expected_device_id]}] = history(DeviceValueRepository)

    Enum.each(expected_values, fn value ->
      assert %Reading{
               timestamp: expected_timestamp,
               value: value
             } in readings
    end)
  end

  defp given_tokens do
    patch(OauthTokensRepository, :get, %OauthTokensSchema{
      access_token: "access",
      refresh_token: "refresh",
      refresh_token_expires_at: DateTime.utc_now()
    })
  end

  defp given_subscription_starts do
    {:ok, pid} = patch(Subscription, :start_link, {:ok, :pid})
    pid
  end

  defp given_listener_is_started do
    given_tokens()
    given_subscription_starts()
    DeviceUpdateListener.start_link(nil)

    [{:start_link, [%{handle_next: handle_next}]}] = history(Subscription)

    handle_next
  end
end
