defmodule RegressionsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @cowboy_readme """
  Cowboy
  ======

  Cowboy is a small, fast and modular HTTP server written in Erlang.

  Goals
  -----

  Cowboy aims to provide a **complete** HTTP stack in a **small** code base.
  It is optimized for **low latency** and **low memory usage**, in part
  because it uses **binary strings**.

  Cowboy provides **routing** capabilities, selectively dispatching requests
  to handlers written in Erlang.

  Because it uses Ranch for managing connections, Cowboy can easily be
  **embedded** in any other application.

  No parameterized module. No process dictionary. **Clean** Erlang code.

  Sponsors
  --------

  The SPDY implementation was sponsored by
  [LeoFS Cloud Storage](http://www.leofs.org).

  The project is currently sponsored by
  [Kato.im](https://kato.im).

  Online documentation
  --------------------

   *  [User guide](http://ninenines.eu/docs/en/cowboy/HEAD/guide)
   *  [Function reference](http://ninenines.eu/docs/en/cowboy/HEAD/manual)

  Offline documentation
  ---------------------

   *  While still online, run `make docs`
   *  Function reference man pages available in `doc/man3/` and `doc/man7/`
   *  Run `make install-docs` to install man pages on your system
   *  Full documentation in Markdown available in `doc/markdown/`
   *  Examples available in `examples/`

  Getting help
  ------------

   *  Official IRC Channel: #ninenines on irc.freenode.net
   *  [Mailing Lists](http://lists.ninenines.eu)
   *  [Commercial Support](http://ninenines.eu/support)
  """

  test "rendering the Cowboy webserver README" do
    Earmark.to_html @cowboy_readme
  end

  @issue_12 """
    iex> {:ambiguous, am} = Kalends
    {:error, :no_matches}
  """  

  test "Issue https://github.com/pragdave/earmark/issues/12" do
    alias Earmark.Options
    result = catch_error(Earmark.to_html @issue_12, %Options{mapper: &Enum.map/2})
    assert result.message == "Invalid Markdown attributes: {error, :no_matches}"
  end

  test "Issue https://github.com/pragdave/earmark/issues/17" do
    assert capture_io( :stderr, fn->
      Earmark.to_html "A\nB\n="
    end) == "Unexpected line =\n"
  end

  @indented_list """
    Para

    1. l1

    2. l2
  """

  test "Issue https://github.com/pragdave/earmark/issues/13" do
    result = Earmark.to_html @indented_list
    assert result == """
                     <p>  Para</p>
                     <ol>
                     <li><p>l1</p>
                     </li>
                     <li>l2
                     </li>
                     </ol>
                     """
  end

  @code_blocks_escape """
      escape("Hello <world>")
      "Hello &lt;world&gt;"
  """

  test "Issue https://github.com/pragdave/earmark/issues/21" do
    result = Earmark.to_html @code_blocks_escape
    assert result == """
                     <pre><code>escape(&quot;Hello &lt;world&gt;&quot;)
                     &quot;Hello &amp;lt;world&amp;gt;&quot;</code></pre>
                     """
  end

  @heading_inline_render """
  # Hello _World_
  """
  test "Issue https://github.com/pragdave/earmark/issues/30" do
    result = Earmark.to_html @heading_inline_render
    assert result == """
                     <h1>Hello <em>World</em></h1>
                     """
  end

  @implicit_list_with_bar """
  - alpha
  beta | gamma
  """
  test "Issue https://github.com/pragdave/earmark/issues/37" do
    result = Earmark.to_html @implicit_list_with_bar
    assert result == """
                     <ul>
                     <li>alpha\nbeta | gamma
                     </li>
                     </ul>
                     """
  end

  @not_the_first_you_see "<alpha<beta></beta>"
  test "Issue https://github.com/pragdave/earmark/issues/40" do
    result = Earmark.to_html @not_the_first_you_see
    assert result == "<p>&lt;alpha<beta></beta></p>\n"
  end


  test "https://github.com/pragdave/earmark/issues/41" do
    result = Earmark.to_html "****"
    assert result == ~s[<hr class="thick"/>\n]
  end

  @indented_code_block """
                  alpha
              beta
          """
  test "https://github.com/pragdave/earmark/issues/43" do
    result = Earmark.to_html @indented_code_block
    assert result == ~s[<pre><code>    alpha\nbeta</code></pre>\n]
  end

  @i48_multiline_inline_code """
  `a
  * b`
  """
  test "https://github.com/pragdave/earmark/issues/48 (1)" do
    result = Earmark.to_html @i48_multiline_inline_code
    assert result == ~s[<p><code class="inline">a\n* b</code></p>\n]
  end

  @i48_multiline_code_in_list """
  * `a
  * b`
  """
  test "https://github.com/pragdave/earmark/issues/48 (2)" do
    result = Earmark.to_html @i48_multiline_code_in_list
    assert result == ~s[<ul>\n<li><code class="inline">a\n* b</code>\n</li>\n</ul>\n]
  end

  @i50_inline_code_in_list_item """
  + ```escape```
  """
  test "https://github.com/pragdave/earmark/issues/50" do
    result = Earmark.to_html @i50_inline_code_in_list_item
    assert result == ~s[<ul>\n<li><code class="inline">escape</code>\n</li>\n</ul>\n]
  end

  @i51_not_a_fenced_block """
  ```elixir ```
  """
  test "https://github.com/pragdave/earmark/issues/51" do
    result = Earmark.to_html @i51_not_a_fenced_block
    assert result == ~s[<p><code class=\"inline\">elixir</code></p>\n]
  end


  @url_to_validate """
  [<<>>/1](http://elixir-lang.org/docs/master/elixir/Kernel.SpecialForms.htm#<<>>/1)
  """

  @code_block_to_validate """
  ```elixir
  term < term :: boolean
  ```
  """

  @code_inline_to_validate """
  `term < term :: boolean`
  """

  test"Escape html in text different than in url" do
    result = Earmark.to_html @url_to_validate
    assert result == """
    <p><a href="http://elixir-lang.org/docs/master/elixir/Kernel.SpecialForms.htm#%3C%3C%3E%3E/1">&lt;&lt;&gt;&gt;/1</a></p>
    """

    result = Earmark.to_html @code_block_to_validate
    assert result == """
    <pre><code class="elixir">term &lt; term :: boolean</code></pre>
    """

    result = Earmark.to_html "[&expr/1](http://elixir-lang.org/docs/master/elixir/Kernel.SpecialForms.htm#&expr/1)"
    assert result == """
    <p><a href="http://elixir-lang.org/docs/master/elixir/Kernel.SpecialForms.htm#&amp;expr/1">&amp;expr/1</a></p>
    """
  end

end
