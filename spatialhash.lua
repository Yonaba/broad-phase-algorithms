------------------------------------------------------------------
-- SpatialHash uniform-grid implementation
-- Broad-phase algorithm to faster collision detection
-- Roland_Yonaba, SpatialHash.lua,v 0.1.1 (2012/29/10)
------------------------------------------------------------------

local ceil, max, min = math.ceil, math.max, math.min
local remove = table.remove
local assert, ipairs, setmetatable = assert, ipairs, setmetatable

-- Private
-- Registers colliding shapes
local array_list = {}
local array_pairs = {}

-- Unique IDs for each added shape
local UNIQUE_ID = 0

-- Clamps a value between given bounds
local function clamp(value, _min, _max)
  return value < _min and _min or min(value,_max)
end

-- Converts from space coordinates to grid coordinates
local function spaceToGrid(x,y,size)
  return ceil((x==0 and 1 or x)/size), ceil((y==0 and 1 or y)/size)
end

-- Clamps x,y  locations inside grid bounds
local function clampToGrid(x,y,grid_width,grid_height)
  return clamp(x,1,grid_width), clamp(y,1,grid_height)
end

-- Simple indexation hash function, to maintain the 2d grid as simple array of buckets
local function getHashIndex(x,y,grid_width)
	return (y-1)*grid_width+x
end

-- Bounding-box collision check
local function AABBCollides(sh1,sh2) 
  local sh1x,sh1y,sh1rx,sh1ry = sh1:getAABB()
  local sh2x,sh2y,sh2rx,sh2ry = sh2:getAABB()
  return not (sh2x >= sh1rx or sh2rx <= sh1x
           or sh2y >= sh1ry or sh2ry <= sh1y)
end

-- Checks if value is within low and high bounds
local function outOfRange(value,low,high)
  return value < low or value > high
end

