defmodule Fingerart do
  @moduledoc """
  Generate OpenSSH-style fingerprint random art (The Drunken Bishop algorithm).

  This module visualizes the random walk of a "bishop" on a 17x9 chessboard based
  on the input binary (usually an SSH key fingerprint or hash). The characters in
  the output represent the number of times a specific square was visited during
  the walk.

  *   `S`: Start position
  *   `E`: End position
  *   ` `: Empty (never visited)
  *   `.`, `o`, `+`, `=`, `*`, `B`, `O`, `X`, `@`: Increasing frequency of visits

  This allows humans to easily distinguish between two long, random strings (like
  keys or hashes) by comparing their visual "art" rather than reading hex digits.
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
  Generate fingerart from a binary. Strings structured as 16 hex pairs separated by colons
  are interpreted as SSH key fingerprints. All others are handled rawly.

  ## Options

  *   `:title` - A title to display in the border (default: `""`)
  *   `:format` - Output format: `:text` (default), `:html`, or `:svg`
  *   `:color` - Boolean to enable color output (default: `false`)

  ## Examples

  Generate art from a fingerprint string:

      Fingerart.generate("fc:94:b0:c1:e5:b0:98:7c:58:43:99:76:97:ee:9f:b7") |> IO.puts()
      +-----------------+
      |       .=o.  .   |
      ...

  With a custom title and color (ANSI):

      Fingerart.generate(binary, title: "RSA 2048", color: true) |> IO.puts()

  Generate SVG for web display:

      Fingerart.generate(binary, format: :svg)
      "<svg>...</svg>"
  """
  @spec generate(binary(), keyword()) :: String.t() | {:error, String.t()}
  def generate(binary, opts \\ [])

  def generate(binary, opts) when is_binary(binary) and is_list(opts) do
    title = Keyword.get(opts, :title, "")
    format = Keyword.get(opts, :format, :text)
    color = Keyword.get(opts, :color, false)

    binary
    |> string_to_charlist()
    |> walk_from_charlist([@start_index])
    |> graph_from_walk
    |> render(format, title, color)
  end

  def generate(_, _), do: {:error, "generate/2 requires a binary"}

  defp render(graph, :text, title, color) do
    """
    #{header_line(title, color)}
    #{graph |> Tuple.to_list() |> gen_art(color)}
    #{header_line("", color)}
    """
  end

  defp render(graph, :html, title, color) do
    content =
      graph
      |> Tuple.to_list()
      |> gen_art_list(color, :html)

    """
    <pre class="fingerart">
    #{header_line_html(title, color)}
    #{content}
    #{header_line_html("", color)}
    </pre>
    """
  end

  defp render(graph, :svg, title, color) do
    lines =
      graph
      |> Tuple.to_list()
      |> Enum.chunk_every(@modulus)

    header = header_line(title, false)
    footer = header_line("", false)

    content =
      [header] ++
        Enum.map(lines, fn row -> "|" <> Enum.map_join(row, &pixel(&1)) <> "|" end) ++ [footer]

    svg_content =
      content
      |> Enum.with_index()
      |> Enum.map(fn {line, row_idx} ->
        line
        |> String.graphemes()
        |> Enum.with_index()
        |> Enum.map(fn {char, col_idx} ->
          fill = (color && color_for_char(char, :svg)) || "black"

          ~s(<text x="#{col_idx * 10}" y="#{row_idx * 15 + 15}" fill="#{fill}" font-family="monospace" font-size="14">#{char}</text>)
        end)
      end)
      |> List.flatten()
      |> Enum.join("\n")

    """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 190 180" width="190" height="180">
      <rect width="100%" height="100%" fill="white"/>
      #{svg_content}
    </svg>
    """
  end

  # Special case things which look like fingerprint strings
  def string_to_charlist(
        <<hp0::binary-2, ":", hp1::binary-2, ":", hp2::binary-2, ":", hp3::binary-2, ":",
          hp4::binary-2, ":", hp5::binary-2, ":", hp6::binary-2, ":", hp7::binary-2, ":",
          hp8::binary-2, ":", hp9::binary-2, ":", hp10::binary-2, ":", hp11::binary-2, ":",
          hp12::binary-2, ":", hp13::binary-2, ":", hp14::binary-2, ":", hp15::binary-2>>
      ) do
    [hp0, hp1, hp2, hp3, hp4, hp5, hp6, hp7, hp8, hp9, hp10, hp11, hp12, hp13, hp14, hp15]
    |> Enum.map(fn hd ->
      {v, ""} = Integer.parse(hd, 16)

      v
    end)
  end

  # Otherwise, just make it a charlist
  def string_to_charlist(binary), do: :erlang.binary_to_list(binary)

  @corner "+"
  @lineh "-"
  @linev "|"
  @obracket "["
  @cbracket "]"

  defp header_line(title, color) do
    tl = String.length(title)

    middle =
      if tl > 0 and tl <= @modulus - 2 do
        pad(@obracket <> title <> @cbracket, @lineh, :right, @modulus - (tl + 2))
      else
        String.duplicate(@lineh, @modulus)
      end

    res = @corner <> middle <> @corner
    if color, do: colorize(res, :text), else: res
  end

  defp header_line_html(title, color) do
    line = header_line(title, false)
    if color, do: colorize(line, :html), else: line
  end

  defp colorize(str, :text) do
    str
    |> String.graphemes()
    |> Enum.map_join("", fn char ->
      c = color_for_char(char, :text)
      if c, do: c <> char <> IO.ANSI.reset(), else: char
    end)
  end

  defp colorize(str, :html) do
    str
    |> String.graphemes()
    |> Enum.map_join("", fn char ->
      c = color_for_char(char, :html)
      if c, do: ~s(<span style="color: #{c}">#{char}</span>), else: char
    end)
  end

  defp color_for_char(char, format) do
    case char do
      "S" -> color_map(:green, format)
      "E" -> color_map(:red, format)
      c when c in ["+", "-", "|", "[", "]"] -> color_map(:cyan, format)
      _ -> nil
    end
  end

  defp color_map(:green, :text), do: IO.ANSI.green()
  defp color_map(:red, :text), do: IO.ANSI.red()
  defp color_map(:cyan, :text), do: IO.ANSI.cyan()

  defp color_map(:green, :html), do: "green"
  defp color_map(:red, :html), do: "red"
  defp color_map(:cyan, :html), do: "darkcyan"

  defp color_map(:green, :svg), do: "green"
  defp color_map(:red, :svg), do: "red"
  defp color_map(:cyan, :svg), do: "darkcyan"

  defp pad(str, _char, _side, 0), do: str

  defp pad(str, char, :right, n) do
    pad(str <> char, char, :left, n - 1)
  end

  defp pad(str, char, :left, n) do
    pad(char <> str, char, :right, n - 1)
  end

  defp gen_art(graph, color) do
    gen_art_rec(graph, color, 0, [])
  end

  defp gen_art_rec([], _color, _index, lines) do
    [_ | notrail] = lines
    notrail |> List.flatten() |> Enum.reverse() |> IO.iodata_to_binary()
  end

  defp gen_art_rec([ti | rest], color, 0, lines) do
    pix = pixel(ti)
    pix = if color, do: colorize(pix, :text), else: pix
    gen_art_rec(rest, color, 1, [pix | [colorize_linev(color, :text) | lines]])
  end

  defp gen_art_rec([ti | rest], color, @max_x, lines) do
    pix = pixel(ti)
    pix = if color, do: colorize(pix, :text), else: pix
    gen_art_rec(rest, color, 0, ["\n", [colorize_linev(color, :text) | [pix, lines]]])
  end

  defp gen_art_rec([ti | rest], color, n, lines) do
    pix = pixel(ti)
    pix = if color, do: colorize(pix, :text), else: pix
    gen_art_rec(rest, color, n + 1, [pix, lines])
  end

  defp gen_art_list(graph, color, format) do
    gen_art_list_rec(graph, color, format, 0, [])
  end

  defp gen_art_list_rec([], _color, _format, _index, lines) do
    [_ | notrail] = lines
    notrail |> List.flatten() |> Enum.reverse() |> Enum.join("")
  end

  defp gen_art_list_rec([ti | rest], color, format, 0, lines) do
    pix = pixel(ti)
    pix = if color, do: colorize(pix, format), else: pix
    gen_art_list_rec(rest, color, format, 1, [pix | [colorize_linev(color, format) | lines]])
  end

  defp gen_art_list_rec([ti | rest], color, format, @max_x, lines) do
    pix = pixel(ti)
    pix = if color, do: colorize(pix, format), else: pix

    gen_art_list_rec(rest, color, format, 0, [
      "\n",
      [colorize_linev(color, format) | [pix, lines]]
    ])
  end

  defp gen_art_list_rec([ti | rest], color, format, n, lines) do
    pix = pixel(ti)
    pix = if color, do: colorize(pix, format), else: pix
    gen_art_list_rec(rest, color, format, n + 1, [pix, lines])
  end

  defp colorize_linev(true, format) do
    c = color_for_char(@linev, format)

    case format do
      :text -> c <> @linev <> IO.ANSI.reset()
      :html -> ~s(<span style="color: #{c}">#{@linev}</span>)
    end
  end

  defp colorize_linev(false, _format), do: @linev

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
      if is_integer(was) and was < @max_visit do
        was + 1
      else
        was
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
