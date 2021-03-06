-- -*-Lua-*-
-- this is a lua script for use in conky

require 'cairo'
require 'lfs'

----------------------------------
local TOP,BOT  = 1,2
----------------------------------
local metar_temp = 0
local temp_int = nil
local temp_ext = nil
local cr, cs   = nil
local iteration = 0
----------------------------------

local function interp(a, b, lambda)
   return a * lambda + b * (1 - lambda)
end

local function graph_set_color(graph, pos, red, green, blue, alpha)
   if pos == TOP then
      graph.red_t=red
      graph.green_t=green
      graph.blue_t=blue
      graph.alpha_t=alpha
   else
      graph.red_b=red
      graph.green_b=green
      graph.blue_b=blue
      graph.alpha_b=alpha
   end
end

local function graph_plot_bar(graph, x, y)
   local max = math.max(graph.max, graph.min + graph.height)
   local z = (y - graph.min)/(max - graph.min)

   cairo_set_source_rgb(graph.cr,
			interp(graph.red_t, graph.red_b, z),
			interp(graph.green_t, graph.green_b, z), 
			interp(graph.blue_t, graph.blue_b, z))
   cairo_move_to(graph.cr, x + graph.px, 0 + graph.py)
   cairo_rel_line_to(graph.cr, 0, -1 - graph.height * z)
   cairo_stroke(graph.cr)
end

local function graph_plot(graph)
   if graph.cr ~= nil then
      cairo_set_line_cap(graph.cr, graph.line_cap)
      cairo_set_line_width(graph.cr, graph.line_width)
      for i=0,graph.width do
        graph_plot_bar(graph, i, graph[i])
      end
      --   print("plot graph to", cr)
   end
end

local function graph_push(graph, iter, value)
   if iter >= graph.next then

      graph.next = graph.next + graph.interval

      if graph.get_value then
        value = graph.get_value(graph)
      end

      print("graph_push", graph,
            "value", value,
            "iter ", iter,
            "next ", graph.next,
            "max  ", graph.max,
            "min  ", graph.min)

      if graph.max ~= graph[0] then
        if value > graph.max then graph.max = value end
      else
        graph.max = value
        for i=1,graph.width do
          if graph[i] > graph.max then graph.max = graph[i] end
        end
      end

      if graph.min ~= graph[0] then
        if value < graph.min then graph.min = value end
      else
        graph.min = value
        for i=1,graph.width do
          if graph[i] < graph.min then graph.min = graph[i] end
        end
      end

      for i=0,graph.width - 1 do graph[i]=graph[i+1] end
      graph[graph.width] = value

   end
end

local function new_graph(px, py, width, init)
   local graph = {}

--   graph.font="Mono"
--   graph.font_size=14
--   graph.font_slant=CAIRO_FONT_SLANT_NORMAL
--   graph.font_face=CAIRO_FONT_WEIGHT_NORMAL
   graph.line_cap=CAIRO_LINE_CAP_BUTT
   graph.line_width=1

   graph_set_color(graph, TOP, 1.0,1.0,1.0,1)
   graph_set_color(graph, BOT, 0.3,0.3,0.3,1)

   graph.px=px
   graph.py=py
   graph.width=width
   graph.height=9

   for i =0,width do
      graph[i] = init
   end

   graph.min = init
   graph.max = init
   graph.next     = 0
   graph.interval = 1
   graph.cr = nil

--   print ("init graph", graph)
--   print ("        px", graph.px)
--   print ("        py", graph.py)
--   print ("     width", graph.width)
--   print ("  interval", graph.interval)
--   print ("      init", init)

   return graph
end

local function graph_write(graph, name)
   local fdesc = io.open("/home/jfleray/.cache/conky/" .. name, "w")
   print ("Write", fdesc, "/home/jfleray/.cache/conky/" .. name)
   fdesc:write(0, " ", graph[0], "\n")
   for i,v in ipairs(graph) do
      fdesc:write(i, " ", v, "\n")
      -- print("write", i, v)
   end
   fdesc:close()
end

