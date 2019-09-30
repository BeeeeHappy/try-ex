defmodule Otp.CacheG do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def all do
    GenServer.call(__MODULE__, :all)
  end

  def exist?(k) do
    GenServer.call(__MODULE__, {:exist?, k})
  end

  def read(k) do
    GenServer.call(__MODULE__, {:read, k})
  end

  def write(k, v) do
    GenServer.cast(__MODULE__, {:write, k, v})
  end

  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:all, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:exist?, k}, _from, state) do
    {:reply, Map.has_key?(state, k), state}
  end

  def handle_call({:read, k}, _from, state) do
    {:reply, Map.get(state, k), state}
  end

  def handle_cast({:write, k, v}, state) do
    {:noreply, Map.put(state, k, v)}
  end

  def handle_cast(:clear, _state) do
    {:noreply, %{}}
  end
end
