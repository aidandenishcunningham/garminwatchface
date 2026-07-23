using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Sensor as Sensor;
using Toybox.Math as Math;

const DAY_ABBREV = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];

class WatchFaceView extends Ui.WatchFace {

    var heading = null; // radians, null until the sensor reports a reading

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
    }

    function onShow() {
        Sensor.enableSensorEvents(method(:onSensorData));
    }

    function onHide() {
        Sensor.enableSensorEvents(null);
    }

    function onSensorData(sensorInfo) {
        heading = sensorInfo.heading;
        Ui.requestUpdate();
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var cy = height / 2;
        var white = Gfx.COLOR_WHITE;

        // Background
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.fillRectangle(0, 0, width, height);

        var clock = Sys.getClockTime();
        var greg = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        drawCompass(dc, width * 0.19, height * 0.19, width * 0.06, white);
        drawDayDate(dc, cx, height, greg, white);
        drawTime(dc, cx, cy, width, clock, white);
        drawBottomRow(dc, cx, width, height, white);
    }

    function drawCompass(dc, ccx, ccy, r, color) {
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(ccx, ccy, r);
        dc.setPenWidth(1);

        // Angle 0 = pointing up (north on screen). When we have a live
        // heading, rotate the needle opposite to the wrist rotation so it
        // keeps pointing at magnetic north. Until the sensor reports a
        // reading, draw it pointing straight up as a static placeholder.
        var angle = (heading == null) ? 0.0 : -heading;
        var cosA = Math.cos(angle);
        var sinA = Math.sin(angle);

        var pts = [
            [0.0, -r],
            [r * 0.22, r * 0.15],
            [0.0, r * 0.45],
            [-r * 0.22, r * 0.15]
        ];

        var poly = new [pts.size()];
        for (var i = 0; i < pts.size(); i++) {
            var px = pts[i][0];
            var py = pts[i][1];
            var rx = (px * cosA) - (py * sinA);
            var ry = (px * sinA) + (py * cosA);
            poly[i] = [ccx + rx, ccy + ry];
        }

        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(poly);
    }

    function drawDayDate(dc, cx, height, greg, color) {
        var dayName = DAY_ABBREV[greg.day_of_week - 1];

        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, height * 0.09, Gfx.FONT_SMALL, dayName,
            Gfx.TEXT_JUSTIFY_CENTER);

        // Day/month, e.g. 23-07 for 23 July.
        var w = height * 0.10;
        var h = w * 1.7;
        var t = w * 0.28;
        var cw = w * 0.55;
        var gap = w * 0.18;

        var tokens = [
            greg.day / 10, greg.day % 10,
            :dash,
            greg.month / 10, greg.month % 10
        ];

        var totalW = SevenSegment.measure(tokens, w, cw, gap);
        var x = cx - (totalW / 2);
        var y = height * 0.155;

        SevenSegment.drawString(dc, tokens, x, y, w, h, t, cw, gap, color);
    }

    function drawTime(dc, cx, cy, width, clock, color) {
        var w = width * 0.155;
        var h = width * 0.30;
        var t = width * 0.032;
        var cw = width * 0.06;
        var gap = width * 0.018;

        var tokens = [
            clock.hour / 10, clock.hour % 10,
            :colon,
            clock.min / 10, clock.min % 10
        ];

        var totalW = SevenSegment.measure(tokens, w, cw, gap);
        var x = cx - (totalW / 2);
        var y = cy - (h / 2);

        SevenSegment.drawString(dc, tokens, x, y, w, h, t, cw, gap, color);
    }

    function drawBottomRow(dc, cx, width, height, color) {
        var w = width * 0.06;
        var h = w * 1.75;
        var t = w * 0.3;
        var cw = w * 0.4;
        var gap = w * 0.22;
        var rowY = height * 0.76;
        var iconSize = w * 1.6;

        // Battery (left half)
        var battPct = (Sys.getSystemStats().battery + 0.5).toNumber();
        var battTokens = digitsOfNatural(battPct);
        var battDigitsW = SevenSegment.measure(battTokens, w, cw, gap);
        var battIconW = iconSize * 1.25; // body + nub
        var battGroupW = battIconW + (width * 0.02) + battDigitsW;
        var battX = (width * 0.30) - (battGroupW / 2);

        drawBatteryIcon(dc, battX, rowY + (h * 0.28), iconSize, iconSize * 0.55, battPct, color);
        SevenSegment.drawString(dc, battTokens, battX + battIconW + (width * 0.02), rowY, w, h, t, cw, gap, color);

        // Steps (right half)
        var steps = ActivityMonitor.getInfo().steps;
        if (steps == null) {
            steps = 0;
        }
        var stepTokens = digitsOfNatural(steps);
        var stepDigitsW = SevenSegment.measure(stepTokens, w, cw, gap);
        var stepGroupW = iconSize + (width * 0.02) + stepDigitsW;
        var stepX = (width * 0.70) - (stepGroupW / 2);

        drawStepsIcon(dc, stepX, rowY + (h * 0.1), iconSize, color);
        SevenSegment.drawString(dc, stepTokens, stepX + iconSize + (width * 0.02), rowY, w, h, t, cw, gap, color);
    }

    function drawBatteryIcon(dc, x, y, w, h, pct, color) {
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRectangle(x, y, w, h);
        dc.setPenWidth(1);
        dc.fillRectangle(x + w, y + (h * 0.3), w * 0.12, h * 0.4);

        var innerW = w - 4;
        var fillW = innerW * (pct / 100.0);
        dc.fillRectangle(x + 2, y + 2, fillW, h - 4);
    }

    function drawStepsIcon(dc, x, y, size, color) {
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y + (size * 0.35), size * 0.55, size * 0.65, size * 0.18);
        dc.fillCircle(x + (size * 0.28), y + (size * 0.15), size * 0.22);
    }

    // Returns the natural (no leading-zero padding) digit array for a
    // non-negative integer, e.g. 83 -> [8, 3], 0 -> [0].
    function digitsOfNatural(n) {
        if (n <= 0) {
            return [0];
        }
        var digits = [];
        while (n > 0) {
            digits.add(n % 10);
            n = n / 10;
        }
        var result = new [digits.size()];
        for (var i = 0; i < digits.size(); i++) {
            result[i] = digits[digits.size() - 1 - i];
        }
        return result;
    }

}
