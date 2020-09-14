defmodule TestU.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end
end


# defmodule TryElixir.MixProject do
#   use Mix.Project

#   def project do
#     [
#       app: :try_elixir,
#       version: "0.1.0",
#       elixir: "~> 1.9",
#       start_permanent: Mix.env() == :prod,
#       deps: deps(),
#       dialyzer: [plt_add_apps: [:mix]]
#     ]
#   end

#   # Run "mix help compile.app" to learn about applications.
#   def application do
#     [
#       extra_applications: [:logger],
#       # mod: {Otp.Pooly, []}
#       # mod: {Otp.A, [%{foo: "bar"}]},
#       # mod: {Otp.S.A, []}
#       mod: {Otp.Test, []}
#     ]
#   end

#   # Run "mix help deps" to learn about dependencies.
#   defp deps do
#     [
#       {:monadex, "~> 1.1"},
#       {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
#     ]
#   end
# end
