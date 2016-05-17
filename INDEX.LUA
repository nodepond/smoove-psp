--[[ 
Smoove V0.92
Pixel, Tile and Sprite Editor for PSPLua

Copyright (c) 2006 020200
http://smoove.node3000.de

feb06mar06apr06sep06

changes to V0.92:
- usb connect
- changes at settiles
- added info urls

changes to V0.91:
- scroll mode at zoom
- minor bugfixes (canvas errors at zoom mode, pixel shift at first row)

changes to V0.9: 
- quick load was replaced by quick save (keys L+R)
- battery loading state at animation menu
- enhanced datastructure (folder structure)
- changed icon.png
- minor bugfixes

ToDo:
- popup(ie. for quit/about)
- settiles bugfixes + animtable
- quick save color sel
- enhancement of menucursor triggering
- better filebrowsing
- show tilesize?
- save as bmp / single frames
- advanced colorpicker

V 1.0 wishlist
- settiles advanced
- mirror tiles
- fill
- transparent color

]]--

require "includes/pad.lc"
require "includes/menu.lc"

Smoove = {
  Black = Color.new(0, 0, 0)
, None  = Color.new(200, 200, 200, 0)
, White = Color.new(255, 255, 255)
, Gray  = Color.new(150, 150, 150)
, Settilecolor = Color.new(175,20,255)
, mapname = nil
, path = "data/"
, mx = 240
, my = 136
, pmx = 240
, pmy = 136
, tilesizex = 32 -- min: 1, max: 58
, tilesizey = 32 -- min: 1, max: 32
, Playtiles = {ffx = 1, tfx = 5, ffy = 1, tfy = 1}
, framex = 1
, framey = 1
, frate = 2
, showsize = true
, showzoom = false
}

-- helper fuctions
function Smoove:Align(t, d)
  return math.floor(t/d)*d
end

function Smoove:drawRect(r, x, y, w, h, c)
  r:drawLine(x, y, x+w, y, c)
  r:drawLine(x+w, y, x+w, y+h, c)
  r:drawLine(x+w, y+h, x, y+h, c)
  r:drawLine(x, y+h, x, y, c)
end


function Smoove:GetDir()
  local x, y = Pad.Ax/90, Pad.Ay/90
  local d = math.sqrt(x*x+y*y)
  if d>1 then
    return x/d, y/d
  else
    return x, y
  end
end


function Smoove:GetVel(x, y, q, s)
  local ax, ay = Smoove:GetDir()
  local v = 3.5
  if q then v = 1 end
  if not s then s = 1 end
  x = x + (Pad:nGetRepeat(Pad.cLr) - Pad:nGetRepeat(Pad.cLl))*s
  y = y + (Pad:nGetRepeat(Pad.cLd) - Pad:nGetRepeat(Pad.cLu))*s
  return
  math.min(math.max(x + ax * v, 0), 479),
  math.min(math.max(y + ay * v, 0), 271)
end

-- color stuff
function Smoove:HSVtoRGB(h, s, v)
  local i = math.floor(h / 60)
  local f = h / 60 - i
  local p1 = v*(1-s)
  local p2 = v*(1-s*f)
  local p3 = v+p1-p2
  if i==0 then return v*255, p3*255, p1*255 end
  if i==1 then return p2*255, v*255, p1*255 end
  if i==2 then return p1*255, v*255, p3*255 end
  if i==3 then return p1*255, p2*255, v*255 end
  if i==4 then return p3*255, p1*255, v*255 end
  if i==5 then return v*255, p1*255, p2*255 end
end


function Smoove:DrawPalette(dst, h)
  local s, v, r, g, b
  for x=0, 20 do s = x / 20
    for y=0, 20 do v = y / 20
      r, g, b = self:HSVtoRGB(h, s, v)
      dst:fillRect(x*3 + 33, 93 - y*3, 3, 3, Color.new(r, g, b))
    end
  end
end


