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

    <pre id="debugbox" class="hidden"><span id="debugbox_hdr" class="hdr"></span><span id="debugbox_msg" class="msg"></span></pre>

    <div id="content" class="show_tt">
      <div class="graph panel">
        <div id="rendering_note" class="hidden">
          <span id-"rendering_note_hdr">Rendering</span>
          <span id="rendering_note_value"></span>
        </div>
        <div id="graph_wrapper" class="canvas_wrapper canvas_size">
          <canvas id="graph_mandel" class="graph_canvas canvas_size" width="900" height="600">
            This requires a browser that supports the &lt;canvas&gt; tag.
          </canvas>
          <canvas id="graph_julia" class="graph_canvas canvas_size hidden" width="900" height="600">
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
          <select name="zoom_amount" id="zoom_amount" autocomplete="off">
            <option value="0.8">80%</option>
            <option value="0.6" selected="selected">60%</option>
            <option value="0.4">40%</option>
            <option value="0.2">20%</option>
          </select>
          <button id="button_zoom" class="tt ttright" data-title="Select a point to soom into.">Zoom</button>
        </div>

        <div class="tracebox buttonbox">
          <span class="title">Trace Animation</span>
          <button id="button_trace_cardioid" class="tt ttright" data-title="Start/Stop animated tracing of the orbit pointer around the main cardioid">Start</button>
          <input id="trace_slider" type="range" min="0" max="6.283185" step="any" autocomplete="off" disabled="disabled" autocomplete="off" class="tt ttright" data-title="Changes the current position along the trace path.">

          <label for="trace_path">
            <select name="trace_path" id="trace_path" autocomplete="off">
              <option value="main_cardioid" selected="selected">Main Cardioid</option>
              <option value="main_bulb">Main Bulb</option>
            </select>
          </label>
        </div>

        <div class="uioptbox buttonbox bbright">
          <span class="title">UI Options</span>
          <label for="show_tooltips" class="tt ttleft" data-title="Enable/Disable tooltips similar to what you are reading right now.">
            Show Tooltips
            <input id="show_tooltips" type="checkbox" checked="checked">
          </label>
        </div>

        <hr class="clear_both"></hr>

        <div class="coordbox optionbox obright">
          <h3>Pointer Location</h3>
          <table>
            <tr>
              <th>C =</th>
              <td><code id="loc_c" class="numfloat complex"></code></td>
            </tr>
            <tr>
              <th>r =</th>
              <td><code id="loc_radius" class="numfloat"></code></td>
            </tr>
            <tr>
              <th>&#952; =</th>
              <td><code id="loc_theta" class="numfloat"></code></td>
            </tr>
          </table>
        </div>

        <div id="orbit_options" class="optionbox obleft">
          <h3>Orbit Options</h3>
          <table>
            <tr>
              <th class="tt ttright" data-title="The number of iterations to draw when rendering an orbit.">Orbit Draw Length</th>
              <td>
                <input id="orbit_draw_length" type="number" value="200" min="0" max="1000" step="10" list="orbit_draw_length_defaults" autocomplete="off">
                <datalist id="orbit_draw_length_defaults">
                  <option value="200">200</option>
                  <option value="150">150</option>
                  <option value="100">100</option>
                  <option value="50">50</option>
                  <option value="5">5</option>
                </datalist>
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="The number of iterations to draw when rendering an orbit.">Draw Lines</th>
              <td>
                <input id="orbit_draw_lines" type="checkbox" checked="checked">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="The number of iterations to draw when rendering an orbit.">Draw Points</th>
              <td>
                <input id="orbit_draw_points" type="checkbox" checked="checked">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="The number of iterations to draw when rendering an orbit.">Point Size</th>
              <td>
                <input id="orbit_point_size" type="number" min="0" max="20" step="0.25" value="2">
              </td>
            </tr>
          </table>
        </div>

        <div id="trace_options" class="optionbox obleft">
          <h3>Trace Options</h3>
          <table>
            <tr>
              <th class="tt ttright" data-title="Show the cardioid curve that will be traced. It is a path inside the Mandelbrot Ser, very close to the edge of the main cardioid.">Highlight Trace Path</th>
              <td>
                <input id="highlight_trace_path" type="checkbox" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Show the construction of the internal angle of the cardioid. The period-n bulbs surrounding the Msndelbrot Set's ain cardioid attach at their fractional values that match their internal angle. TRe integer bulbes attach to the main cardioid at the inversse of their internal angle. E.g. the period-3 bulbs attaches at internal angles 1/3 TAU and 2/3 TAU.">Show Internal Angle</th>
              <td>
                <input id="highlight_internal_angle" type="checkbox" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Distance the trace path is moved away from the true edge of the Mandelbrot Set.">Trace Speed</th>
              <td>
                <input id="trace_speed" type="range" value="0.0016362461737446838" min="0" max="0.016362461737446838" step="any" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Distance the trace path is moved away from the true edge of the Mandelbrot Set.">Trace Edge Distance</th>
              <td>
                <input id="trace_path_edge_distance" value="0.015" autocomplete="off">
              </td>
            </tr>
          </table>
        </div>

        <div id="julia_options" class="optionbox obleft">
          <h3>Julia Options</h3>
          <table>
            <tr>
              <th class="tt ttright" data-title="Show the Julia set in a box surrounding the currently rendered Mandelbrot orbit. WARNING: significantly increasres the amount of computation that is recomputed every time the orbit changes (i.e. every time the mouse moves)">Show Nearby Julia</th>
              <td>
                <input id="julia_draw_local" type="checkbox" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Maximum iterations when rendering the Julia overlay. WARNING: Higher values significantly increase Julia rendering time!">Max Iterations</th>
              <td>
                <label for="julia_max_iterations" id="julia_max_iterations_label">60%</label>
                <input id="julia_max_iterations" type="range" value="50" min="20" max="200" step="10" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Opacity of the Julia overlay.">Opacity</th>
              <td>
                <label for="julia_local_opacity" id="julia_local_opacity_label">60%</label>
                <input id="julia_local_opacity" type="range" value="0.6" min="0" max="1" step="0.05" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Additional margin (in pixels) to render around the current orbit.">Rendering Margin</th>
              <td>
                <input id="julia_local_margin" value="55" min="0" max="50" step="5" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Maximum size (in pixels) of the height & width of the Julia rendering box.">Max Julia Size</th>
              <td>
                <input id="julia_local_max_size" value="550" min="50" max="750" step="50" autocomplete="off">
              </td>
            </tr>
          </table>
        </div>

        <div id="mandel_options" class="optionbox obleft">
          <h3>Mandelbrot Options</h3>
          <table>
            <tr>
              <th class="tt ttright" data-title="Maximum iterations when rendering the static (background) Mandelbrot fractal. Higher values significantly increase Mandelbrot rendering time, but this only happens when the page loads or you change the zoom factor. NOTE: extremely high values will not improve the quality of large zoom factors! All of the math is done using standard Javascript double precision floating point values, which have very limited precision.">Max Iterations</th>
              <td>
                <label for="mandel_max_iterations" id="mandel_max_iterations_label">60%</label>
                <input id="mandel_max_iterations" type="range" value="100" min="20" max="1000" step="20" autocomplete="off">
              </td>
            </tr>
          </table>
</div>
        <div class="clear_both"></div>
      </div>
    </div>

    <footer></footer>

    <script type="text/javascript">
undivert(`uioption.js')
undivert(`main.js')
    </script>
  </body>
</html>
