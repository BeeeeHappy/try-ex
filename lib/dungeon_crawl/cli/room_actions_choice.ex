defmodule DungeonCrawl.CLI.RoomActionsChoice do
  alias Mix.Shell.IO, as: Shell

  import DungeonCrawl.CLI.BaseCommands

  def start(room) do
    Shell.info(room.description())

    room_actions = room.actions

    find_action_by_index = &Enum.at(room_actions, &1)

    chosen_action =
      room_actions
      |> display_options
      |> generate_question
      |> Shell.prompt()
      |> parse_answer
      |> find_action_by_index.()

    {room, chosen_action}
  end
end