local function graph_read(graph, name)

   local i,v
   local fdesc = io.open("/home/jfleray/.cache/conky/" .. name, "r")

   if not fdesc then
     print ("Mkdir /home/jfleray/.cache/conky/")
     lfs.mkdir("/home/jfleray/.cache/conky")
   else

     print ("Read", fdesc, "/home/jfleray/.cache/conky/" .. name)

     while true do
       i, v = fdesc:read("*n", "*n")
       -- print("graph[", i, "] =", v)
       if i and v then
         graph[i] = v
       else
         break
       end
     end
     fdesc:close()

     graph.min = graph[0]
     graph.max = graph[0]
     for j = 1,graph.width do
       if graph[j] then
         graph.min = math.min(graph.min, graph[j])
         graph.max = math.max(graph.max, graph[j])
         metar_temp = graph[j]
       end
     end
   end
end

--
-- Température interne (du processeur 0)
--

local function get_proc_temp(n)
   if n == nil then n = 0 end

   local thermal = io.open("/sys/class/thermal/thermal_zone" .. n .. "/temp")
   local temp    = thermal:read("*n")
   thermal:close()
   return temp/1000.0
end

local function graph_get_proc_temp(graph)
   return get_proc_temp(graph.parameter)
end

function conky_thermint(n)
   return string.format("%.1f", get_proc_temp(n))
end

--
-- Température externe (de la station LFRK)
--

local function get_metartemp(name)
   local url = "https://www.aviationweather.gov/adds/dataserver_current/" ..
      "httpparam?dataSource=metars&requestType=retrieve&format=csv&stationString=" ..
      name .. "&hoursBeforeNow=3&mostRecent=true"

   local fdesc = io.popen ("curl -s '" .. url .. "'")
   local line = {}

   for i = 1,7 do
     line[i] = fdesc:read("*l")
     -- print("line", i, line[i])
   end

   local i = 0
   local fields = {}
   for field in string.gmatch(line[7], "([^,]*),") do
      i = i + 1
      fields[i] = field
   end

   local oldlocale = os.setlocale (nil)
   os.setlocale("C")
   local temp = tonumber(fields[6])
   os.setlocale(oldlocale)

   return temp or metar_temp
end

local function get_exttemp(n)
   return metar_temp
end

local function graph_get_metar_temp(graph)
   metar_temp = get_metartemp(graph.parameter)
   graph_write(graph, graph.parameter)
   return metar_temp
end

function conky_thermext(n)
   return string.format("%.1f", get_exttemp(n))
end

function conky_main()

   iteration = iteration + 1

   -- initialization of graphs
   if iteration == 1 then

      --
      -- graphique température intérieure (CPU 0)
      --

      temp_int = new_graph(151.5, 87, 150, get_proc_temp("0"))
      temp_int.interval = 5
      temp_int.get_value = graph_get_proc_temp
      temp_int.parameter = "0"

      graph_set_color(temp_int, TOP, 1.0,0.7,0.0,1)
      graph_set_color(temp_int, BOT, 0.4,0.3,0.0,1)

      --
      -- graphique température extérieure (LFRG) (Deauville Saint Gatien)
      --

      temp_ext = new_graph(151.5, 103, 150, metar_temp)
      graph_read(temp_ext, "LFRK")
      temp_ext.interval = 900
      temp_ext.get_value = graph_get_metar_temp
      temp_ext.parameter = "LFRK"

      graph_set_color(temp_ext, TOP, 1.0,0.7,0.0,1)
      graph_set_color(temp_ext, BOT, 0.4,0.3,0.0,1)

   end

   -- deferred initialization (cr value is not immédiately
   -- avalaible)
   if conky_window and (iteration % 100) == 5 then
      cs = cairo_xlib_surface_create(conky_window.display,
				     conky_window.drawable,
				     conky_window.visual,
				     conky_window.width,
				     conky_window.height)
      cr = cairo_create(cs)
      -- print("cs, cr", cs, cr)
      temp_int.cr = cr
      temp_ext.cr = cr
   end

   -- eventually add a new value to graphs
   if temp_int then graph_push(temp_int, iteration, 0) end
   if temp_ext then graph_push(temp_ext, iteration, 0) end

   -- plot the graphs
   if temp_int then graph_plot(temp_int) end
   if temp_ext then graph_plot(temp_ext) end

   --      cairo_destroy(cr)
   --      cairo_surface_destroy(cs)
   --      cs, cr = nil
   --   draw_text_value(cr, 200, 52, "Temp0:", temp0/1000)
   --   draw_text_value(cr, 200, 69, "Temp1:", temp1/1000)

end
