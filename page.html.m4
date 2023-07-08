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
          <button id="button_reset" class="tt ttright" data-title="Reset back to original non-zoomed view.">Reset</button>
          <select name="zoom_amount" id="zoom_amount">
            <option value="0.8">80%</option>
            <option value="0.6" selected="selected">60%</option>
            <option value="0.4">40%</option>
            <option value="0.2">20%</option>
          </select>
          <button id="button_zoom" class="tt ttleft" data-title="Select a point to soom into.">Zoom</button>"
        </div>
      </div>
    </div>

    <div class="clear_both"></div>

    <footer></footer>

    <script type="text/javascript">
undivert(`main.js')
    </script>
  </body>
</html>
