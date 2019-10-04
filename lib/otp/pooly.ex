defmodule Otp.Pooly do
  use Application

  def start(_type, _args) do
    pool_config = [worker_module: Otp.Worker, size: 5]
    start_pool(pool_config)
  end

  def start_pool(pool_config) do
    Otp.Pooly.Supervisor.start_link(pool_config)
  end

  def checkout do
    Otp.Pooly.Server.checkout
  end

  def checkin(worker_pid) do
    Otp.Pooly.Server.checkin(worker_pid)
  end

  def status do
    Otp.Pooly.Server.status
  end
end

defmodule Otp.Pooly.Supervisor do
  use Supervisor

  def start_link(pool_config) do
    Supervisor.start_link(__MODULE__, pool_config)
  end

  def init(pool_config) do
    children = [{Otp.Pooly.Server, {self(), pool_config}}]
    Supervisor.init(children, strategy: :one_for_all)
  end
end

defmodule Otp.Pooly.Server do
  use GenServer

  defmodule State do
    defstruct [:sup, :size, :worker_module, :worker_sup, :workers, :monitors]
  end

  def start_link({sup, pool_config}) do
    GenServer.start_link(__MODULE__, {sup, pool_config}, name: __MODULE__)
  end

  def state do
    GenServer.call(__MODULE__, :state)
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  def checkout do
    GenServer.call(__MODULE__, :checkout)
  end

  def checkin(worker) do
    GenServer.cast(__MODULE__, {:checkin, worker})
  end

  def init({sup, pool_config}) when is_pid(sup) do
    monitors = :ets.new(:monitors, [:private])
    init(pool_config, %State{sup: sup, monitors: monitors})
  end

  def init([{:worker_module, worker_module} | tail], state) do
    init(tail, %State{state | worker_module: worker_module})
  end

  def init([{:size, size} | tail], state) do
    init(tail, %State{state | size: size})
  end

  def init([_head | tail], state) do
    init(tail, state)
  end

  def init([], state) do
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  def handle_call(:state, _from, %State{} = state) do
    {:reply, state, state}
  end

  def handle_call(:status, _from, %State{workers: workers, monitors: monitors} = state) do
    {:reply, {length(workers), :ets.info(monitors, :size)}, state}
  end

  def handle_call(:checkout, {from_pid, _ref}, %State{workers: workers, monitors: monitors} = state) do
    case workers do
      [worker | rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}
      [] ->
        {:reply, :noproc, state}
    end
  end

  def handle_cast({:checkin, worker}, %State{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker) do
      [{worker, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, worker)
        {:noreply, %{state | workers: [worker | workers]}}
      [] ->
        {:noreply, state}
    end
  end

  def handle_info(:start_worker_supervisor, state) do
    %State{sup: sup, worker_module: worker_module, size: size} = state

    worker_sup_spec = Otp.Pooly.WorkerSupervisor.child_spec([])
    {:ok, worker_sup} = Supervisor.start_child(sup, worker_sup_spec)
    workers = prepopulate(size, {worker_sup, worker_module})

    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  defp prepopulate(size, sup_worker), do: prepopulate(size, sup_worker, [])
  defp prepopulate(size, _sup_worker, workers) when size < 1, do: workers

  defp prepopulate(size, sup_worker, workers),
    do: prepopulate(size - 1, sup_worker, [new_worker(sup_worker) | workers])

  defp new_worker({worker_sup, worker_module}) do
    {:ok, worker} = DynamicSupervisor.start_child(worker_sup, worker_module)
    worker
  end
end

defmodule Otp.Pooly.WorkerSupervisor do
  use DynamicSupervisor, restart: :temporary

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok)
  end

  def start_child(sup, worker_spec) do
    DynamicSupervisor.start_child(sup, worker_spec)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 5,
      extra_arguments: []
    )
  end
end
