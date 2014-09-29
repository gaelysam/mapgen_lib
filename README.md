# Features
## Noises
### mapgen.noise2d
To get a 2D perlin noise map.

Arguments :

* **minp** *(position)* : Minimal corner of the perlin noise map
* **maxp** *(position)* : Maximal corner of the perlin noise map
* **offset** *(number)* : The noise offset
* **scale** *(number)* : The scale of the noise
* **spread** *(table)* : This table has the same format than a position. It define how slow/fast the value changes in 2 dimensions
* **seed** *(number)* : Each seed generate a different noise
* **octaves** *(number)* : A high value result of more details but is slower
* **persist** *(number)* : Depth of the details evoked previously

Return :

* **noise** *(table)* : An array of values starting at index 1

### mapgen.noise3d
Same as above, but in 3D.

Arguments :

* **minp** *(position)* : Minimal corner of the perlin noise map
* **maxp** *(position)* : Maximal corner of the perlin noise map
* **offset** *(number)* : The noise offset
* **scale** *(number)* : The scale of the noise
* **spread** *(table)* : This table has the same format than a position. It define how slow/fast the value changes in 3 dimensions
* **seed** *(number)* : Each seed generate a different noise
* **octaves** *(number)* : A high value result of more details but is slower
* **persist** *(number)* : Depth of the details evoked previously

Return :

* **noise** *(table)* : An array of values starting at index 1

### VoxelArea:noise
It returns a perlin noise map from a voxel area.
Then you can use VoxelArea:index(pos) to get the noise value matching the position pos.

Arguments :

* **offset** *(number)* : The noise offset
* **scale** *(number)* : The scale of the noise
* **spread** *(table)* : This table has the same format than a position. It define how slow/fast the value changes.
* **seed** *(number)* : Each seed generate a different noise
* **octaves** *(number)* : A high value result of more details but is slower
* **persist** *(number)* : Depth of the details evoked previously

Return :

* **noise** *(table)* : An array of values starting at index 1

Equivalent in 2D : FlatArea:noise

## VoxelAreas
### VoxelArea:altitude
To get only the y coordinate (altitude) at index i, faster than `pos = VoxelArea:position(i)` if we want only the y.

Arguments :

* **i** *(number)* : index of the VoxelArea

Return :

* **alt** *(number)* : the y value (the altitude) of the position matching index i

### minetest.voxel_area
Just a shortcut for `VoxelArea:new({MinEdge = minp, MaxEdge = maxp})`

Arguments :

* **minp** *(position)* : The corner of the VoxelArea which has the smaller coordinates
* **maxp** *(position)* : The opposite corner

Return :

* **o** *(VoxelArea)* : The new voxel area

### FlatArea
Same but in 2D. It has the same methods than a VoxelArea except altitude.

### minetest.flat_area
Just a shortcut for `FlatArea:new({MinEdge = minp, MaxEdge = maxp})`.

Arguments :

* **minp** *(position)* : The corner of the VoxelArea which has the smaller coordinates
* **maxp** *(position)* : The opposite corner

Return :

* **o** *(FlatArea)* : The new voxel area

### mapgen.translate
Takes an index of area1 and return the index matching the same position for area2.

Arguments :

* **area1** *(VoxelArea or FlatArea)* : The first area (input)
* **area2** *(VoxelArea or FlatArea)* : The second area (output)
* **i** *(number)* : An index of area1 which will be convert to index of area2
* **alt** *(number)* : Only when area1 is a FlatArea and area2 is a VoxelArea. It is the altitude (y coordinate) of the point.

Return :

* **i** *(number)* : The index of area2 which matches the same position for area1

You can also use `VoxelArea:translate(area2, i)` or `FlatArea:translate(area2, i, alt)`.

## Map Metadata
You can store map metadata in the file mapgen.txt placed in the world folder. The 3 following functions are used to store these metadata. Not that these metadata are set on shutting down : if it crash, they aren't saved.

### mapgen.set_map_meta
To set to value the metadata with field as name.

Arguments :

* **field** *(string, number or boolean)* : The name of the metadata to set
* **value** *(table, string, number, boolean or nil)* : Value to give to the metadata

No return

### minetest.define_map_meta
Same as above, but don't change anything if this metadata is already defined.

Arguments :

* **field** *(string, number or boolean)* : The name of the metadata to set
* **value** *(table, string, number, boolean or nil)* : Value to give to the metadata

No return

### minetest.increment_map_meta
Increment the involved metadata by 1 (must be a number).

Arguments :

* **field** *(string, number or boolean)* : The name of the metadata to increment

No return