function Smoove:CreatePalette()
  local z, h, rad, x, y, ox, oy, r, g, b
  local palette = Image.createEmpty(128, 128)
  x, y = 64, 15
  for z=49.5, 62, 0.5 do
    for h=0, 359 do
      rad = math.rad(h)
      ox = x ; x = 64-math.sin(rad)*z
      oy = y ; y = 64-math.cos(rad)*z
      if z>50 and z<62 then
        r, g, b = self:HSVtoRGB(h, 1.0, 1.0)
        palette:drawLine(ox, oy, x, y, Color.new(r, g, b))
      else
        palette:drawLine(ox, oy, x, y, self.Black)
      end
    end
  end
  palette:fillRect(32, 32, 65, 65, self.Black)
  return palette
end


function Smoove:DrawCursor(x, y, c)
  screen:drawLine(x-7, y, x+7, y, self.Black)
  screen:drawLine(x, y-7, x, y+7, self.Black)
  screen:pixel(x, y, self.White)
  screen:fillRect(x+3, y+3, 8, 8, self.Black)
  screen:fillRect(x+4, y+4, 6, 6, c)
end


function Smoove:SelectColor()
  self.pmx, self.pmy = self:GetVel(self.pmx, self.pmy, Pad.Rr)

  local dx, dy = 240-self.pmx, 136-self.pmy
  local d = math.sqrt(dx*dx+dy*dy)
  if d>=50 and d<63 then
    local r = math.deg(math.atan2(dx, dy))
    if r<0 then r = r + 360 end
    self:DrawPalette(self.palette, math.floor(r))
  end

  screen:blit(240-64, 136-64, self.palette)
  self.CurrentColor = screen:pixel(self.pmx, self.pmy)
  self:DrawCursor(self.pmx, self.pmy, self.CurrentColor)
end

function Smoove:drawBack(cx, cy, tx, ty)
  for x=0, tx-1 do
    for y=0, ty-1 do
      if cx+x < 480 then self.canvas:pixel(cx+x, cy+y, self.dscr:pixel(x*8+9, y*8+9)) end
    end
  end
end

function Smoove:zoomContent(canvx,canvy,w,h, drawx, drawy, zoomfactor, drawgrid, gridcolor)
  if not zoomfactor then zoomfactor = 8 end
  if not gridcolor then gridcolor = self.Gray end
  if drawgrid == nil then drawgrid = true end

  -- first lines
  if drawgrid then
    self.zscr:drawLine(drawx, drawy, drawx, h*zoomfactor+drawy, gridcolor)
    self.zscr:drawLine(drawx, drawy, w*zoomfactor+drawx, drawy, gridcolor)
  end

  for x=0, w-1 do
    for y=0, h-1 do
      local tx=(x+1)*zoomfactor+drawx
      local ty=(y+1)*zoomfactor+drawy
      if drawgrid then
        self.zscr:drawLine(tx, drawy, tx, h*zoomfactor+drawy, gridcolor) -- vertical lines
        self.zscr:drawLine(drawx, ty, w*zoomfactor+drawx, ty, gridcolor) -- horizontal lines
      end
      self.dscr:fillRect(tx-zoomfactor, ty-zoomfactor, zoomfactor, zoomfactor, self.canvas:pixel(canvx+x, canvy+y))    
    end
  end

end