-- Registers bounding-box collisions in a array_list
function reportColWith(self,aShape,wherex,wherey,list)
  local checks = 0
  if outOfRange(wherex,1,self.__cols) then return 0 end
  if outOfRange(wherey,1,self.__rows) then return 0 end
  local hashedIndex = getHashIndex(wherex,wherey,self.__cols)
  local bucket = self.__array[hashedIndex]
	for _,shape in ipairs(bucket) do
		if shape ~= aShape then 
      if AABBCollides(shape,aShape) then list[#list+1] = shape end
      checks = checks+1
    end
	end
  return checks
end

-- Registers bounding-box collisions in a array_list of tables
function reportColPairs(self,aShape,wherex,wherey,list,bool)
  local checks = 0
  if outOfRange(wherex,1,self.__cols) then return 0 end
  if outOfRange(wherey,1,self.__rows) then return 0 end
  local hashedIndex = getHashIndex(wherex,wherey,self.__cols)
  local bucket = self.__array[hashedIndex]
	for _,shape in ipairs(bucket) do
		if shape ~= aShape and (not bool and true or aShape.ID > shape.ID) then 
      if AABBCollides(shape,aShape) then list[#list+1] = {aShape,shape} end
      checks = checks+1
    end
	end
  return checks
end

-- Inits a new hash
function inits(hash)
  hash.__cols, hash.__rows = spaceToGrid(hash.width,hash.height,hash.cellSize)
  hash.__size = hash.__cols*hash.__rows
  hash.__array = {}
  for i = 1,hash.__size do hash.__array[i] = {} end
  return hash
end

-- Adds a shape into a bucket in a hash
local function __addShapeToBucket(hash,shape,xmin,ymin)
  local bucketIndex = getHashIndex(xmin,ymin,hash.__cols)
  local bucketIndexSize = #hash.__array[bucketIndex]
  hash.__array[bucketIndex][bucketIndexSize+1]= shape
  if not shape.ID then 
    UNIQUE_ID = UNIQUE_ID + 1
    shape.ID = UNIQUE_ID
  end
  return bucketIndex
end

-- Removes a shape from a bucket in a hash
local function __removeShapeFromBucket(hash,shape)
  local bucketIndex = shape.index
  local bucketIndexSize = #hash.__array[bucketIndex]
  for i = 1,bucketIndexSize do
    if shape == hash.__array[bucketIndex][i] then
      remove(hash.__array[bucketIndex],i)
      return
    end
  end
end

-- Gets the largest dimension of a given shape
local function getShapeSize(shape)
  local xmin, ymin, xmax, ymax = shape:getAABB()
  return max((xmax-xmin),(ymax-ymin))
end

-- Public interface
--- a <tt>spatialHash</tt> instance.
--- <em>Although all attributes are accessible, those starting with <strong>__</strong> should be considered as <strong>internal</strong></em>.
-- @class table
-- @name spatialHash 
-- @field width the world space width
-- @field height the world space height
-- @field cellSize the square cell size of the grid. Must be larger than the largest shape in the space.
-- @field __cols the number of columns in the spatial grid
-- @field __rows the number of rows in the spatial grid
-- @field __size the number of buckets (i.e. <em>cells</em>) in the spatial grid
-- @field __array the array-list holding the spatial grid buckets
local SpatialHash = {}
SpatialHash.__index = SpatialHash

--- Instantiates a new spatial hash (synctactic shortcut to <tt>SpatialHash:new()</tt>.
-- @class function
-- @name SpatialHash
-- @param width the world space width
-- @param height the world space height
-- @param cellSize the square cell size of the grid. Must be larger than the largest shape in the space.
-- @return a <tt>SpatialHash</tt>

--- Instantiate a new spatial hash.
-- @param width the world space width
-- @param height the world space height
-- @param cellSize the square cell size of the grid. Must be larger than the largest shape in the space.
-- @return a <tt>SpatialHash</tt>
function SpatialHash:new(width, height, cellSize)
  local newSpatialHash = {}
  newSpatialHash.width = width
  newSpatialHash.height = height
  newSpatialHash.cellSize = cellSize
  return setmetatable(inits(newSpatialHash),SpatialHash)
end

--- Adds a given shape in a SpatialHash.
-- The given shape must implement a <tt>getAABB</tt> method returning rectangle bounding vertices coordinates, that is
-- in order, the upper-left and lower-right corners coordinates
--<ul><pre class="example">
--local shape = {x = 10, y = 10, w = 20, h = 20}<br/>
--function shape:getAABB()
--<br>  return (self.x, self.y, self.x+self.w,self.y+self.h)<br/>
--end
--</pre></ul>
-- @param shape a <tt>shape</tt>
function SpatialHash:addShape(shape)
  assert(pcall(shape.getAABB),'Arg \'shape\' must implement a getAABB() method')
  assert(getShapeSize(shape) <= self.cellSize,'Cannot add shape larger than hash grid cell size')
  
  local xmin, ymin = shape:getAABB()
  xmin, ymin = spaceToGrid(xmin,ymin,self.cellSize)
  xmin, ymin = clampToGrid(xmin, ymin, self.__cols, self.__rows)
  shape.index = __addShapeToBucket(self,shape,xmin,ymin)
  shape.xmin, shape.ymin = xmin, ymin
end

--- Removes a given shape from a SpatialHash.
-- @param shape a <tt>shape</tt>
function SpatialHash:removeShape(shape)
	__removeShapeFromBucket(self,shape)
end

--- Updates a given shape position in the hash.
--- Should be called each time the given shape <em>position</em> or <em>geometry</em> attributes changes.
-- @param shape a <tt>shape</tt>
function SpatialHash:updateShape(shape)
  local xmin, ymin = shape:getAABB()
  xmin, ymin = spaceToGrid(xmin,ymin,self.cellSize)
  xmin, ymin = clampToGrid(xmin,ymin,self.__cols, self.__rows)
  if (xmin == shape.xmin and ymin == shape.ymin) then return end
  __removeShapeFromBucket(self,shape)
  shape.index = __addShapeToBucket(self,shape,xmin,ymin)
  shape.xmin, shape.ymin = xmin, ymin
end

--- Returns a set of potentially colliding-pairs involving a given shape
-- @param shape a <tt>shape</tt>
-- @return an array-list of shapes in bounding-box collision with a given shape
-- @return the number of bounding-box collision checks made
function SpatialHash:getCollidingWith(shape)
  array_list = {}
  local checks = 0
  local overlapEastBorder
  local _,_,rx,ry = shape:getAABB()
  checks = checks + reportColWith(self,shape,shape.xmin,shape.ymin,array_list)
  checks = checks + reportColWith(self,shape,shape.xmin,shape.ymin-1,array_list)
  checks = checks + reportColWith(self,shape,shape.xmin-1,shape.ymin-1,array_list)
  checks = checks + reportColWith(self,shape,shape.xmin-1,shape.ymin,array_list)
  if (rx/self.cellSize > shape.xmin) then
    overlapEastBorder = true
    checks = checks + reportColWith(self,shape,shape.xmin+1,shape.ymin-1,array_list)
    checks = checks + reportColWith(self,shape,shape.xmin+1,shape.ymin,array_list)
  end
  if (ry/self.cellSize > shape.ymin)  then
    checks = checks + reportColWith(self,shape,shape.xmin-1,shape.ymin+1,array_list)
    checks = checks + reportColWith(self,shape,shape.xmin,shape.ymin+1,array_list)
    if overlapEastBorder then
      checks = checks + reportColWith(self,shape,shape.xmin+1,shape.ymin+1,array_list)
    end    
  end
  return array_list,checks
end

--- Returns a list of potentially colliding-pairs
-- @param shapes an array list of <tt>shape</tt> objects
-- @return an array-list of pairs in mutual bounding-box collision
-- @return the number of bounding-box collision checks made
function SpatialHash:getCollidingPairs(shapes)
  array_pairs = {}
  local checks = 0
  local _,rx,ry
  local overlapEastBorder
  for i = 1,#shapes do
    _,_,rx,ry = shapes[i]:getAABB()
    overlapEastBorder = false    
    checks = checks + reportColPairs(self,shapes[i],shapes[i].xmin,shapes[i].ymin,array_pairs,true)
    checks = checks + reportColPairs(self,shapes[i],shapes[i].xmin-1,shapes[i].ymin+1,array_pairs)
    if (rx/self.cellSize > shapes[i].xmin) then
      overlapEastBorder = true
      checks = checks + reportColPairs(self,shapes[i],shapes[i].xmin+1,shapes[i].ymin,array_pairs)
    end
    if (ry/self.cellSize > shapes[i].ymin)  then
      checks = checks + reportColPairs(self,shapes[i],shapes[i].xmin,shapes[i].ymin+1,array_pairs)
      if overlapEastBorder then
        checks = checks + reportColPairs(self,shapes[i],shapes[i].xmin+1,shapes[i].ymin+1,array_pairs)
      end    
    end
  end
  return array_pairs,checks
end

-- Returns the Spatial hash class
return setmetatable(SpatialHash,{__call = function(self,...) return SpatialHash:new(...) end})

--[[
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
--]]
