using Toybox.Graphics as Gfx;

// Draws digits (and a colon / dash separator) as classic 7-segment LCD
// glyphs using plain filled rectangles, so the "segmented" look does not
// depend on any licensed font file being bundled with the app.
module SevenSegment {

    // Which of the seven segments (a..g, laid out as on a calculator)
    // are lit for each digit.
    //   a
    // f   b
    //   g
    // e   c
    //   d
    const DIGIT_SEGMENTS = {
        0 => [true,  true,  true,  true,  true,  true,  false],
        1 => [false, true,  true,  false, false, false, false],
        2 => [true,  true,  false, true,  true,  false, true ],
        3 => [true,  true,  true,  true,  false, false, true ],
        4 => [false, true,  true,  false, false, true,  true ],
        5 => [true,  false, true,  true,  false, true,  true ],
        6 => [true,  false, true,  true,  true,  true,  true ],
        7 => [true,  true,  true,  false, false, false, false],
        8 => [true,  true,  true,  true,  true,  true,  true ],
        9 => [true,  true,  true,  true,  false, true,  true ],
    };

    // Draws a single digit inside the box (x, y, w, h) using stroke
    // thickness t. Segment order in the array is [a, b, c, d, e, f, g].
    function drawDigit(dc, x, y, w, h, t, digit, color) {
        if (digit == null || !(DIGIT_SEGMENTS.hasKey(digit))) {
            return;
        }
        var segs = DIGIT_SEGMENTS.get(digit);
        var midY = y + (h / 2);
        var halfGap = t / 2;

        dc.setColor(color, Gfx.COLOR_TRANSPARENT);

        // a: top horizontal
        if (segs[0]) {
            dc.fillRectangle(x + t, y, w - (2 * t), t);
        }
        // b: top-right vertical
        if (segs[1]) {
            dc.fillRectangle(x + w - t, y + t, t, (midY - halfGap) - (y + t));
        }
        // c: bottom-right vertical
        if (segs[2]) {
            dc.fillRectangle(x + w - t, midY + halfGap, t, (y + h - t) - (midY + halfGap));
        }
        // d: bottom horizontal
        if (segs[3]) {
            dc.fillRectangle(x + t, y + h - t, w - (2 * t), t);
        }
        // e: bottom-left vertical
        if (segs[4]) {
            dc.fillRectangle(x, midY + halfGap, t, (y + h - t) - (midY + halfGap));
        }
        // f: top-left vertical
        if (segs[5]) {
            dc.fillRectangle(x, y + t, t, (midY - halfGap) - (y + t));
        }
        // g: middle horizontal
        if (segs[6]) {
            dc.fillRectangle(x + t, midY - halfGap, w - (2 * t), t);
        }
    }

    // Draws a colon (two stacked squares) inside box (x, y, w, h).
    function drawColon(dc, x, y, w, h, t, color) {
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        var size = t;
        var cx = x + (w / 2) - (size / 2);
        var topY = y + (h / 3) - (size / 2);
        var botY = y + (2 * h / 3) - (size / 2);
        dc.fillRectangle(cx, topY, size, size);
        dc.fillRectangle(cx, botY, size, size);
    }

    // Draws a short dash (e.g. date separator) vertically centered in box.
    function drawDash(dc, x, y, w, h, t, color) {
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y + (h / 2) - (t / 2), w, t);
    }

    // A digit glyph is width w, a colon/dash glyph is treated as width cw.
    // str is an array of tokens: Number (0-9), :colon, or :dash.
    function measure(str, w, cw, gap) {
        var total = 0;
        for (var i = 0; i < str.size(); i++) {
            var tok = str[i];
            if (tok instanceof Number) {
                total += w;
            } else {
                total += cw;
            }
            if (i < str.size() - 1) {
                total += gap;
            }
        }
        return total;
    }

    // Draws a left-to-right sequence of tokens (Number / :colon / :dash),
    // each digit box sized w x h with stroke thickness t, colon/dash boxes
    // sized cw x h, gap pixels between glyphs. (x, y) is the top-left of
    // the whole string.
    function drawString(dc, str, x, y, w, h, t, cw, gap, color) {
        var cursor = x;
        for (var i = 0; i < str.size(); i++) {
            var tok = str[i];
            if (tok instanceof Number) {
                drawDigit(dc, cursor, y, w, h, t, tok, color);
                cursor += w;
            } else if (tok == :colon) {
                drawColon(dc, cursor, y, cw, h, t, color);
                cursor += cw;
            } else if (tok == :dash) {
                drawDash(dc, cursor, y, cw, h, t, color);
                cursor += cw;
            }
            cursor += gap;
        }
    }

}
