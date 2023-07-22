<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Mandelbrot Iterations</title>
    <style type="text/css" media="screen">
undivert(`basic.css')
    </style>
    <style type="text/css" media="screen" title="app_stylesheet">
undivert(`style.css')
    </style>
  </head>
  <body>
    <header>
      <h1>Mandelbrot Iterations</h1>
    </header>

    <pre id="debugbox" class="hidden"><span class="hdr"></span><span class="msg"></span></pre>

    <div id="content" class="show_tt">
      <div class="graph panel">
        <div id="graph_wrapper" class="canvas_wrapper canvas_size">
          <canvas id="graph" class="graph_canvas canvas_size" width="900" height="600">
            This requires a browser that supports the &lt;canvas&gt; tag.
          </canvas>
          <canvas id="graph_ui" class="graph_canvas canvas_size" width="900" height="600">
            This requires a browser that supports the &lt;canvas&gt; tag.
          </canvas>
        </div>
      </div>

      <div class="ui panel">
        <div class="zoombox buttonbox">
          <spasn class="title">Zoom</span>
          <button id="button_reset" class="tt ttright" data-title="Reset back to original non-zoomed view.">Reset</button>
          <select name="zoom_amount" id="zoom_amount">
            <option value="0.8">80%</option>
            <option value="0.6" selected="selected">60%</option>
            <option value="0.4">40%</option>
            <option value="0.2">20%</option>
          </select>
          <button id="button_zoom" class="tt ttleft" data-title="Select a point to soom into.">Zoom</button>
        </div>

        <div class="tracebox buttonbox">
          <span class="title">Trace Animation</span>
          <button id="button_trace_cardioid" class="tt ttright" data-title="Start/Stop animated tracing of the orbit pointer around the main cardioid">Start</button>
        </div>

        <div class="uioptbox buttonbox bbright">
          <span class="title tt ttleft">UI Options</span>
          <label for="show_tooltips" class="tt ttleft" data-title="Enable/Disable tooltips similar to what you are reading right now.">
            Show Tooltips
            <input id="show_tooltips" type="checkbox" checked="checked">
          </label>
        </div>

        <hr class="clear_both"></hr>

        <div class="optionbox obleft">
          <h3>Optional Features</h3>
          <table>
            <tr>
              <th>Highlight Trace Path</th>
              <td id="tt ttright" data-title="Show the cardioid curve that will be traced. It is a path inside the Mandelbrot Ser, very close to the edge of thej main cardioid.">
                <input id="highlight_trace_path" type="checkbox">
              </td>
            </tr>
            <tr>
              <th clasa="tt ttright" data-title="Show the construction of the internal angle of the cardioid. The period-n bulbs surrounding the Msndelbrot Set's ain cardioid attach at their fractional values that match their internal angle. TRe integer bulbes attach to the main cardioid at the inversse of their internal angle. E.g. the period-3 bulbs attaches at internal angles 1/3 TAU and 2/3 TAU.">Show Internal Ang;e</th>
              <td>
                <input id="highlight_internal_angle" type="checkbox">
              </td>
            </tr>
            <tr>
          </table>
        </div>

        <div class="clear_both"></div>
      </div>
    </div>

    <footer></footer>

    <script type="text/javascript">
undivert(`main.js')
    </script>
  </body>
</html>
