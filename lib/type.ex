defmodule Type do
  defstruct name: "", valuetype: nil, parent: ""

  def from_json(%{"name" => name, "value" => type}, parent) do
    %Type{
      name: name,
      valuetype: type,
      parent: parent
    }
  end
end

defmodule TypeDef do
  def from_json(%{"type" => "typedef", "name" => name, "values" => values}) do
    values |> Enum.reduce(%{}, fn x, acc -> Map.merge(acc, %{x["name"] => Type.from_json(x, name)}) end)
  end
end
