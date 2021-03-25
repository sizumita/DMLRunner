defmodule DmlRunner.Converter do
  @struct "Struct"
  @int "Integer"
  @float "Float"
  @bool "Bool"
  @string "String"
  @unit "Unit"
  @any "'a"

  defp value(v, t) do
    %{"type" => "value", "value" => v, "t" => t}
  end

  def message(msg) do
    %{
      "id" => msg.id |> value(@int),
      "content" => msg.content |> value(@string),
    } |> value(@struct)
  end
end