-- Zoom Edit --------------------------------------------
function Smoove:ZoomEdit(cx, cy)
  
  -- check if right border is valid
  local tilesx = self.tilesizex
  if cx + tilesx >= 480 then  
    tilesx = 479 - cx
    self.zscr:clear(self.None)
    self.dscr:clear(self.None)
  end
  -- check if bottom border is valid
  local tilesy = self.tilesizey
  if cy + tilesy >= 272 then  
    tilesy = 272 - cy
    self.zscr:clear(self.None)
    self.dscr:clear(self.None)
  end
   
  Smoove:zoomContent(cx, cy, tilesx, tilesy, 8, 8)

  while not Pad.tRl do  
    Pad:Update()
    screen:blit(0, 0, self.whiteimg)
    screen:blit(0, 0, self.dscr)
    screen:blit(0, 0, self.zscr)
    if Pad.Ru then
      self:SelectColor()
    else
      self.mx, self.my = self:GetVel(self.mx, self.my, Pad.Rr or Pad.Rd, 8)
      -- zoom scroll
      if self.mx == 0 then
        Smoove:drawBack(cx, cy, tilesx, self.tilesizey) 
        cx = cx - 1
        if cx < 0 then cx = 0 end
        Smoove:zoomContent(cx, cy, tilesx, self.tilesizey, 8, 8)
        self.mx = 4
      end
      if self.mx >= tilesx*8+15 then 
        Smoove:drawBack(cx, cy, tilesx, self.tilesizey)
        cx = cx + 1
        if cx + tilesx >= 480 then cx = 479 - tilesx end
        Smoove:zoomContent(cx, cy, tilesx, self.tilesizey, 8, 8)
        self.mx = tilesx*8+12
      end
      if self.my == 0 then 
        Smoove:drawBack(cx, cy, tilesx, self.tilesizey)
        cy = cy - 1
        if cy < 0 then cy = 0 end
        Smoove:zoomContent(cx, cy, tilesx, self.tilesizey, 8, 8)
        self.my = 4
      end
      if self.my >= self.tilesizey*8+15 then 
        Smoove:drawBack(cx, cy, tilesx, self.tilesizey)
        cy = cy + 1
        if cy + self.tilesizey >= 272 then cy = 272 - self.tilesizey end
        Smoove:zoomContent(cx, cy, tilesx, self.tilesizey, 8, 8)
        self.my = self.tilesizey*8+12
      end     

      if Pad.R1 then self.CurrentColor = screen:pixel(self.mx, self.my) end
      if Pad.Rr and (self.mx<(tilesx+2)*8) and (self.my<(self.tilesizey+2)*8)  then -- only draw inside grid + markers
        self.dscr:fillRect(self:Align(self.mx,8)+1,
          self:Align(self.my,8)+1, 7, 7, self.CurrentColor)
      end
      if Pad.Rd and (self.mx<(tilesx+2)*8) and (self.my<(self.tilesizey+2)*8)  then
         self.dscr:fillRect(self:Align(self.mx,8)+1,
         self:Align(self.my,8)+1, 7, 7)
      end
      if Pad.L1 then
        for x=0, tilesx-1 do
           for y=0, self.tilesizey-1 do
             self.dscr:fillRect(x*8+9, y*8+9, 7, 7, self.copyBuffer:pixel(x, y))
           end
        end
      end
      self:DrawCursor(self.mx, self.my, self.CurrentColor)      
    end
    screen.waitVblankStart()
    screen.flip()
  end

  while not Pad.rRl do
    Pad:Update()
    screen.waitVblankStart()
  end
  
  Smoove:drawBack(cx, cy, tilesx, self.tilesizey)

  -- copy buffer
  for x=0, tilesx-1 do
    for y=0, self.tilesizey-1 do
      self.copyBuffer:pixel(x, y,  self.dscr:pixel(x*8+9, y*8+9)) 
    end
  end  

end


function Smoove:iterateFrames(reset)
  if reset then 
    self.framex = self.Playtiles.ffx 
    self.framey = self.Playtiles.ffy
    else self.framex = self.framex + 1
  end
  if self.framex*self.tilesizex >= 480 then 
    self.framex = 1
    self.framey = self.framey + 1    
  end 

  if self.framex >= self.Playtiles.tfx and self.framey >= self.Playtiles.tfy then 
    self.framex = self.Playtiles.ffx 
    self.framey = self.Playtiles.ffy 
  end
end


