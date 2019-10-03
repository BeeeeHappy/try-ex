defmodule Otp.Pooly.Supervisor do
  use Supervisor
end

defmodule Otp.Pooly.Server do
  use GenServer

  defmodule State do
    defstruct [:sup, :size, :mfa, :worker_sup, :workers]
  end

  def start_link(sup, pool_config) do
    GenServer.start_link(__MODULE__, {sup, pool_config}, name: __MODULE__)
  end

  def init({sup, pool_config}) when is_pid(sup) do
    init(pool_config, %State{sup: sup})
  end

  def init([mfa: mfa | tail], state) do
    init(tail, %State{state | mfa: mfa})
  end

  def init([size: size | tail], state) do
    init(tail, %State{state | size: size})
  end

  def init([_head | tail], state) do
    init(tail, state)
  end

  def init([], state) do
    send(self, :start_worker_supervisor)
    {:ok, state}
  end

  def handle_info(:start_worker_supervisor, state) do
    %State{sup: sup, mfa: mfa, size: size} = state
    worker_sup_spec = Supervisor.child_spec(Otp.Pooly.WorkerSupervisor, restart: :temporary)
    {:ok, worker_sup} = Supervisor.start_child(sup, worker_sup_spec)
    workers = prepopulate(size, worker_sup)
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  defp prepopulate(size, worker_sup), do: prepopulate(size, worker_sup, [])
  defp prepopulate(size, _worker_sup, workers) when size < 1, do: workers
  defp prepopulate(size, worker_sup, workers), do: prepopulate(size - 1, worker_sup, [new_worker(worker_sup) | workers])
  defp new_worker(worker_sup), do: DynamicSupervisor.start_child(worker_sup, Otp.WorkerOtp.Worker)
end

defmodule Otp.Pooly.WorkerSupervisor do
  use DynamicSupervisor

  def start_link do
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