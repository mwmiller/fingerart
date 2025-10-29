defmodule Fingerart do
  @moduledoc """
  Generate OpenSSH fingerprint random art
  """
  @max_x 16
  @max_y 8
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

  @doc """
  Given a current index (0-152) and a direction (0-3) output the
  index to which the bishop steps
  """
  # Corners
  def next_step(0, dir) do
    case dir do
      0 -> 0
      1 -> 1
      2 -> 17
      3 -> 18
    end
  end

  def next_step(@max_x, dir) do
    case dir do
      0 -> @max_x - 1
      1 -> @max_x
      2 -> @max_x + 16
      3 -> @max_x + 17
    end
  end

  @bottom_left @modulus * @max_y

  def next_step(@bottom_left, dir) do
    case dir do
      0 -> @bottom_left - 17
      1 -> @bottom_left - 16
      2 -> @bottom_left
      3 -> @bottom_left + 1
    end
  end

  def next_step(@max_index, dir) do
    case dir do
      0 -> @max_index - 18
      1 -> @max_index - 17
      2 -> @max_index - 1
      3 -> @max_index
    end
  end

  # Top border
  def next_step(curr, dir) when div(curr, 17) == 0 do
    case dir do
      0 -> curr - 1
      1 -> curr + 1
      2 -> curr + 16
      3 -> curr + 18
    end
  end

  # Bottom border
  def next_step(curr, dir) when div(curr, 17) == 8 do
    case dir do
      0 -> curr - 18
      1 -> curr - 16
      2 -> curr - 1
      3 -> curr + 1
    end
  end

  # Right border
  def next_step(curr, dir) when rem(curr, 17) == 16 do
    case dir do
      0 -> curr - 18
      1 -> curr - 17
      2 -> curr + 16
      3 -> curr + 17
    end
  end

  # Left border
  def next_step(curr, dir) when rem(curr, 17) == 0 do
    case dir do
      0 -> curr - 17
      1 -> curr - 16
      2 -> curr + 17
      3 -> curr + 18
    end
  end

  # Common middle case
  def next_step(curr, dir) do
    case dir do
      0 -> curr - 18
      1 -> curr - 16
      2 -> curr + 16
      3 -> curr + 18
    end
  end
end