function Smoove:animate()  
  screen:blit(0, 0, self.whiteimg) 
  
  Smoove:drawRect(screen, 299, 8, self.tilesizex+1, self.tilesizey+1, self.Black)
  screen:blit(300,9, self.canvas, self.tilesizex*(self.framex-1)+1, self.tilesizey*(self.framey-1)+1, self.tilesizex, self.tilesizey)
  
  if self.showzoom then
    Smoove:zoomContent(self.tilesizex*(self.framex-1), self.tilesizey*(self.framey-1), self.tilesizex, self.tilesizey, 8, 8, 3, false)
    screen:blit(8, 168, self.dscr, 8, 8, self.tilesizex*3, self.tilesizey*3)
  end

  Menu:drawMenu()

  frametimer = frametimer + 1
  if (frametimer >= self.frate) then
    frametimer = 0
    Smoove:iterateFrames()  
  end
  
end


-- Menu functions ---------------------------------------
function Smoove:frameSize()
  Menu:Cue()
  Pad:Update()
  while not Pad.tRr do
    Pad:Update()
    
    if Pad.tLr then self.tilesizex = self.tilesizex + 1 end
    if Pad.tLl then self.tilesizex = self.tilesizex - 1 end
    if Pad.tLu then self.tilesizey = self.tilesizey - 1 end
    if Pad.tLd then self.tilesizey = self.tilesizey + 1 end
    if self.tilesizex > 58 then self.tilesizex = 58 end
    if self.tilesizey > 32 then self.tilesizey = 32 end
    if self.tilesizex < 1 then self.tilesizex = 1 end
    if self.tilesizey < 1 then self.tilesizey = 1 end
 
    Menu:changeEntry(Menu:getSelectedNum(), "frame size: " .. self.tilesizex .. "x" .. self.tilesizey)
    self:animate()
    screen.waitVblankStart()
    screen.flip()
   end
   self.dscr:clear(self.None)
   Menu:Uncue()
end

function Smoove:open()
  local tmp = Menu:browseFiles(".PNG", self.path)
  local img
  if tmp then
    self.mapname = tmp
    img = Image.load(self.path..self.mapname)
    self.canvas:clear(self.None)
    self.canvas:blit(0,0,img)
  end
end

function Smoove:save()
  self.canvas:save(self.path..self.mapname)
end

function Smoove:saveAs()
  if not self.mapname then self.mapname = "NEW.PNG" end
  local tmp = Menu:enterName(self.mapname)
  if tmp then
    self.mapname = tmp
    self.canvas:save(self.path..self.mapname)
  end
end

function Smoove:clearScreen()
  self.canvas:clear()
end

function Smoove:setTiles()
  Pad:Update()
  self.mx = self.Playtiles.ffx*self.tilesizex-(self.tilesizex/2)
  self.my = self.Playtiles.ffy*self.tilesizey-(self.tilesizey/2)
  
  while true do
    Pad:Update()
    screen:blit(0, 0, self.whiteimg)
    screen:blit(0, 0, self.canvas)

    if Pad.Rd then break end
    if Pad.tRr then break end
    
    Smoove:drawRect(screen, 0, 0, 480, 272, self.Settilecolor)
    if Pad.tRl then
      self.Playtiles.ffx = (self:Align(self.mx, self.tilesizex)/self.tilesizex)+1
      self.Playtiles.ffy = (self:Align(self.my, self.tilesizey)/self.tilesizey)+1
      if self.Playtiles.ffx > self.Playtiles.tfx then self.Playtiles.tfx = self.Playtiles.ffx end
      if self.Playtiles.ffy > self.Playtiles.tfy then self.Playtiles.tfy = self.Playtiles.ffy end
      self.framex = self.Playtiles.ffx
      self.framey = self.Playtiles.ffy
    end

    if Pad.Rl then self.Playtiles.tfx = (self:Align(self.mx, self.tilesizex)/self.tilesizex)+2 end
    if self.Playtiles.tfx*self.tilesizex >= 480 then self.Playtiles.tfx = (self:Align(479, self.tilesizex)/self.tilesizex)+2 end
    if Pad.Rl then self.Playtiles.tfy = (self:Align(self.my, self.tilesizey)/self.tilesizey)+1 end

    if self.Playtiles.tfx <= self.Playtiles.ffx and self.Playtiles.tfy <= self.Playtiles.ffy then self.Playtiles.tfx = self.Playtiles.ffx+1 end
    if self.Playtiles.tfy < self.Playtiles.ffy then self.Playtiles.tfy = self.Playtiles.ffy end

   Smoove:iterateFrames(1)
    for i = 1, 100 do
      Smoove:drawRect(screen, (self.framex-1)*self.tilesizex, (self.framey-1)*self.tilesizey, self.tilesizex, self.tilesizey, self.Settilecolor) 
      Smoove:iterateFrames()
    end

    self.my = math.min(self.my, 254)
    self.mx, self.my = self:GetVel(self.mx, self.my, Pad.Rr or Pad.Rd)
    Smoove:DrawCursor(self.mx, self.my, self.CurrentColor)

    screen.waitVblankStart()
    screen.flip()
  end 
  Smoove:iterateFrames(1)
