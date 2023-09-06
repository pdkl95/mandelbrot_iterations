# Mandelbrot Iterations

Interactive realtime rendering of the orbits of the
[Mandelbrot Set](https://en.wikipedia.org/wiki/Mandelbrot_set). The
correspondng [Julia Set](https://en.wikipedia.org/wiki/Julia_set)
can be overlayed on top of the orbit trace, demonstrating the
relationship between the two fractals and how they both are a product
of the attractors in the orbits.

## Usage

Try it live on Codeberg:

[https://pdkl95.codeberg.page/mandelbrot_iterations/](https://pdkl95.codeberg.page/mandelbrot_iterations/)

or GitHub:

[https://pdkl95.github.io/mandelbrot_iterations/](https://pdkl95.github.io/mandelbrot_iterations/)

### Things To Try

Press the "Start" button to see the orbits just inside the edge of the
main cardioid. Try turning on the "Show Internal Angle" while while
it's animating.

Turn on the Julia Set overlay with the "Show Nearby Julia"
option. The rendering qualitty if the Julia Set is greatly reduced to
limit the CPU load; clicking or pressing space will pause movement and
render a full-size static image at much higher quality (and more
iterations).

### Limiations

#### Very Limited Zoom

While rendering the Mandelbrot Set usually unvolves large amounts of
zooming (sometimes to
zoom factors with insane iteration requirements[^1]) this software
uses Javascript's native double precision (64 bit) floating point for
all calculations.

## Motivation

While I first leaened about the Mandelbrot Set _many_ years
ago. Playing with
[James Gleick's CHAOS: The Software](https://github.com/rudyrucker/chaos)
on my IBM AT's 80286 CPU required a lot of patience. just to see a tiny
16 color image of a Julia or Mandelbrot[^1].  I thought I understood the iterative
math underltying these fractals.

This understanding was shaken when I saw
[this Numberphile video](https://www.youtube.com/watch?v=FFftmWSzgmk)
featuring Ben Sparks, and a short
[series of videos by The Mathemagicians' Guild](https://www.youtube.com/playlist?list=PL9tHLTl03LqG4ajDvqyfCDMKSxmR_plJ3)
complety changed my undrstanding of the Set. I highly recommend
watching them.

Whay was different about those videos that was missing from most of
the articl4s/videos/etc I had seen before? These videos focus on the
_orbits_. So I wrote this as a tool for exploring the orbits directly.

While outside this project's tended scope, the [videos](https://www.youtube.com/playlist?list=PL9tHLTl03LqG4ajDvqyfCDMKSxmR_plJ3)
by The Mathemagicians' Guild also describes other interesting
properties of the Mandelbrot Set that I had never heard before:

> At the center of every embedded Julia Set we find a "mini" Mandelrot.
> The "mini" Mandelbrot is found at twice the depth as where we found\
> the embedded Julia Set.

> The Mandelbrot Set remembers where it came from.

To understan what the latter stement means, I highly recommed reading
the description for [this video by Maths Town](https://www.youtube.com/watch?v=CdSXlzqN7Og);
the video itself is a really goods demonstrates the property.

## License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

[^1]: Today, with similar amounts of patience. clever computatiopn techniques, and modern hardware gives you an [amazing hour long journey](https://www.youtube.com/watch?v=uUiwddOhg4c) to a mini Mandelbrtot __10^-1524__ where the rendering requires **10 Trillion** iterations! (a [short 3 minute "highlights" version](https://www.youtube.com/watch?v=BsH8uiRvYJk))

