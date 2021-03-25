defmodule DmlRunner do
  @moduledoc """
  Documentation for `DmlRunner`.
  """
  @buildin ~w/+ - \/ */

  def get(dict, name) do
    o = dict |> Enum.filter(fn x -> x.name == name end)
    case o do
      [] -> raise "Undefined: " <> name
      [head | _tail] -> head
    end
  end

  def expr(%{"type" => "assign"} = json, {dict, _types}) do
    [ %Variable{name: json["name"], value: expr(json["value"], dict)} | dict ]
  end

  def expr(%{"type" => "value"} = json, _data) do
    json
  end

  def expr(%{"type" => "fun"} = json, _data) do
    json
  end

  def expr(%{"type" => "call", "func" => %{"type" => "var", "name" => name} = func } = json, {dict, _types}) do
    if @buildin |> Enum.any?(fn x -> x == name end) do
      args = json["args"] |> Enum.map(fn x -> expr(x, dict) end)
      Buildin.exec(name, args)
    else
      func = get(dict, name).value
      new_dict = Enum.zip(func["args"], json["args"])
                 |> Enum.reduce(
                      dict,
                      fn {name, value}, acc ->
                        [ %Variable{name: name, value: expr(value, dict)} | acc ]
                      end)
      expr(func["content"], new_dict)
    end
  end

  def expr(%{"type" => "call", "func" => %{"type" => "fun"} = func, "content" => content} = json, {dict, _types}) do
    new_dict = Enum.zip(func["args"], json["args"])
               |> Enum.reduce(
                    dict,
                    fn {name, value}, acc ->
                      [ %Variable{name: name, value: expr(value, dict)} | acc ]
                    end)
    expr(content, new_dict)
  end

  def expr(%{"type" => "var", "name" => name}, {dict, _types}) do
    get(dict, name).value
  end

  def expr(%{"type" => "typedef", "name" => name} = json, {dict, types}) do
    {dict, Map.merge(types, TypeDef.from_json(json))}
  end

  def expr(json, _dict) do
    json
  end

  def run(raw) do
    json = Jason.decode!(raw)
    json |> Enum.reduce({[], %{}}, fn x, acc -> expr(x, acc) end)
  end
end
