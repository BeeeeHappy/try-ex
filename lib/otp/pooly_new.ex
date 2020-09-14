defmodule Otp.PoolyNew do
  use Application

  def start(_type, _args) do
    pools_config = [
      [name: "Pool_1", worker_mod: Otp.Worker, size: 2],
      [name: "Pool_1", worker_mod: Otp.Worker, size: 3],
      [name: "Pool_1", worker_mod: Otp.Worker, size: 4]
    ]
    start_pools(pools_config)
  end

  def start_pools(pools_config) do
    Otp.Pooly.Supervisor.start_link(pool_config)
  end

  def checkout(pool_name) do
    Otp.Pooly.Server.checkout(pool_name)
  end

  def checkin(pool_name, worker_pid) do
    Otp.Pooly.Server.checkin(pool_name, worker_pid)
  end

  def status(pool_name) do
    Otp.Pooly.Server.status(pool_name)
  end
end

defmodule Otp.Pooly.Supervisor do
  use Supervisor

  def start_link(pools_config) do
    Supervisor.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  def init(pools_config) do
    children = [
      Otp.Pooly.PoolsSupervisor,
      {Otp.Pooly.Server, pools_config}
    ]
    Supervisor.init(children, strategy: :one_for_all)
  end
end

defmodule Otp.Pooly.PoolsSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Supervisor.init([], strategy: :one_for_one)
  end
end

defmodule Otp.Pooly.Server do
  use GenServer

  def start_link(pools_config) do
    GenServer.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  def checkout(pool_name) do
    GenServer.call(:"#{pool_name}Server", :checkout)
  end

  def checkin(pool_name, worker_pid) do
    GenServer.cast(:"#{pool_name}Server", {:checkin, worker_pid})
  end

  def status(pool_name) do
    GenServer.call(:"#{pool_name}Server", :status)
  end

  def init(pools_config) do
    pools_config |> Enum.each(fn(pool_config) ->
      send(self, {:start_pool, pool_config})
    end)

    {:ok, pools_config}
  end

  def handle_info({:start_pool, pool_config}, state) do
    [name: name, worker_mod: worker_mod, size: size] = pool_config
    name = :"#{pool_config[:name]}Supervisor"
    child_spec = Supervisor.child_spec({worker_mod, {name, size}}, id: name)
    {:ok, _pool_sup} = Supervisor.start_child(Otp.Pooly.PoolsSupervisor, {worker_mod, [name, size]})
    {:noreply, state}
  end
end

defmodule Otp.Pooly.PoolSupervisor do
  use Supervisor

  def start_link({name, size} = pool_config) do
    Supervisor.start_link(__MODULE__, pool_config, name: name) 
  end

  def init(pool_config) do
    children = [
      {Otp.Pooly.PoolServer, pool_config}
    ]

    opt = [
      strategy: :one_for_all
    ]

    Supervisor.init(children, opt)
  end
end

defmodule Otp.Pooly.PoolServer do
  use GenServer
  
  defmodule State do
    defstruct [:pool_sup, :worker_sup, :size, :name, :worker_mod, :workers, :monitors]
  end

  def start_link({pool_sup, {name, size} = pool_config}) do
    GenServer.start_link(__MODULE__, {pool_sup, pool_config}, name: name(name))
  end

  def state(pool_name) do
    GenServer.call(name(pool_name), :state)
  end

  def status(pool_name) do
    GenServer.call(name(pool_name), :status)
  end

  def checkout(pool_name) do
    GenServer.call(name(pool_name), :checkout)
  end

  def checkin(pool_name, worker) do
    GenServer.cast(name(pool_name), {:checkin, worker})
  end

  def init({pool_sup, pool_config}) when is_pid(pool_sup) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    init(pool_config, %State{pool_sup: pool_sup, monitors: monitors})
  end

  def init([{:worker_mod, worker_mod} | tail], state) do
    init(tail, %State{state | worker_mod: worker_mod})
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

  def handle_call(
        :checkout,
        {from_pid, _ref},
        %State{workers: workers, monitors: monitors} = state
      ) do
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
    %State{pool_sup: pool_sup, worker_mod: worker_mod, name: name, size: size} = state

    worker_sup_spec = Otp.Pooly.WorkerSupervisor.child_spec([])
    {:ok, worker_sup} = Supervisor.start_child(name, worker_sup_spec)
    workers = prepopulate(size, {worker_sup, worker_mod})

    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  def handle_info({:DOWN, ref, _, _, _}, %State{monitors: monitors, workers: workers} = state) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] -> 
        true = :ets.delete(monitors, pid)
        new_state = %{state | workers: [pid | workers]}
        {:noreply, new_state}
      [[]] ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, pid, _reason}, %State{monitors: monitors, workers: workers, worker_sup: worker_sup, worker_mod: worker_mod} = state) do
    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_worker = new_worker({worker_sup, worker_mod})
        new_state = %{state | workers: [new_worker | workers]}
      [[]] ->
        {:noreply, state}
    end
  end

  defp name(pool_name) do
    :"#{pool_name}Server"
  end

  defp prepopulate(size, sup_worker), do: prepopulate(size, sup_worker, [])
  defp prepopulate(size, _sup_worker, workers) when size < 1, do: workers

  defp prepopulate(size, sup_worker, workers),
    do: prepopulate(size - 1, sup_worker, [new_worker(sup_worker) | workers])

  defp new_worker({worker_sup, worker_mod}) do
    {:ok, worker} = DynamicSupervisor.start_child(worker_sup, worker_mod)
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
