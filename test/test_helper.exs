{:ok, _} = Application.ensure_all_started(:amqp)

ExUnit.configure(exclude: [:pending, :rabbitmq])
ExUnit.start()
