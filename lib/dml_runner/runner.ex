defmodule DmlRunner.Runner do
  @moduledoc """
  Documentation for `DmlRunner`.
  """
  @buildin ~w/+ - \/ * get = > < >= <= ! exit/

  def get(dict, name) do
    o = dict |> Enum.filter(fn x -> x.name == name end)
    case o do
      [] -> raise "Undefined: " <> name
      [head | _tail] -> head
    end
  end

  def expr(%{"type" => "assign"} = json, {dict, types, info}) do
    {[%Variable{name: json["name"], value: expr(json["value"], {dict, types, info})} | dict], types, info}
  end

  def expr(%{"type" => "value"} = json, _data) do
    # TODO tがStructだった時に定義されている構造体かどうかをみる
    json
  end

  def expr(%{"type" => "fun"} = json, _data) do
    json
  end

  def expr(%{"type" => "call", "func" => %{"type" => "var", "name" => "__" <> name}} = json, {_dict, _types, info} = data) do
    args = json["args"] |> Enum.map(fn x -> expr(x, data) end)
    Buildin.exec(name, args, info)
  end

  def expr(%{"type" => "call", "func" => %{"type" => "var", "name" => "if"}} = json, data) do
    [formula, then, els] = json["args"]
    result = expr(formula, data)
    case result["type"] do
      "value" ->
        if result["value"] == true do
          expr(then, data)
        else
          expr(els, data)
        end
      _ -> raise "missing value type"
    end
  end

  def expr(%{"type" => "call", "func" => %{"type" => "var", "name" => name} = func } = json, {dict, types, info}) do
    if @buildin |> Enum.any?(fn x -> x == name end) do
      args = json["args"] |> Enum.map(fn x -> expr(x, {dict, types, info}) end)
      Buildin.exec(name, args, info)
    else
      func = get(dict, name).value
      new_dict = Enum.zip(func["args"], json["args"])
                 |> Enum.reduce(
                      dict,
                      fn {name, value}, acc ->
                        [ %Variable{name: name, value: expr(value, {dict, types, info})} | acc ]
                      end)
      expr(func["content"], {new_dict, types, info})
    end
  end

  def expr(%{"type" => "call", "func" => %{"type" => "fun", "content" => content} = func } = json, {dict, types, info}) do
    IO.inspect json
    IO.inspect json["args"]
    new_dict = Enum.zip(func["args"], json["args"])
               |> Enum.reduce(
                    dict,
                    fn {name, value}, acc ->
                      [ %Variable{name: name, value: expr(value, {dict, types, info})} | acc ]
                    end)
    expr(content, {new_dict, types, info})
  end

  def expr(%{"type" => "call", "func" => func, "args" => args} = json, data) do
    expr(%{"type" => "call", "func" => expr(func, data), "args" => args}, data)
  end

  def expr(%{"type" => "block", "contents" => contents}, data) do
    r = contents |> Enum.reduce(
                      {nil, data},
                      fn x, {_y, data_} ->
                        case expr(x, data_) do
                          {_dict, _types, _info} = result -> {nil, result}
                          v -> {v, data_}
                        end
                      end)

    case r do
      {nil, _data} -> raise "Block stmt have to return value"
      {value, data}  -> expr(value, data)
    end
  end

  def expr(%{"type" => "var", "name" => name}, {dict, _types, _info}) do
    get(dict, name).value
  end

  def expr(%{"type" => "name_space_var"} = json, {dict, _types, _info}) do
    json
  end

  def expr(%{"type" => "typedef", "name" => name} = json, {dict, types, _info}) do
    {dict, Map.merge(types, TypeDef.from_json(json))}
  end

  def expr(json, dict) do
#    IO.inspect json
#    IO.inspect dict
    raise "unknown format"
  end

  def run(raw, args, info) do
    try do
      json = Jason.decode!(raw)
      {dict, types, info} = json |> Enum.reduce({[], %{}, info}, fn x, acc -> expr(x, acc) end)
      main = get(dict, "main").value
      expr(%{"type" => "call", "func" => main, "args" => args}, {dict, types, info})
    catch
      x -> :error
    end
  end
end
