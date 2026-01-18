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

  @tokens %OauthTokensSchema{
    access_token: "access",
    refresh_token: "refresh",
    refresh_token_expires_at: DateTime.utc_now()
  }
  @subscription_base_uri URI.parse("wss://platform.hiloenergie.com/api/digital-twin/v3/graphql")

  test "given no access tokens are available, start_link returns an error" do
    patch(OauthTokensRepository, :get, nil)

    assert {:error, _} = DeviceUpdateListener.start_link(nil)
  end

  test "it starts a ghaphql subscription and returns the subscription pid" do
    patch(OauthTokensRepository, :get, @tokens)
    {:ok, expected_pid} = patch(Subscription, :start_link, {:ok, :pid})

    assert {:ok, ^expected_pid} = DeviceUpdateListener.start_link(nil)
  end

  test "it subscribes to the correct url with the access token as query param" do
    patch(OauthTokensRepository, :get, @tokens)
    patch(Subscription, :start_link, {:ok, :pid})

    DeviceUpdateListener.start_link(nil)

    expected_url =
      URI.append_query(
        @subscription_base_uri,
        URI.encode_query(%{"access_token" => @tokens.access_token})
      )

    assert_called Subscription.start_link(%{url: ^expected_url})
  end

  test "when receiving a malformed device update, it raises" do
    patch(OauthTokensRepository, :get, @tokens)
    patch(Subscription, :start_link, {:ok, :pid})
    DeviceUpdateListener.start_link(nil)
    [{:start_link, [%{handle_next: handle_next}]}] = history(Subscription)

    assert catch_error(handle_next.("some malformed payload"))
  end

  test "it can handle a device update with a power value" do
    patch(OauthTokensRepository, :get, @tokens)
    patch(Subscription, :start_link, {:ok, :pid})
    patch(DeviceValueRepository, :upsert, nil)
    DeviceUpdateListener.start_link(nil)
    [{:start_link, [%{handle_next: handle_next}]}] = history(Subscription)
    payload = Fixture.json("hilo/device_update_payloads/power-update.json")

    handle_next.(payload)

    {:ok, expected_timestamp, _} = DateTime.from_iso8601("2025-12-20T15:11:21.197Z")

    assert_called DeviceValueRepository.upsert(
                    [
                      %Reading{
                        timestamp: ^expected_timestamp,
                        value: %DeviceValue{
                          type: :power,
                          value: 1.132,
                          kind: "KILOWATT"
                        }
                      }
                    ],
                    "urn:hilo:philo:0xc0619a400000d287-smart_meter:0"
                  )
  end

  test "it can handle a device update with multiple values" do
    patch(OauthTokensRepository, :get, @tokens)
    patch(Subscription, :start_link, {:ok, :pid})
    patch(DeviceValueRepository, :upsert, nil)
    DeviceUpdateListener.start_link(nil)
    [{:start_link, [%{handle_next: handle_next}]}] = history(Subscription)
    payload = Fixture.json("hilo/device_update_payloads/multiple-value-update.json")

    handle_next.(payload)

    {:ok, expected_timestamp, _} = DateTime.from_iso8601("2025-12-20T15:11:02.045Z")

    [{:upsert, [readings, "urn:hilo:philo:5cc7c1fffeeab2c1:0"]}] = history(DeviceValueRepository)

    assert %Reading{
             timestamp: expected_timestamp,
             value: %DeviceValue{
               type: :ambient_temperature,
               value: 20.0,
               kind: "DEGREE_CELSIUS"
             }
           } in readings

    assert %Reading{
             timestamp: expected_timestamp,
             value: %DeviceValue{
               type: :ambient_temperature_setpoint,
               value: 5.0,
               kind: "DEGREE_CELSIUS"
             }
           } in readings

    assert %Reading{
             timestamp: expected_timestamp,
             value: %DeviceValue{
               type: :power,
               value: 0.0,
               kind: "WATT"
             }
           } in readings
  end
end
