defmodule DmlRunner.Command do
  def run_command(msg, "```\n" <> rev_command) do
    command = String.reverse rev_command
    r = System.cmd("/Users/sizumita/Workspace/dml_runner/main", [command])
    case r do
      {json, 0} ->
        result = Task.async(DmlRunner.Runner, :run, [json, [DmlRunner.Converter.message(msg)], %{}])
                 |> Task.await(1000 * 3)
        Nostrum.Api.create_message(msg.channel_id, result |> Jason.encode!())
      _ ->
        Nostrum.Api.create_message(msg.channel_id, "パースに失敗しました。")
    end
  end

  def handle(%{content: "!run\n```\n" <> command} = msg) do
    run_command(msg, command |> String.reverse)
  end

  def handle(_msg) do
    :noop
  end
end
