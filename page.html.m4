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
          <span id="rendering_note_hdr">Rendering</span>
          <span id="rendering_note_value"></span>
          <progress id="rendering_note_progress" max="100" value="0">0%</progress>
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
        </div>

        <div class="uioptbox buttonbox label">
          <span class="title">Status</span>
          <div id="status" class="loading">
            <span class="statusmsg loading">Loading...</span>
            <span class="statusmsg rendering">Rendering</span>
            <span class="statusmsg normal">Ok</span>
            <span class="statusmsg paused">Paused</span>
          </div>
        </div>

        <div id="msgbox" class="buttonbox label hidden">
          <span id="msg"></span>
        </div>

        <hr id="buttonbox_hr" class="clear_both"></hr>

        <div class="coordbox optionbox obright">
          <h3 class="collapse_header" data-collapse_hide="pointer_location_table" data-collapse_show="pointer_location_hr">Pointer Location</h3>
          <table id="pointer_location_table">
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
            <tr>
              <th></th>
              <td>
                <button id="copy_loc_to_set_c">&darr; Copy To Set C &darr;</button>
                <button id="save_loc">Save &darr;</button>
              </td>
            </tr>
            <tr>
              <th colspan="2">&nbsp;</th>
            </tr>
            <tr>
              <th class="tt ttleft" data-title="Set the real part of the cursor position C.">Real</th>
              <td><input id="set_c_real" value="0"></td>
            </tr>
            <tr>
              <th class="tt ttleft" data-title="Set the imaginary part of the cursor position C. NOTE: the i axis is reversed from normal; the positive i direction is down.">Imag</th>
              <td><input id="set_c_imag" value="0"><span id="set_c_imag_i">i</span></td>
            </tr>
            <tr>
              <th></th>
              <td>  
                <button id="set_c">Set C</button>
                <button id="save_c">Save &darr;</button>
              </td>
            </tr>
          </table>
          <hr id="pointer_location_hr" class="clear_both hidden collapse_hr"></hr>

          <div class="tabs">
            <div class="tabheader">
              <button id="highlights_tab_button" class="tabbutton active">Highlights</label>
              <button id="saved_locations_tab_button" class="tabbutton">Saved Locations</label>
            </div>

            <div id="highlights_tab" class="tabpanel active">
              <div id="highlight_header">
                <button id="highlight_prev" class="invis">&larr;</button>
                <select name="highlight_group" id="highlight_group" autocomplete="off">
                  <option value="0" selected="selected">&darr; Group &darr;</option>
                </select>
                <button id="highlight_next" class="invis">&rarr;</button>
              </div>
              <ol id="highlight_list" class="invis">
              </ol>
            </div>

            <div id="saved_locations_tab" class="tabpanel">
              <table id="saved_locations">
                <thead>
                  <th>Name</th>
                  <th>Real</th>
                  <th>Imag</th>
                  <th></th>
                </thead>
                <tbody id="saved_locations_body">
                </tbody>
              </table>
              <div id="saved_location_buttons">
                <button id="save_to_file">Save To File</button>
                <input id="load_from_file_input" class="hidden" type="file" accept=".json" />
                <button id="load_from_file">Load From File</button>
              </div>
            </div>
          </div>
        </div>

        <div id="orbit_options" class="optionbox obleft">
          <h3 class="collapse_header" data-collapse_hide="orbit_options_table" data-collapse_show="orbit_options_hr">Orbit Options</h3>
          <table id="orbit_options_table" class="collapse_target">
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
                <input id="orbit_draw_lines" type="checkbox" checked="checked" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="The number of iterations to draw when rendering an orbit.">Draw Points</th>
              <td>
                <input id="orbit_draw_points" type="checkbox" checked="checked" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="The number of iterations to draw when rendering an orbit.">Point Size</th>
              <td>
                <input id="orbit_point_size" type="number" min="0" max="20" step="0.25" value="2" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Skip the first few results when drawing orbits.">Skip Initial<br />Iterations</th>
              <td>
                <input id="orbit_skip_initial_results" type="checkbox" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="The number of iterations to skip when Skip Initial Iterations is active.">Skip Size</th>
              <td>
                <input id="orbit_skip_initial_num" type="number" min="0" max="100" step="10" value="20" autocomplete="off">
              </td>
            </tr>
	    <tr>
              <th>Cursor Color</th>
              <td>
                <select name="cursor_color" id="cursor_color" autocomplete="off"></select>
              </td>
            </tr>
          </table>
          <hr id="orbit_options_hr" class="clear_both hidden collapse_hr"></hr>

          <h3 class="collapse_header" data-collapse_hide="trace_options_table" data-collapse_show="trace_options_hr">Trace Options</h3>
          <table id="trace_options_table" class="collapse_target">
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
              <td class="slider">
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
          <hr id="trace_options_hr" class="clear_both hidden collapse_hr"></hr>

          <h3 class="collapse_header" data-collapse_hide="ui_options_table" data-collapse_show="ui_options_hr">UI Options</h3>
          <table id="ui_options_table" class="collapse_target">
            <tr class="hidden">
              <th class="tt ttright" data-title="Cursor movement step size for each arrow key keypress. Useful for fine-tuning the cursor more accurately than the mouse. Holding <shift>, <ctrl>, or <alt> slows down movement. <shift> slows the least, <alt> slows the most.">Step</th>
              <td>
                <input id="keyboard_step" class="hidden" type="number" value="0.1" min="0.05" max="1.0" step="0.05">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Enable/Disable tooltips similar to what you are reading right now.">Show Tooltips</th>
              <td>
                <input id="show_tooltips" type="checkbox" checked="checked">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Confirm with a popup box when removing saved locations.">Confirm Removing<br />Saved Locations</th>
              <td>
                <input id="confirm_remove_saved_loc" type="checkbox" checked="checked">
              </td>
            </tr>
          </table>
          <hr id="ui_options_hr" class="clear_both hidden collapse_hr"></hr>
        </div>

        <div id="julia_options" class="optionbox obleft">
          <h3 class="collapse_header" data-collapse_hide="julia_options_table" data-collapse_show="julia_options_hr">Julia Options</h3>
          <table id="julia_options_table" class="collapse_target">
            <tr>
              <th class="tt ttright" data-title="Show the Julia set in a box surrounding the currently rendered Mandelbrot orbit. WARNING: significantly increasres the amount of computation that is recomputed every time the orbit changes (i.e. every time the mouse moves)">Show Nearby Julia</th>
              <td>
                <input id="julia_draw_local" type="checkbox" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Maximum iterations when rendering the Julia overlay. WARNING: Higher values significantly increase Julia rendering time!">Max Iterations</th>
              <td class="slider">
                <label for="julia_max_iterations" id="julia_max_iterations_label">120</label>
                <input id="julia_max_iterations" type="range" value="80" min="20" max="250" step="10" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Antialias the Julia set rendering by oversampling each pixel. Only active in the higher resolution (paused) mode. WARNING: gets VERY expensive very quickly!">Antialias</th>
              <td>
                <select name="julia_antialias" id="julia_antialias" autocomplete="off">
                  <option value="1" selected="selected">Disabled</option>
                  <option value="2">2 x 2</option>
                  <option value="3">3 x 3</option>
                </select>
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Alternative maximum iterations to use when paused (by clicking or pressing space) (anything over 500 is probably beyond the precision of Javascript double precision floating point math)">Max Iter When Paused</th>
              <td class="slider">
                <label for="julia_max_iter_paused" id="julia_max_iter_paused_label">200</label>
                <input id="julia_max_iter_paused" type="range" value="350" min="50" max="2500" step="50" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Expand Rendering of the Julia set to the entire window when paused (by clicking or pressing space)">Show More When Paused</th>
              <td>
                <input id="julia_more_when_paused" type="checkbox" autocomplete="off" checked="checked">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Opacity of the Julia overlay.">Opacity</th>
              <td class="slider">
                <label for="julia_local_opacity" id="julia_local_opacity_label">60%</label>
                <input id="julia_local_opacity" type="range" value="0.65" min="0" max="1" step="0.05" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Opacity of the Julia overlay.">Pixel Size</th>
              <td class="slider">
                <label for="julia_local_pixel_size" id="julia_local_pixel_size_label">3x</label>
                <input id="julia_local_pixel_size" type="range" value="3" min="1" max="4" step="1" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Additional margin (in pixels) to render around the current orbit.">Rendering Margin</th>
              <td>
                <input id="julia_local_margin" type="number" value="80" min="0" max="500" step="10" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Maximum size (in pixels) of the height & width of the Julia rendering box.">Max Julia Size</th>
              <td>
                <input id="julia_local_max_size" type="number" value="650" min="50" max="1000" step="50" autocomplete="off">
              </td>
            </tr>
          </table>
          <hr id="julia_options_hr" class="clear_both hidden collapse_hr"></hr>

          <h3 class="collapse_header" data-collapse_hide="mandelbrot_options_table" data-collapse_show="mandelbrot_options_hr">Mandelbrot Options</h3>
          <table id="mandelbrot_options_table" class="collapse_target">
            <tr>
              <th class="tt ttright" data-title="Maximum iterations when rendering the static (background) Mandelbrot fractal. Higher values significantly increase Mandelbrot rendering time, but this only happens when the page loads or you change the zoom factor. NOTE: extremely high values will not improve the quality of large zoom factors! All of the math is done using standard Javascript double precision floating point values, which have very limited precision.">Max Iterations</th>
              <td class="slider">
                <label for="mandel_max_iterations" id="mandel_max_iterations_label">60%</label>
                <input id="mandel_max_iterations" type="range" value="120" min="20" max="1000" step="20" autocomplete="off">
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Antialias the Mandelbrot set rendering by oversampling each pixel. Increases CPU cost to render the Mandelbrot (which only happens once).">Antialias</th>
              <td>
                <select name="mandel_antialias" id="mandel_antialias" autocomplete="off">
                  <option value="1">Disabled</option>
                  <option value="2" selected="selected">2 x 2</option>
                  <option value="3">3 x 3</option>
                </select>
              </td>
            </tr>
            <tr>
              <th class="tt ttright" data-title="Color for compllex values inside the Mandelbrot Set. (traditionally black)">
                Internal Color
              </th>
              <td class="color_picker">
                <label for="mandel_color_internal" id="mandel_color_internal_label">#000000</label>
                <input id="mandel_color_internal" name="mandel_color_internal"
                       type="color" value="#000000" autocomplete="off">
              </td>
            </tr>
            <tr>
              <td colspan="2" class="dialog_container">
                <button id="mandel_external_color_move_to_dialog" class="move_to_dialog tt ttleft" data-title="Pop out the color editor into a movable window.">&nearr;</button>
                <div id="mandel_external_color" class="gradient_editor"></div>
              </td>
            </tr>
            <tr>
              <th>Color Presets</th>
              <td>
                <select name="mandel_color_preset" id="mandel_color_preset" autocomplete="off">
                </select>
                <button id="mandel_use_color_preset">Use</button>
              </td>
            </tr>
          </table>
          <hr id="mandelbrot_options_hr" class="clear_both hidden collapse_hr"></hr>
        </div>

        <hr class="clear_both"></hr>

        <div id="orbit_options" class="optionbox obleft">
          <h3 class="collapse_header" data-collapse_hide="miscellaneous_options_table" data-collapse_show="miscellaneous_options_hr">Miscellaneous</h3>
          <table id="micellaneous_options_table" class="collapse_target">
            <tr>
              <th class="tt ttright" data-title="Clears all localStorage data and resets the values back to their default values.">Clear Persistant Storage</th>
              <td>
                <button id="reset_all_storage">Reset ALL Storage</button>
              </td>
            </tr>
          </table>
          <hr id="miscellaneous_options_hr" class="clear_both hidden collapse_hr"></hr>
        </div>

        <div class="clear_both"></div>
      </div>
    </div>

    <footer></footer>

    <script type="text/javascript">
undivert(`uioption.js')
undivert(`motion.js')
undivert(`highlight.js')
undivert(`fileio.js')
undivert(`dialog.js')
undivert(`color.js')
undivert(`main.js')
    </script>
  </body>
</html>
