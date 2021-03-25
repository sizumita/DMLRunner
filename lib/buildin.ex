defmodule Buildin do
  @int "Integer"
  @float "Float"
  @bool "Bool"
  @string "String"
  @unit "Unit"
  @any "'a"

  def value(v, t) do
    %{"type" => "value", "value" => v, "t" => t}
  end

  def exec("if", [b, then, els]) do
    IO.inspect b["value"]
    if b["value"] == true do
      then
    else
      els
    end
  end

  def exec("+", [l, r]) do
    case {l["t"], r["t"]} do
      {@int, @int} -> value(l["value"] + r["value"], @int)
      {@float, @float} -> value(l["value"] + r["value"], @float)
      {@string, @string} -> value(l["value"] <> r["value"], @string)
      _ -> raise "Missing argument type"
    end
  end

  def exec("-", [l, r]) do
    case {l["t"], r["t"]} do
      {@int, @int} -> value(l["value"] - r["value"], @int)
      {@float, @float} -> value(l["value"] - r["value"], @float)
      _ -> raise "Missing argument type"
    end
  end

  def exec("*", [l, r]) do
    case {l["t"], r["t"]} do
      {@int, @int} -> value(l["value"] * r["value"], @int)
      {@float, @float} -> value(l["value"] * r["value"], @float)
      _ -> raise "Missing argument type"
    end
  end

  def exec("/", [l, r]) do
    case {l["t"], r["t"]} do
      {@int, @int} -> value(Float.floor(l["value"] / r["value"]), @int)
      {@float, @float} -> value(l["value"] / r["value"], @float)
      _ -> raise "Missing argument type"
    end
  end

  def exec("==", [l, r]) do
    value(l["value"] == r["value"], @bool)
  end

  def exec("<", [l, r]) do
    case {l["t"], r["t"]} do
      {@int, @int} -> value(l["value"] < r["value"], @bool)
      {@float, @float} -> value(l["value"] < r["value"], @bool)
      {@string, @string} -> value(l["value"] < r["value"], @bool)
      _ -> raise "Missing argument type"
    end
  end

  def exec(">", [l, r]) do
    case {l["t"], r["t"]} do
      {@int, @int} -> value(l["value"] > r["value"], @bool)
      {@float, @float} -> value(l["value"] > r["value"], @bool)
      {@string, @string} -> value(l["value"] > r["value"], @bool)
      _ -> raise "Missing argument type"
    end
  end

  def exec("<=", [l, r]) do
    case {l["t"], r["t"]} do
      {@int, @int} -> Float.floor(l["value"] <= r["value"], @bool)
      {@float, @float} -> value(l["value"] <= r["value"], @bool)
      {@string, @string} -> value(l["value"] <= r["value"], @bool)
      _ -> raise "Missing argument type"
    end
  end

  def exec(">=", [l, r]) do
    case {l["t"], r["t"]} do
      {@int, @int} -> value(l["value"] >= r["value"], @bool)
      {@float, @float} -> value(l["value"] >= r["value"], @bool)
      {@string, @string} -> value(l["value"] >= r["value"], @bool)
      _ -> raise "Missing argument type"
    end
  end

  def exec("!", [l]) do
    case l["t"] do
      @bool -> value(!l["value"], @bool)
      _ -> raise "Missing argument type"
    end
  end

  def exec("get", [%{"t" => "Struct"} = base, v]) do
    r = base["value"][v["value"]]
    if r == nil do
      raise "KeyError: " <> v["value"]
    else
      r
    end
  end

  def exec("get", [%{"type" => "name_space_var"} = base, v]) do
    %{"type" => "var", "name" => ~s/__#{base["name"]}_#{v["value"]}/, "t" => "'a"}
  end

  def exec(name, _) do
    raise "Undefined function: " <> name
  end
end
