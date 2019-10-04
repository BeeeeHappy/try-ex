defmodule Otp.A do
  use Application

  def start(type, args) do
    type |> IO.inspect(label: "type")
    args |> IO.inspect(label: "args")
    start_worker(args)
  end

  defp start_worker(state) do
    children = [
      {Otp.Worker, [state]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
