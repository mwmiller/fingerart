defmodule Fingerart do
  @moduledoc """
  Generate OpenSSH fingerprint random art
  """
  @max_y 8
  @max_x @max_y * 2
  @modulus @max_x + 1
  @max_index @modulus * (@max_y + 1)
  @start_index div(@max_index, 2)

  @visited {" ", ".", "o", "+", "=", "*", "B", "O", "X", "@", "%", "&", "#", "/", "^"}
  @max_visit tuple_size(@visited) - 1
  @start_char "S"
  @finish_char "E"

  @doc """
  Produces fingerart from a standard SSH key fingerprint
  """
  def from_string(fpstring) do
    # This could also be done with a pattern match since we know its exact shape
    # I feel like this is better for readability

    for fph <- String.split(fpstring, ":") do
      {char, ""} = Integer.parse(fph, 16)
      char
    end
    |> walk_from_charlist([@start_index])
    |> graph_from_walk
    |> art_from_graph
  end

  defp art_from_graph(graph) do
    """
    #{header_line("")}
    #{graph |> Tuple.to_list() |> gen_art()}
    #{header_line("")}
    """
  end

  defp header_line("") do
    "+" <> String.duplicate("-", @modulus) <> "+"
  end

  defp gen_art(graph, index \\ 0, lines \\ [])

  defp gen_art([], _index, lines) do
    [_ | notrail] = lines
    notrail |> List.flatten() |> Enum.reverse() |> IO.iodata_to_binary()
  end

  defp gen_art([ti | rest], 0, lines) do
    gen_art(rest, 1, [pixel(ti) | ["|" | lines]])
  end

  defp gen_art([ti | rest], @max_x, lines) do
    gen_art(rest, 0, ["\n", ["|" | [pixel(ti), lines]]])
  end

  defp gen_art([ti | rest], n, lines) do
    gen_art(rest, n + 1, [pixel(ti), lines])
  end

  defp pixel(ti) when is_integer(ti), do: elem(@visited, ti)
  defp pixel(ta), do: ta

  defp graph_from_walk(walk) do
    # We probably already know this,
    [start | rest] = walk
    [finish | trim] = Enum.reverse(rest)
    visits = Enum.reverse(trim)

    state =
      Tuple.duplicate(0, @max_index)
      |> put_elem(start, @start_char)
      |> put_elem(finish, @finish_char)

    build_graph(visits, state)
  end

  defp build_graph([], state), do: state

  defp build_graph([i | rest], state) do
    was = elem(state, i)

    is =
      cond do
        is_integer(was) -> if was < @max_visit, do: was + 1, else: was
        true -> was
      end

    build_graph(rest, put_elem(state, i, is))
  end

  def walk_from_charlist([], walk), do: Enum.reverse(walk)

  def walk_from_charlist([char | rest], [curr | _] = walk) do
    # This is always a short (4 entry) first list
    walk_from_charlist(rest, char_steps(<<char>>, curr) ++ walk)
  end

  def char_steps(<<d4::2, d3::2, d2::2, d1::2>>, start) do
    Enum.reduce([d1, d2, d3, d4], [start], fn d, [c | _r] = a -> [next_step(c, d) | a] end)
    |> Enum.take(4)
  end

  def coords_to_index({x, y}) when x >= 0 and x <= @max_x and y >= 0 and y <= @max_y do
    x + @modulus * y
  end

  def coords_to_index(coords), do: {:error, "improper coordinates #{inspect(coords)}"}

  def index_to_coords(index) when index >= 0 and index <= @max_index do
    {rem(index, @modulus), div(index, @modulus)}
  end

  def index_to_coords(index), do: {:error, "improper index #{inspect(index)}"}

  @dir_offset %{
    ne: -1 * @modulus + 1,
    e: 1,
    se: @modulus + 1,
    s: @modulus,
    stay: 0,
    sw: @modulus - 1,
    w: -1,
    nw: -1 * @modulus - 1,
    n: -1 * @modulus
  }

  defp offset(dir), do: Map.get(@dir_offset, dir)

  @doc """
  Given a current index and a direction (0-3) output the
  index to which the bishop steps
  """
  # Corners
  def next_step(0, dir) do
    case dir do
      0 -> offset(:stay)
      1 -> offset(:e)
      2 -> offset(:s)
      3 -> offset(:se)
    end
  end

  def next_step(@max_x, dir) do
    ok =
      case dir do
        0 -> :w
        1 -> :stay
        2 -> :sw
        3 -> :s
      end

    @max_x + offset(ok)
  end

  @bottom_left @modulus * @max_y

  def next_step(@bottom_left, dir) do
    ok =
      case dir do
        0 -> :n
        1 -> :ne
        2 -> :stay
        3 -> :e
      end

    @bottom_left + offset(ok)
  end

  def next_step(@max_index, dir) do
    ok =
      case dir do
        0 -> :nw
        1 -> :n
        2 -> :w
        3 -> :stay
      end

    @max_index + offset(ok)
  end

  # Top border
  def next_step(curr, dir) when div(curr, @modulus) == 0 do
    ok =
      case dir do
        0 -> :w
        1 -> :e
        2 -> :sw
        3 -> :se
      end

    curr + offset(ok)
  end

  # Bottom border
  def next_step(curr, dir) when div(curr, @modulus) == @max_y do
    ok =
      case dir do
        0 -> :nw
        1 -> :ne
        2 -> :w
        3 -> :e
      end

    curr + offset(ok)
  end

  # Right border
  def next_step(curr, dir) when rem(curr, @modulus) == 16 do
    ok =
      case dir do
        0 -> :nw
        1 -> :n
        2 -> :sw
        3 -> :s
      end

    curr + offset(ok)
  end

  # Left border
  def next_step(curr, dir) when rem(curr, @modulus) == 0 do
    ok =
      case dir do
        0 -> :n
        1 -> :ne
        2 -> :s
        3 -> :se
      end

    curr + offset(ok)
  end

  # Common middle case
  def next_step(curr, dir) do
    ok =
      case dir do
        0 -> :nw
        1 -> :ne
        2 -> :sw
        3 -> :se
      end

    curr + offset(ok)
  end
end
