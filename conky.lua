--this is a lua script for use in conky
require 'cairo'

last,current=0,0
temp0={}
tmax0,tmin0=100,0
----------------------------------
font="Mono"
font_size=14
red0,green0,blue0,alpha0=1.0,0.7,0.0,1
red1,green1,blue1,alpha1=0.4,0.3,0.0,1
width=1
height=10
px,py = 201.5, 86
font_slant=CAIRO_FONT_SLANT_NORMAL
font_face=CAIRO_FONT_WEIGHT_NORMAL
line_cap=CAIRO_LINE_CAP_BUTT
----------------------------------

function draw_text_value(cr, xpos, ypos, text, value)
   cairo_select_font_face(cr, font, font_slant, font_face)
   cairo_set_font_size(cr, font_size)
   cairo_set_source_rgba(cr, red0, green0, blue0, alpha0)
   cairo_move_to(cr, xpos, ypos)
   cairo_show_text(cr, text .. value)
   cairo_stroke(cr)
end

function plot(cr, x, y)
   -- tmax0, tmin0 : global values
   if y == nil then return end

   local z = (y - tmin0)/(math.max(tmax0, tmin0 + 4) - tmin0)
   
   cairo_set_source_rgb(cr, interp(red0, red1, z),
			interp(green0, green1, z), 
			interp(blue0, blue1, z))
   cairo_move_to(cr, x + px, 0 + py)
   cairo_rel_line_to(cr, 0, -1 - height * z)
   cairo_stroke(cr)
end

function interp(a, b, lambda)
   return a * lambda + b * (1 - lambda)
end

function push_next_temp(temp)

   -- temp0, tmax0, tmin0 : global values
   if tmax0 ~= temp0[0] then
      if temp > tmax0 then tmax0 = temp end
   else
      tmax0 = temp
      for i=1,100 do
	 if temp0[i] > tmax0 then tmax0 = temp0[i] end
      end
   end

   if tmin0 ~= temp0[0] then
      if temp < tmin0 then tmin0 = temp end
   else
      tmin0 = temp
      for i=1,100 do
	 if temp0[i] < tmin0 then tmin0 = temp0[i] end
      end
   end

   for i=0,99 do temp0[i]=temp0[i+1] end
   temp0[100] = temp

end

function get_temp(n)
   if n == nil then
      n = 0
   end

   local thermal = io.open("/sys/class/thermal/thermal_zone" .. n .. "/temp")
   local temp    = thermal:read("*n")
   thermal:close()
   return temp/1000.0
end

function conky_thermalread(n)
   return string.format("%.1f", get_temp(n))
end

function conky_main()

   current=tonumber(conky_parse('${updates}'))

   if temp0[0] == nil then -- La première fois
      local temp =  get_temp("0")
      for i = 0,99 do temp0[i] = temp - 1 end
      temp0[100] = temp
      tmax0      = temp
      tmin0      = temp - 1
      last = current
      -- print (tmin0, temp0[100], tmax0)
   end
      
   if current >= last + 5 then -- Toutes les 5 secondes
      push_next_temp(get_temp("0"))
      last = current
      -- print (tmin0, temp0[100], tmax0)
   end

   if conky_window ~= nil then
      cs = cairo_xlib_surface_create(conky_window.display,
				     conky_window.drawable,
				     conky_window.visual,
				     conky_window.width,
				     conky_window.height)
      cr = cairo_create(cs)
      cairo_set_line_cap(cr, line_cap)
      cairo_set_line_width(cr, width)
      
      for i=13,100 do
	 plot(cr, i, temp0[i])
      end
      
      cairo_destroy(cr)
      cairo_surface_destroy(cs)
      cs,cr=nil,nil
   end
    
--   local cs, cr=nil, nil
--   local temp0, temp1
--  
--   thermal = io.open("/sys/class/thermal/thermal_zone0/temp")
--   temp0   = thermal:read("*n")
--   thermal:close()
--   thermal = io.open("/sys/class/thermal/thermal_zone1/temp")
--   temp1   = thermal:read("*n")
--   thermal:close()
--   draw_text_value(cr, 200, 52, "Temp0:", temp0/1000)
--   draw_text_value(cr, 200, 69, "Temp1:", temp1/1000)

end
