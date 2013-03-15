# Copyright 2012 Joshua Carver  
#  
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at 
#  
# http://www.apache.org/licenses/LICENSE-2.0 
#  
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
# See the License for the specific language governing permissions and 
# limitations under the License. 


# @import point.coffee
# @import label.coffee
# @import scaling.coffee
# @import base_chart.coffee

bar = () ->

class BulletChart extends BaseChart
  constructor: (dom_id, options = {}) ->
    bar = (label, value, average, comparison, min, max, blob = false) ->
      {
        label: label
        value: value
        average: average
        comparison: comparison
        min: min
        max: max
        blob: blob
      }
    super dom_id, new BulletChartOptions(options)
    @bars = []

  add: (label, value, average, comparison) ->
    @bars.push bar.apply(bar, arguments)


  draw_background: (point, y_offset, bar_midpoint, label) ->
    if bar.blob
      x_offset = point.x-@options.area_width
      width = @options.area_width*2
      text_anchor = 'middle'
    else
      if label > 0
        x_offset = bar_midpoint.x
        width = point.x-bar_midpoint.x
        text_anchor = 'end'
        point.x -= 5  # a touch of padding
      else if label < 0
        x_offset = point.x
        width = bar_midpoint.x-point.x
        text_anchor = 'start'
        point.x += 5  # a touch of padding
      else
        x_offset = bar_midpoint.x-@options.area_width/2
        width = @options.area_width
        text_anchor = 'middle'

    rect = @r.rect(
      x_offset,
      y_offset,
      width,
      @options.area_width
    )

    rect.attr({
      fill: @options.area_color
      "stroke": "none" 
    })
    
    new Label(
      @r,
      point.x,
      y_offset + @options.area_width/2,
      label + @options.area_label_suffix,
      @options.label_format,
      Math.min(@options.area_width - 6, width/1.5 - 6),
      @options.font_family,
      "#fff",
      {'text-anchor': text_anchor}
    ).draw()

  draw_line: (point, background_midpoint) ->
    y = background_midpoint.y - @options.line_width/2
    rect = @r.rect(
      @options.x_padding
      y,
      point.x-@options.x_padding
      @options.line_width
    )

    rect.attr({
      fill: @options.line_color
      "stroke" : "none"
    })
  
  draw_average: (point, midpoint_y) ->
    rect = @r.rect(
      point.x - (@options.average_width/2),
      midpoint_y - @options.average_height/2,
      @options.average_width,
      @options.average_height
    )

    rect.attr({
      fill: @options.average_color
      "stroke" : "none"
    })

  draw_label: (text, offset) ->

  draw_x_label: (raw_point, point) ->
    fmt = @options.label_format
    size = @options.x_label_size
    font_family = @options.font_family

    label = if raw_point.is_date_type == true then new Date(raw_point.x) else Math.round(raw_point.x)
    new Label(
      @r,
      point.x,
      @options.area_width + 20,
      label,
      fmt,
      size,
      font_family,
      @options.x_label_color
    ).draw()


  clear: () ->
    super()
    @bars = []


  draw: () ->
    tick_height = Math.max(@options.area_width, @options.line_width, @options.average_width) + 5

    for bar, i in @bars

      p = [
            new Point(bar.comparison, 0),
            new Point(bar.value, 0),
            new Point(bar.average, 0),
            new Point(0,0) # dummy for scaling
          ]

      [max_x, min_x, max_y, min_y] = Scaling.get_ranges_for_points(p)

      min_x = bar.min if bar.min
      max_x = bar.max if bar.max

      p.push(new Point(max_x, 0)) # another dummy for scaling

      s = new Scaler()
      .domain([min_x, max_x])
      .range([@options.x_padding, @width - @options.x_padding])

      points = (new Point(s(point.x), 0) for point in p)

      step_size = (max_x - min_x) / @options.max_x_labels
      ticks = (new Point(min_x+step_size*j, 0) for j in [0..(@options.max_x_labels-1)])

      y_offset = i * (@options.area_width + @options.bar_margin)
      midpoint_y = y_offset + @options.area_width/2
      @draw_line(points[1], new Point(points[0].x, midpoint_y))
      @draw_background(points[0], y_offset, points[3], if Math.round(p[0].x) != p[0].x then p[0].x.toFixed(1) else p[0].x)
      @draw_average(points[2], midpoint_y)

      new Label(
       @r,
       0,
       y_offset + @options.area_width/2,
       bar.label,
       "",
       @size = 14,
       @options.font_family
      ).draw()

      for k in ticks
        @r.path('M'+(new Point(s(k.x)).x)+','+tick_height+'L'+(new Point(s(k.x)).x)+','+(tick_height + 5)).attr({'stroke': @options.x_label_color})
        @draw_x_label(k, new Point(s(k.x)))

      # always draw the last tick
      @r.path('M'+(points[4].x)+','+tick_height+'L'+(points[4].x)+','+(tick_height + 5)).attr({'stroke': @options.x_label_color})
      @draw_x_label(p[4], points[4])

      @r


exports.BulletChart = BulletChart
