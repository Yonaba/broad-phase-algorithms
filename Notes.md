broad-phase-algorithms
======================

Various space partitioning techniques implemented in [Lua](http://www.lua.org) for faster broad-phase collision detection :

##What for ?
[Collision detection](http://en.wikipedia.org/wiki/Collision_detection) is a fundamental topic, feaured in a wide range of applications, such as computer games,
physically-based simulations, etc. Although simple with fewer number of entities, it can turn into a bottleneck,
especially when dealing with growing numbers of moving objects.

Suppose that we are rendering 100 objects, and we need to check if they are colliding (i.e overlapping or not).
The first common (and naive) approach would be testing each objects against the others:

for i = 1,100 do
  for j = 1,100 do
    if i~=j then
	  collisionTest(object[i], object[j])
	end
  end
end  

That will result in __9900__ collision tests.
A second approach (a bit more clever) would take advantage of the __commutative nature__ of collisions (i.e *A-collides-B* equals *B-collides-A*).
Therefore, the test above could be reduced to :

for i = 1,99 do
  for j = i,100 do
    collisionTest(object[i], object[j])
  end
end  

That will result in __4950__ collision tests. This is better, but what if we could narrow down __a lot more__ else the number of collision checks ?

##Broad-phase collision detection
To drastically reduce the number of collision checks we will have to perform, we can perform a __broad-phase__.
This step identifies __groups of objects that may be colliding__ and excludes those which are not.
There are various __broad-phase processing__ techniques. Find some implemented in [Lua] in this repository.
See (Readme.md]() for more details and examples of use

* [Spatial Hashes/Uniform-grid](http://www.gamedev.net/page/resources/_/technical/game-programming/spatial-hashing-r2697)


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