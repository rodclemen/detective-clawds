import Foundation

/// Superman's S-shield on a 28×26 canvas, for the menu bar: the five-sided diamond with a red S on yellow inside a
/// red border. `mono`: one colour with the yellow parts left out, for a template image macOS tints, so the S reads
/// as the shape and the yellow as holes in it.
func drawMenuBarShield(_ c: PixelCanvas, mono: Bool = false) {
    let red = mono ? C(0x000000) : C(0xD01C24), yellow = mono ? nil : C(0xFFD21E)
    // The S joins the border at the top right and bottom left, as on the real shield, so the mono shape stays in
    // one piece and the yellow falls out as four holes.
    let rows: [String] = [
        ".....RRRRRRRRRRRRRRRRRR.....",
        "....RRRRRRRRRRRRRRRRRRRR....",
        "...RRRYYYYYYYYYYYYYYYYRRR...",
        "..RRRYYYYRRRRRRRRRRRRRRRRR..",
        ".RRRYYYRRRRRRRRRRRRRRRRRRRR.",
        "RRRYYRRRRYYYYYYYYYYYYYYYYRRR",
        "RRRYYRRRYYYYYYYYYYYYYYYYYRRR",
        ".RRYYRRRRYYYYYYYYYYYYYYYYRR.",
        ".RRRYYRRRRRRRRRRRRRRYYYYRRR.",
        "..RRRYYYRRRRRRRRRRRRRRYRRR..",
        "...RRRYYYYYYYYYYYYYRRRRRR...",
        "....RRYYYYYYYYYYYYYYRRRR....",
        "....RRRYYYYYYYYYYYYRRRRR....",
        ".....RRRRRRRRRRRRRRRRRR.....",
        "......RRRRRRRRRRRRRRRR......",
        "......RRRYYYYYYYYYYRRR......",
        ".......RRRYYYYYYYYRRR.......",
        "........RRYYYYYYYYRR........",
        "........RRRYYYYYYRRR........",
        ".........RRRYYYYRRR.........",
        "..........RRRYYRRR..........",
        "...........RRYYRR...........",
        "...........RRRRRR...........",
        "............RRRR............",
        ".............RR.............",
    ]
    var palette: [Character: Px] = ["R": red]
    if let yellow { palette["Y"] = yellow }
    c.pattern(0, 0, rows, palette)
}
