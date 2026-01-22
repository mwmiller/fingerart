defmodule FingerartTest do
  use ExUnit.Case
  doctest Fingerart

  describe "generate" do
    test "from SSH key fingerprint string" do
      expect = """
      +-----------------+
      |       .=o.  .   |
      |     . *+*. o    |
      |      =.*..o     |
      |       o + ..    |
      |        S o.     |
      |         o  .    |
      |          .  . . |
      |              o .|
      |               E.|
      +-----------------+
      """

      assert expect ==
               Fingerart.generate("fc:94:b0:c1:e5:b0:98:7c:58:43:99:76:97:ee:9f:b7")
    end

    test "from SSH key hash binary" do
      expect = """
      +-----------------+
      |       .=o.  .   |
      |     . *+*. o    |
      |      =.*..o     |
      |       o + ..    |
      |        S o.     |
      |         o  .    |
      |          .  . . |
      |              o .|
      |               E.|
      +-----------------+
      """

      assert expect ==
               Fingerart.generate(
                 <<252, 148, 176, 193, 229, 176, 152, 124, 88, 67, 153, 118, 151, 238, 159, 183>>
               )
    end

    test "on under 128 bits" do
      expect = """
      +-----------------+
      |                 |
      |                 |
      |                 |
      |       .         |
      |        S        |
      |         . .     |
      |          +      |
      |           o     |
      |          E..    |
      +-----------------+
      """

      assert expect == Fingerart.generate(<<252, 147, 175>>)
    end

    test "on over 128 bits" do
      expect = """
      +-----------------+
      |^^Bo.            |
      |^=*+ .           |
      |o*o . .          |
      |.. . . .         |
      |  . .   S        |
      |  ...            |
      |oo.o . .         |
      |+o. . ...        |
      |o     .oE        |
      +-----------------+
      """

      assert expect ==
               Fingerart.generate(
                 <<0, 10, 2, 31, 4, 52, 6, 73, 8, 94, 10, 16, 22, 37, 48, 100, 110, 112, 131, 114,
                   152, 126, 173, 138, 194, 210, 116, 222, 237, 248>>
               )
    end

    test "with title" do
      expect = """
      +---[nonsense]----+
      |       .=o.  .   |
      |     . *+*. o    |
      |      =.*..o     |
      |       o + ..    |
      |        S o.     |
      |         o  .    |
      |          .  . . |
      |              o .|
      |               E.|
      +-----------------+
      """

      assert expect ==
               Fingerart.generate(
                 <<252, 148, 176, 193, 229, 176, 152, 124, 88, 67, 153, 118, 151, 238, 159, 183>>,
                 title: "nonsense"
               )
    end

    test "with color (text)" do
      result = Fingerart.generate(<<252, 147, 175>>, color: true)
      # Check for some ANSI codes (Cyan for border, Green for S, Red for E)
      assert result =~ "\e[36m"
      assert result =~ "\e[32mS"
      assert result =~ "\e[31mE"
    end

    test "format: :html" do
      result = Fingerart.generate(<<252, 147, 175>>, format: :html)
      assert result =~ "<pre"
      assert result =~ "+-----------------+"
      assert result =~ "|        S        |"
    end

    test "format: :html with color" do
      result = Fingerart.generate(<<252, 147, 175>>, format: :html, color: true)
      assert result =~ "<span style=\"color: darkcyan\">+</span>"
      assert result =~ "<span style=\"color: green\">S</span>"
    end

    test "format: :svg" do
      result = Fingerart.generate(<<252, 147, 175>>, format: :svg)
      assert result =~ "<svg"
      assert result =~ "viewBox=\"0 0 190 180\""
      assert result =~ "fill=\"black\""
    end

    test "format: :svg with color" do
      result = Fingerart.generate(<<252, 147, 175>>, format: :svg, color: true)
      assert result =~ "fill=\"green\""
      assert result =~ ">S</text>"
      assert result =~ "fill=\"darkcyan\""
    end
  end
end