end

function Smoove:framerate()
  Menu:Cue()
  Pad:Update()
  while not Pad.tRr do
    Pad:Update()    
    if Pad.tLr then self.frate = self.frate + 1 end
    if Pad.tLl then self.frate = self.frate - 1 end
    if self.frate < 1 then self.frate = 1 end
    Menu:changeEntry(Menu:getSelectedNum(), "framerate: " .. 60/self.frate)
    screen:blit(0, 0, self.whiteimg) 

    self:animate()
    screen.waitVblankStart()
    screen.flip()
   end
   Menu:Uncue()
end

function Smoove:showTilesize()
  local show
  if self.showsize then 
    self.showsize = false
    show = "no"
  else 
    self.showsize = true
    show = "yes"
  end
  
  Menu:changeEntry(Menu:getSelectedNum(), "show tilesize: " .. show)
end

function Smoove:showZoom()
   local show
   if self.showzoom then 
    self.showzoom = false
    show = "no"
  else 
    self.showzoom= true
    show = "yes"
  end
  
  Menu:changeEntry(Menu:getSelectedNum(), "show zoom: " .. show)
end

function Smoove:usbConnect()
  Pad:Update()
  System.usbDiskModeActivate()
  Menu:Cue()
  Menu:changeEntry(Menu:getSelectedNum(), "connected...")
    
  while not Pad.tRr do
    Pad:Update()
    Menu:drawMenu()
    screen.waitVblankStart()
    screen.flip()
   end
   Menu:Uncue()
   Menu:changeEntry(Menu:getSelectedNum(), "connect to usb")
   System.usbDiskModeDeactivate()
end

function Smoove:info()
  Menu:Cue()
  Pad:Update()
  while not Pad.tRr do
    Pad:Update()    
    
    Menu:changeEntry(Menu:getSelectedNum(), "http://smoove.node3000.de")
    screen:blit(0, 0, self.whiteimg) 

    self:animate()
    screen.waitVblankStart()
    screen.flip()
   end
   Menu:Uncue()
   Menu:changeEntry(Menu:getSelectedNum(), "info")
end

------ Menu and Animate ---------------------------------
function Smoove:AnimateMenu()
  frametimer = 0
  Pad:Update()
  while not Pad.tSl do
    Pad:Update()
    local framemax = (480/self.tilesizex) * (272/self.tilesizey)
    -- select menu
    -- todo: enhancement of menucursor triggering
    self.mx, self.my = self:GetVel(self.mx, self.my)
    if Pad.tLu then Menu:moveUp() end
    if Pad.tLd then Menu:moveDown() end
    -- menue selection action
    local num = "none"
    if Pad.tRr then num = Menu:getSelectedId() end
    if num == "framesize" then Smoove:frameSize()
       elseif num == "open" then Smoove:open()
       elseif num == "save" then Smoove:save()
       elseif num == "saveas" then Smoove:saveAs()
       elseif num == "clearscreen" then Smoove:clearScreen()
       elseif num == "settiles" then Smoove:setTiles()
       elseif num == "framerate" then Smoove:framerate()
       elseif num == "showtilesize" then Smoove:showTilesize()
       elseif num == "showzoom" then Smoove:showZoom()
       elseif num == "usbconnect" then Smoove:usbConnect()
       elseif num == "info" then Smoove:info()
    end

    self:animate()
    screen:print(440, 8, System.powerGetBatteryLifePercent().."%", self.Black)
    screen.waitVblankStart()
    screen:flip()
  end
  self.zscr:clear(self.None)
