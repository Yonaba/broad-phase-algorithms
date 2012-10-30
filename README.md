broad-phase-algorithms
======================

Various *space partitioning* techniques implemented in [Lua](http://www.lua.org) for [broad-phase collision detection](http://www.metanetsoftware.com/technique/tutorialB.html).<br/>
See [Notes](https://github.com/Yonaba/broad-phase-algorithms/blob/master/Notes.md)

##Spatial Hashes

###Resources

* __Source code__: see [spatialhash.lua](https://github.com/Yonaba/broad-phase-algorithms/blob/master/spatialhash.lua)
* __Documentation__: see [docs/spatialhash](https://github.com/Yonaba/broad-phase-algorithms/blob/master/docs/spatialhash)
* __Demo__: see [downloads](https://github.com/Yonaba/broad-phase-algorithms/downloads)

###Example of use

```lua
math.randomseed(os.time())
-- Calls the library
local SH = require 'spatialhash'
-- The cellSize for our hash.
-- Remember that shapes we will create later on should not be larger than this
local cellSize = 50
-- Creates a new hash
local grid = SH:new(500,500,cellSize)

-- All shapes we add into the grid must implement a method getAABB()
-- providing the minimum and maximum vertices coordinates of the shape bounding-box
-- Let's use this custom factory function to make compatible shapes
local function newShape(x,y,width,height)
  local shape = {x = x, y = y, w = width, h = height}
  function shape:getAABB()
    return self.x, self.y, self.x+self.w, self.y+self.h
  end
  return shape
end

-- Let's make some shapes
local shapes = {}
for i = 1,10 do shapes[i] = newShape(
  math.random(300),math.random(300), -- random x,y
  50,50) -- width, height
  shapes[i].id = i -- sets an ID to each shape
  grid:addShape(shapes[i]) -- Add the shape to the grid
end


-- Gets colliding-pairs
print('Colliding pairs')
local colliding = grid:getCollidingPairs(shapes)
table.foreach(colliding,
  function(_,v) print(('Shape(%d) collides with Shape(%d)'):format(v[1].id,v[2].id)) end)


-- Let's move our shapes
print('moving shapes')
for i = 1,#shapes do
  shapes[i].x,shapes[i].y = math.random(300),math.random(300), -- random x,y
  grid:updateShape(shapes[i]) -- update the shape position in the hash
end

-- Gets colliding-pairs
print('Colliding pairs')
local colliding = grid:getCollidingPairs(shapes)
table.foreach(colliding,
	function(_,v) print(('Shape(%d) collides with Shape(%d)'):format(v[1].id,v[2].id)) end)
```


##License
This work is under [MIT-LICENSE](http://www.opensource.org/licenses/mit-license.php)<br/>
Copyright (c) 2012 Roland Yonaba

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.