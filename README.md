# My examples from learning WGPU through Odin

### Introduction
Learning graphics programming is hard.
Learning WGPU is even harder;
Learning WGPU in a language that's not rust, mind blowing.

Why? Cause there's practically nothing for learning WGPU. There's a few websites and videos, but nothing
to the extent of something like OpenGL. WGPU really expects you to understand the graphics pipeline, which I don't.
Or WebGPU, which I also don't know.

You see, I'm an idiot. I didn't realize how big of an undertaking this learning was was when I started.

I'm not a smart man, and my memory is not so great. So i've created this repo here: Odin-wgpu-win32-learnings
to track my learning of WGPU through Odin, but also, to document how WGPU works using Odin. 'Cause I'm not going
to remember how all of this works. Not right at least. Not for a while.

Originally just a place to hold the completed projects I did, I've decided to add an breakdown.md file to all of the
examples (currenlty a WIP progress). I hope that I can document at a high level what is needed for a WGPU project.
In doing so, getting started with WGPU will hopefully be less confusing and feel less like a daunting task. But also,
so I don't have to figure all of this out a second time (techincally a third time cause I redid the examples).

With the intro out of the way, let's talk about the format of the repository

### The Repository Format
Each example is stored in its own folder.

Each example will (eventually) have a breakdown.md file that is tailored the new concpets in that example.

I created each of these examples one after the other, building on top of what I learned from the previous example. As such, the
breakdown.md files will work the same way.

For example, in the init-window example, there's a breakdown.md file. In the next exampe, triangle, the breakdown.md file will
not cover window creation, just triangle stuff.

Because graphics programming is a huge monstrosity to try and tackle, these breakdown.md files are going to be long. And there's
a lot of reading involved. I wrote/am writting these with the intent to use them as reference when I forget stuff, but they're written
in the style of a tutorial to help make sure I can relearn things as needed. However as such, they can work as a tutorial.

Also because I only know how to write documentation in the style of a tutorial....so yeah, there's that.

Since the init-window is the first example, there going to be a lot of explaining in that one.
That's not to say the other examples won't be, but this one specifically will.
A lot of the patterns that WGPU uses for setting things up is pretty much the same accross the board, from what I've seen, but with different proc calls and such. So the later examples
after init-window will have a lot of that stuff ommitted to avoid repetition.


This is written in the guise of a tutorial, but it's really a series of refence docs to help me remember stuff ultimately.

### How to build and run these
In order to run these examples you need to download them first or clone the repository.

Once you do, just cd into the example and run:

```odin run .```

This will run the examples

### These examples currenlty in the repository

| Name                     | Description                                                     |
|--------------------------|-----------------------------------------------------------------|
|init-window               |Creates a window and connects it to WGPU                         |
|triangle                  |Creates a triangle                                               |
|vertex-buffer-rgb-triangle|Creates a triangle using a vertex buffer and makes it RGB colored|
|vertex-buffer-rgb-quad    |Creates a quad using a vertex buffer and makes it RGB colored    |
|vertex-buffer-rgb-pentagon|Creates a pentagon using a vertex buffer and makes it RGB colored|
|index-buffer-pentagon     |Creates a pentagon using an index buffer                         |
|texture-quad              |Creates a quad and assigns a texture to it                       |

### The Resources used while learning
Here you will find the resources I've used to help me learn WGPU

|Name                         |Link                                                  |Reason                                         |
|-----------------------------|------------------------------------------------------|-----------------------------------------------|
|Phind                        |https://www.phind.com/                                |Good for creating examples and debugging errors|
|Copilot                      |https://copilot.microsoft.com/                        |Good for creating examples and debugging errors|
|Chatgpt                      |https://chatgpt.com/                                  |Good for creating examples and debugging errors|
|Odin WGPU Examples Repository|https://github.com/odin-lang/examples/tree/master/wgpu|Was amazing when first getting started and having no idea what anything did or meant|
|Learn Wgpu                   |https://sotrh.github.io/learn-wgpu/                   |Main reference point and what's being used to compare against in terms of things working|

