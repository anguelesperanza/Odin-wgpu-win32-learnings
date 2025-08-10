# Odin-wgpu-learnings
Hello Hello,

This is my repository for me to dump examples I create while learning WGPU in Odin in relation to Win32.
I am not an expert by any means in either WGPU or Win32 or Odin, so any and all examples should be taken with the finest grain of salt.
I am winging it -- these are examples I created while learning after all.

There is no saying how far this repository will go with examples; graphics programming is hard after all and I will drop it if gets
more frustraiting than it's worth learning -- but the repo will remain nonetheless

As is the case with my GDI learnings, numerous tools were used in creating these examples,
ranging from webites, other repositories, and AI tools as well. I try and credit when and where but I do forget at times.

There is no license for this repository; it's just a dump of examples I made, I'm not married to them one way or another.

==========================

Currenlt folders in repository

init-window -> Shows how to make a basic win32 window, init wgpu and connect the two together

triangle -> Shows how to render a triangle

vertex-buffer-rgb-triangle -> Shows how to use a vertex buffer to generate an rgb triangle

index-buffer-pentagon -> Shows how to use an index buffer to produce a shape (pentagon in this example)

index-buffer-rgb-quad -> Shows how to use an index buffer to produce an rgp quad (quad in this this example)

index-buffer-rgb-pentagon -> Shows how to use an index buffer to produce an rgb pentagon (quad in this this example)

texture-quad -> Shows how to render an image onto a quad (turn image into texture)
  -> This folder contains multiple images, board.png and quad.png are used for debugging to tell if an image is skwewd
    image.png is the actual image to use to convert to a texture
    You can use the debugging textures by changing the image that is loaded at the start of the main proc
