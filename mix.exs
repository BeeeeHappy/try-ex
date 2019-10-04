defmodule TryElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :try_elixir,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Otp.Pooly, []},
      # mod: {Otp.A, [%{foo: "bar"}]},
      # mod: {Otp.S.A, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:monadex, "~> 1.1"},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
    ]
  end
end
