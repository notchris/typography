import font, os, streams, strutils, tables, vmath, xmlparser, xmltree

proc readFontSvg*(f: Stream): Font =
  ## Read an SVG font from a stream.
  var font = Font()
  font.typeface = Typeface()
  font.size = 16
  font.lineHeight = 20
  font.typeface.glyphs = initTable[string, Glyph]()

  var xml = parseXml(f)

  for tag in xml.findAll "font":
    var name = tag.attr "id"
    if name.len > 0:
      font.typeface.name = name
    var advance = tag.attr "horiz-adv-x"
    if advance.len > 0:
      font.typeface.advance = parseFloat(advance)

  for tag in xml.findAll "font-face":
    var unitsPerEm = tag.attr "units-per-em"
    if unitsPerEm.len > 0:
      font.typeface.unitsPerEm = parseFloat(unitsPerEm)
    var bbox = tag.attr "bbox"
    if bbox.len > 0:
      var v = bbox.split()
      font.typeface.bboxMin = vec2(parseFloat(v[0]), parseFloat(v[1]))
      font.typeface.bboxMax = vec2(parseFloat(v[2]), parseFloat(v[3]))
    var capHeight = tag.attr "cap-height"
    if capHeight.len > 0:
      font.typeface.capHeight = parseFloat(capHeight)
    var xHeight = tag.attr "x-height"
    if xHeight.len > 0:
      font.typeface.xHeight = parseFloat(xHeight)
    var ascent = tag.attr "ascent"
    if ascent.len > 0:
      font.typeface.ascent = parseFloat(ascent)
    var descent = tag.attr "descent"
    if descent.len > 0:
      font.typeface.descent = parseFloat(descent)

  for tag in xml.findAll "glyph":
    var glyph = Glyph()
    glyph.code = tag.attr "unicode"
    let name = tag.attr "glyph-name"
    var advance = tag.attr "horiz-adv-x"
    if advance.len > 0:
      glyph.advance = parseFloat(advance)
    else:
      glyph.advance = font.typeface.advance
    glyph.path = tag.attr "d"
    if name == "space" and glyph.code == "":
      glyph.code = " "
    font.typeface.glyphs[glyph.code] = glyph

  font.typeface.kerning = initTable[(string, string), float32]()
  for tag in xml.findAll "hkern":
    var k = parseFloat tag.attr "k"
    var u1 = tag.attr "u1"
    var u2 = tag.attr "u2"
    if u1.len > 0 and u2.len > 0:
      font.typeface.kerning[(u1, u2)] = k

  return font

proc readFontSvg*(filename: string): Font =
  ## Read an SVG font from a file.
  if not fileExists(filename):
    raise newException(OSError, "File " & filename & " not found")
  var f = newFileStream(filename)
  result = readFontSvg(f)
  result.typeface.filename = filename
