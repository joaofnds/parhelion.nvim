; extends

((jsx_closing_element
  (identifier) @parhelion.tag)
  (#set! priority 127))

((jsx_opening_element
  (identifier) @parhelion.tag)
  (#set! priority 127))

((jsx_self_closing_element
  (identifier) @parhelion.tag)
  (#set! priority 127))
