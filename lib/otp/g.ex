defmodule Otp.G do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def stack do
    GenServer.call(__MODULE__, :stack)
  end

  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  def push(item) do
    GenServer.call(__MODULE__, {:push, item})
  end

  def init(stack) when is_list(stack) do
    {:ok, stack}
  end

  def handle_call(:stack, _from, stack) do
    {:reply, stack, stack}
  end

  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  def handle_call({:push, item}, _from, stack) do
    {:reply, :ok, [item | stack]}
  end
end
