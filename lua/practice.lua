--[[ practice.lua
   Registers an unnumbered "Practice." environment for bookdown HTML output.
   Usage in any chapter:
       ::: {.practice}
       ...student-facing prompt...
       :::
   The filter inserts an italic "Practice." label as real inline content
   (not a CSS pseudo-label), so it behaves like bookdown's built-in
   ::: {.remark} box. Pair with the div.practice style in custom.css.
   This is HTML-only on purpose; PDF support would need a \newtheorem*
   {practice}{Practice} preamble (not wired here).
]]
local function has_class(classes, cls)
  for _, c in ipairs(classes) do
    if c == cls then return true end
  end
  return false
end

Div = function(div)
  if not has_class(div.classes, "practice") then
    return nil
  end

  if FORMAT:match("html") or FORMAT:match("slidy") then
    local label = pandoc.Span({
      pandoc.Strong(pandoc.Str("Practice")),
      pandoc.Str("."),
      pandoc.Space()
    }, pandoc.Attr("", {"practice-label"}))

    if #div.content > 0 and div.content[1].t == "Para" then
      table.insert(div.content[1].content, 1, label)
    else
      table.insert(div.content, 1, pandoc.Para({label}))
    end

    return div
  end

  return nil
end
