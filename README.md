# A software 3D rasteriser in Zig

## Features
* pipelines consisting of user defined Vertex and Fragment shaders
* attributes, uniforms, varyings
* projection matrices
* perspective correct varying interpolation
* depth buffers and testing
* nearest neighbour texture sampling
* tga image output

## TODO
* more texturing (bilinear sampling)
* mipmap selection

![cubes and ground plane (demonstrating texture aliasing)](cubes_and_plane_aliased.png)
![textured cubes](cubes_bw.png)
![cubes](cubes.png)
![a quad](quad.png)