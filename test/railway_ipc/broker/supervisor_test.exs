defmodule RailwayIpc.Broker.SupervisorTest do
  use ExUnit.Case, async: true

  alias RailwayIpc.Broker.Supervisor, as: BrokerSupervisor

  defp normalize(config) do
    config |> Enum.sort()
  end

  test "invokes the init/1 callback on start", context do
    {:ok, _} = RailwayIpc.TestBroker.start_link(parent: self(), name: context.test)
    assert_receive {RailwayIpc.TestBroker, :init, _}
  end

  test "invokes the init/1 callback on config" do
    assert RailwayIpc.TestBroker.config() |> normalize() == [
             host: "localhost",
             otp_app: :railway_ipc
           ]
  end

  describe "compile_time_config/1" do
    test "requires :otp_app option" do
      assert_raise ArgumentError, "missing :otp_app option on use RailwayIpc.Broker", fn ->
        BrokerSupervisor.compile_time_config([])
      end
    end

    test "requires :adapter option" do
      assert_raise ArgumentError, "missing :adapter option on use RailwayIpc.Broker", fn ->
        BrokerSupervisor.compile_time_config(otp_app: :my_app)
      end
    end

    test "requires a defined module as :adapter" do
      assert_raise ArgumentError,
                   "adapter :foo was not compiled, ensure it is correct and it is included as a project dependency",
                   fn -> BrokerSupervisor.compile_time_config(otp_app: :my_app, adapter: :foo) end
    end

    test "requires an adapter that implements RailwayIpc.Adapters.Impl" do
      assert_raise ArgumentError,
                   "expected :adapter option given to `use RailwayIpc.Broker` to list RailwayIpc.Adapters.Impl as a behaviour",
                   fn ->
                     BrokerSupervisor.compile_time_config(
                       otp_app: :my_app,
                       adapter: RailwayIpc.InvalidTestAdapter
                     )
                   end
    end

    test "returns the otp_app, the adapter and the adapter behaviours" do
      assert {:my_app, RailwayIpc.TestAdapter, [RailwayIpc.Adapters.Impl]} =
               BrokerSupervisor.compile_time_config(
                 otp_app: :my_app,
                 adapter: RailwayIpc.TestAdapter
               )
    end
  end

  describe "runtime_config/4" do
    test "calls init/1 on the broker" do
      parent = self()
      opts = [parent: parent]

      assert {:ok, config} =
               BrokerSupervisor.runtime_config(
                 RailwayIpc.TestBroker,
                 :my_app,
                 RailwayIpc.TestAdapter,
                 opts
               )

      assert_received {RailwayIpc.TestBroker, :init, received_opts}
      assert [otp_app: :my_app, parent: ^parent] = normalize(received_opts)
      assert [host: "localhost", otp_app: :my_app, parent: ^parent] = normalize(config)
    end
  end

  describe "start_link/4" do
    test "calls adapter.child_spec with the runtime config" do
      parent = self()
      opts = [parent: parent, otp_app: :my_app, adapter: RailwayIpc.TestAdapter]

      assert {:ok, pid} =
               BrokerSupervisor.start_link(
                 RailwayIpc.TestBroker,
                 :my_app,
                 RailwayIpc.TestAdapter,
                 opts
               )

      assert_received {RailwayIpc.TestAdapter, :child_spec, received_opts}

      assert [
               adapter: RailwayIpc.TestAdapter,
               host: "localhost",
               otp_app: :my_app,
               parent: ^parent
             ] = normalize(received_opts)

      :ok = Supervisor.stop(pid)
    end
  end
end