### minetest.get_map_meta
Returns the map meta with field as name.

Arguments :

* **field** *(string, number or boolean)* : The name of the metadata to get

No return

## Others mapgen-related features
### mapgen.get_voxel_manip
Return a VoxelManip object and his VoxelArea.

Arguments :

* **minp** *(position)* : minimal corner of the area
* **maxp** *(position)* : maximal corner of the area

Return :

* **vm** *(VoxelManip)* : The VoxelManip object, which has already read the chunk
* **area** *(VoxelArea)* : A VoxelManip matching the VM.

### mapgen.get_ids
Converts nodenames to content ids

Arguments :

* **node1**, **node2**, **node3** ... *(string or table)* : Name of the nodes to convert to ids, or table containing these names

Return :

* **id1**, **id2**, **id3** ... *(number or table)* : If number, the content id ; if table, array of ids, with exactely the same structure than the argument table

For example `mapgen.get_ids(nodename1, nodename2, {nodename3, {nodename4}, stuff = nodename5}, nodename6)` returns `id_of_node1, id_of_node2, {id_of_node3, {id_of_node4}, stuff = id_of_node5}, id_of_node6`

### mapgen.average_time
Returns average generation time

No arguments

Return :

* **t** *(number)* : The average generation time in seconds

## Others
### pos2d
Convert a standard pos to a 2D pos with `{x = pos.x, y = pos.z}`.

Arguments :

* **pos_in** *(position)* : The position to convert ; if already 2D, the same is returned

Return :

* **pos_out** *(2D position)* : The 2D position

### pos3d
Convert a 2D pos to 3D, reverse of the previous function

Arguments :

* **pos_in** *(2D position)* : The position to convert ; if already 3D, the same is returned
* **alt** *(number)* : Altitude (y coordinate) of your future 3D position

Return :

* **pos_out** *(position)* : The 3D position

### load_modfile
Loads a file in your mod.

Arguments :

* **path** *(string)* : Path of the file from the mod folder (for example `file.lua` or `scripts/generate.lua`)

No return

### mapgen.send
Send a message to the main player, or all players, and print it on debug.txt.

Arguments :

* **text** *(string)* : The text to send
* **all** *(boolean)* : If true, will be sent to all players, if false or omitted, only sent to the main player

No return

### math.round
Round a number to the nearest multiple.

Arguments :

* **n** *(number)* : The number to round
* **div** *(number)* : n is rounded to the nearest multiple of div ; if omitted, set to 1

Return :

* **rn** *(number)* : The rounded number

----------

# TO MAKE A MAPGEN :

Write a lua file which defines the following functions. These functions are not functions that mapgen_lib defines and you call, it's the contrary ! If you omit one of them, this poses no problem.

## mapgen.on_generated
Used to make the base map with the VoxelManipulator.

Arguments :

* **minp** *(position)* : The corner of the generated chunk which has the smallest coordinates
* **maxp** *(position)* : The opposite corner
* **data** *(table)* : A huge array containing the ids of all nodes in the chunk
* **param** *(table)* : Same as above, but contains the param (light) levels ; integers from 0 to 255 (day light + night light * 16)
* **param2** *(table)* : Same as above, but contains the param2 values
* **area** *(VoxelArea)* : A Voxel Area to help you ; you can use area:iterp(minp, maxp) or area:index(pos) for example
* **seed** *(number)* : The seed of the world ; currently a 32-bit integer

Return :

* **data** *(table)* : The content id array
* **param** *(table or boolean)* : The light data array ; if you returns the boolean true instead of the array, light is calculated automatically.
* **param2** *(table)* : Array containing the param2 values

## mapgen.after_generated
Called after the base map generation by the VoxelManip. Used to generate complementary structures like trees or villages.

Arguments :

* **minp** *(position)* : The corner of the generated chunk which has the smallest coordinates
* **maxp** *(position)* : The opposite corner
* **seed** *(number)* : The seed of the world ; currently a 32-bit integer

No return

## mapgen.spawn_player
Used to define where the player is spawned in the world. You can also generate structures like platforms by minetest.set_node.

Arguments :

* **player** *(ObjectRef)* : The player to spawn
* **seed** *(number)* : The seed of the world ; currently a 32-bit integer

Return :

* **pos** *(position)* : The position at which the player appears

## Params formspec
You can define mapgen.params_formspec, if any, it is shown after choosing the mapgen and before generating map. The sent fields are stored in metadata. To get the field which has been sent from a given widget, do `mapgen.get_map_meta("name_of_the_widget")`.

----------

When all is done, create a folder "mapgen" in your mod folder and put this lua file in it.
