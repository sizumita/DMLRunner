defmodule DmlRunner do
  @moduledoc """
  Documentation for `DmlRunner`.
  """
  @buildin ~w/+ - \/ */
  @t """
  [{"type":"assign","name":"a","value":{"type":"call","func": {"type":"fun","content":{"type":"call","func": {"type":"var","name":"+", "t":"'a"},"args":[{"type":"var","name":"b", "t":"'a"}, {"type":"value","value": 1,"t":"Integer"}]},"args":["b"]},"args":[{"type":"value","value": 2,"t":"Integer"}]}}]

  """

  def get(dict, name) do
    o = dict |> Enum.filter(fn x -> x.name == name end)
    case o do
      [] -> raise "Undefined: " <> name
      [head | _tail] -> head
    end
  end

  def expr(%{"type" => "assign"} = json, {dict, types}) do
    {[%Variable{name: json["name"], value: expr(json["value"], {dict, types})} | dict], types}
  end

  def expr(%{"type" => "value"} = json, _data) do
    json
  end

  def expr(%{"type" => "fun"} = json, _data) do
    json
  end

  def expr(%{"type" => "call", "func" => %{"type" => "var", "name" => name} = func } = json, {dict, types}) do
    if @buildin |> Enum.any?(fn x -> x == name end) do
      args = json["args"] |> Enum.map(fn x -> expr(x, {dict, types}) end)
      Buildin.exec(name, args)
    else
      func = get(dict, name).value
      new_dict = Enum.zip(func["args"], json["args"])
                 |> Enum.reduce(
                      dict,
                      fn {name, value}, acc ->
                        [ %Variable{name: name, value: expr(value, dict)} | acc ]
                      end)
      expr(func["content"], {new_dict, types})
    end
  end

  def expr(%{"type" => "block", "contents" => contents}, data) do
    r = contents |> Enum.reduce(
                  {nil, data},
    fn x, {_y, data_} ->
      case expr(x, data_) do
        {_dict, _types} = result -> {nil, result}
        v -> {v, data_}
      end
    end)

    IO.inspect r
    case r do
      {nil, _data} -> raise "Block stmt have to return value"
      {value, data}  -> expr(value, data)
    end
  end

  def expr(%{"type" => "call", "func" => %{"type" => "fun", "content" => content} = func } = json, {dict, types}) do
    new_dict = Enum.zip(func["args"], json["args"])
               |> Enum.reduce(
                    dict,
                    fn {name, value}, acc ->
                      [ %Variable{name: name, value: expr(value, dict)} | acc ]
                    end)
    expr(content, {new_dict, types})
  end

  def expr(%{"type" => "var", "name" => name}, {dict, _types}) do
    get(dict, name).value
  end

  def expr(%{"type" => "typedef", "name" => name} = json, {dict, types}) do
    {dict, Map.merge(types, TypeDef.from_json(json))}
  end

  def expr(json, dict) do
    IO.inspect json
    IO.inspect dict
    raise "unknown format"
  end

  def run do
    json = Jason.decode!(@t)
    json |> Enum.reduce({[], %{}}, fn x, acc -> expr(x, acc) end)
  end
end
