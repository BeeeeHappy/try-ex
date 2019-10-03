defmodule Otp.Worker do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  def stop(worker) do
    GenServer.call(worker, :stop)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end
end