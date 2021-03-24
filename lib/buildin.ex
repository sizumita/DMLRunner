defmodule Buildin do
  @int "Integer"
  @float "Float"
  @bool "Bool"
  @string "String"
  @unit "Unit"

  def value(v, t) do
    %{"type" => "value", "value" => v, "t" => t}
  end

  def exec("+", [l, r]) do
    case {l["t"], r["t"]} do
      {@int, @int} -> value(l["value"] + r["value"], @int)
      {@float, @float} -> value(l["value"] + r["value"], @float)
      {@string, @string} -> value(l["value"] ++ r["value"], @string)
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
end