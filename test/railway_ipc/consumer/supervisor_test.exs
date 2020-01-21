defmodule RailwayIpc.Consumer.SupervisorTest do
  use ExUnit.Case, async: true

  alias RailwayIpc.Consumer.Supervisor, as: ConsumerSupervisor

  def normalize(opts), do: Enum.sort(opts)

  describe "compile_time_config/1" do
    test "requires :broker option" do
      assert_raise ArgumentError, "missing :broker option on use RailwayIpc.Consumer", fn ->
        ConsumerSupervisor.compile_time_config([])
      end
    end

    test "requires a compiled broker" do
      assert_raise ArgumentError,
                   "broker :foo was not compiled, ensure it is correct and it is included as a project dependency",
                   fn -> ConsumerSupervisor.compile_time_config(broker: :foo) end
    end

    test "returns the otp_app and the Consumer adapter" do
      assert {:railway_ipc, RailwayIpc.TestConsumerAdapter} =
               ConsumerSupervisor.compile_time_config(broker: RailwayIpc.TestBroker)
    end
  end

  describe "start_link/5" do
    test "calls adapter.child_spec with opts and name, module and otp_app" do
      parent = self()
      opts = [parent: parent]
      use_opts = [broker: RailwayIpc.TestBroker, queue_name: "default:messages"]

      assert {:ok, pid} =
               ConsumerSupervisor.start_link(
                 RailwayIpc.TestConsumer,
                 :my_app,
                 RailwayIpc.TestConsumerAdapter,
                 use_opts,
                 opts
               )

      assert_received {RailwayIpc.TestConsumerAdapter, :child_spec, opts}

      assert [
               broker: RailwayIpc.TestBroker,
               module: RailwayIpc.TestConsumer,
               name: RailwayIpc.TestConsumer,
               otp_app: :my_app,
               parent: ^parent,
               queue_name: "default:messages"
             ] = normalize(opts)

      :ok = Supervisor.stop(pid)
    end
  end
end