end

-- Init -------------------------------------------------
function Smoove:Init()
  Menu:clearAll()
  Menu:setSize(0, 0, 270, 130)
  Menu:setStyle(Color.new(175,20,255), Color.new(0,0,0), Color.new(255,255,0), Color.new(255,255,150), Color.new(255,255,255,255))
  Menu:addEntry("framesize", "frame size: " .. self.tilesizex .. "x" .. self.tilesizey)
  Menu:addEntry("open", "open")
  Menu:addEntry("save", "save")
  Menu:addEntry("saveas", "save as...")
  Menu:addEntry("clearscreen", "clear screen")
  Menu:addEntry("settiles", "set tiles")
  Menu:addEntry("framerate", "framerate: " .. 60/self.frate)
  Menu:addEntry("showtilesize", "show tilesize: yes" )
  Menu:addEntry("showzoom", "show zoom: no" )
  Menu:addEntry("usbconnect", "connect to usb" )
  Menu:addEntry("info", "info" )
end


-- Main -------------------------------------------------
function Smoove:Main()  
  local ox, oy

  Smoove:Init()
  
  if self.zscr == nil then
    self.dscr = Image.createEmpty(480, 272)
    self.zscr = Image.createEmpty(480, 272)
    self.copyBuffer = Image.createEmpty(480, 272)
    self.whiteimg = Image.createEmpty(480, 272)
    self.dscr:clear(self.None)
    self.zscr:clear(self.None)
    self.whiteimg:clear(self.White)
  end

  self.palette = self:CreatePalette()
  self.canvas = Image.createEmpty(480, 272)
  self.canvas:clear()
  self.CurrentColor = self.Black

  self:DrawPalette(self.palette, math.floor(0))

  while not Pad.tSt do
   Pad:Update()

    if Pad.R1 and Pad.L1 then 
      if self.mapname == nil then Smoove:saveAs() else Smoove:save() end
    end
      
    screen:blit(0, 0, self.whiteimg)
    self.canvas:fillRect(0, 261, 40, 12, self.White) -- showframesize
    if self.showsize then self.canvas:print(1, 263, self.tilesizex.."x"..self.tilesizey) end
    screen:blit(0, 0, self.canvas)

    if Pad.Ru then
      self:SelectColor()
    else
      
      if Pad.tSl then self:AnimateMenu() end
      self.mx, self.my = self:GetVel(self.mx, self.my, Pad.Rr or Pad.Rd)
      if Pad.R1 then self.CurrentColor = screen:pixel(self.mx, self.my) end
      if Pad.Rl then
        self.my = math.min(self.my, 255)
        self:drawRect(screen, self:Align(self.mx,self.tilesizex), self:Align(self.my,self.tilesizey), self.tilesizex, self.tilesizey, self.Black)
      elseif Pad.rRl then
        ox, oy = self.mx, self.my
        self.mx = (math.floor(ox) - self:Align(ox,self.tilesizex))*8+12
        self.my = (math.floor(oy) - self:Align(oy,self.tilesizey))*8+12
        self:ZoomEdit(self:Align(ox,self.tilesizex), self:Align(oy,self.tilesizey))
        self.mx, self.my = ox, oy
      elseif Pad.Rr then
        self.canvas:pixel(self.mx, self.my, self.CurrentColor)
      elseif Pad.Rd then
        self.canvas:pixel(self.mx, self.my, self.None)
      end
      self:DrawCursor(self.mx, self.my, self.CurrentColor)
    end
   
    screen.waitVblankStart()
    screen.flip()
  end

  if not Pad.Lu then 
    if self.mapname == nil then Smoove:saveAs() else Smoove:save() end
  end
  Pad:Update()  
end

do Smoove:Main() end