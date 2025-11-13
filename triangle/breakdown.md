# Breakdown:  Triangle

### Introduction
The infamous triangle; everyone's first major step into graphics programming.
And I am no exception.

Given that a lot of the setup code was covered in init-window, that will not be covered
here. Instead, this breakdown will cover the neww stuff this file adds.

# The structure of this example
Unlike the init-window example, this triangle example ( and the others as well )
have logic broken up into different files.

The surface information remains in main.odin, although I should pull that out into it's own file at some point.
These are the files this example contains:

|File          |Description                                          |
|--------------|-----------------------------------------------------|
|main.odin     |The main source file where everything else connect to|
|pipeline.odin |Contains the logic for creating a pipeline           |
|primitive.odin|Contains the logic for creating a primitive          |
|shader.odin   |Contains the logic needed for the shader             |
|sahder.wgsl   |The shader                                           |

Technically, all this logic could go into the main.odin file but it becomes very difficult to manage and debug.
It was a nightmare when I got to the texture portion of the Learn WGPU tutorials because everything was in one file.
Small little tidbit; I did that tutorial 3 times before I manged to get my texture rendered. And in the process, I redid the other examples too.

# The Shader (shader.odin)
Shaders are GPU specific programs. They do things to the pixels on our screen.

We'll be using the shader going forward for every example to come, so may as well
get this out of the way first.

The shader below contains actions for our vertx and our fragment.
The vertex, or our points for our shapes, are defined and set here in this shader.
It also defines and creates our color data for our triangle that will be used by our fragment shader portion of the code.

The fragment shader, will run once for each pixel on the screen and determine what color that pixel is.

In a later example we'll pull this out into a seperate file and read it into the shader.

To be honest, I don't quite understand shaders myself yet so the best I can offer here is the code from
Learn WGPU github page that I used.

````
struct VertexPayload {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
};

@vertex
fn vs_main(@builtin(vertex_index) i: u32) -> VertexPayload {
    var positions = array<vec2<f32>, 3>(
        vec2<f32>(-0.75, -0.75),
        vec2<f32>( 0.75, -0.75),
        vec2<f32>(  0.0,  0.75),
    );

    var colors = array<vec3<f32>, 3>(
        vec3<f32>(1.0, 0.0, 0.0),
        vec3<f32>(0.0, 1.0, 0.0),
        vec3<f32>(0.0, 0.0, 1.0),
    );

    var out: VertexPayload;
    out.position = vec4<f32>(positions[i], 0.0, 1.0);
    out.color = colors[i];
    return out;
}

@fragment
fn fs_main(in: VertexPayload) -> @location(0) vec4<f32> {
    return vec4<f32>(in.color, 1.0);
}
````
Now that we have the shader file, we're going to need to load that into odin.
There's two way you can do this, either as a file, or by embedding it directly into the code.

I loaded it via a file as that makes changing it a lot easier.

Now for full transparency, I don't fully understand how the context system works in Odin (or in general).
If we try and load our shader after set the context, it reads in an empty file.

So in our main proc, before we set the context we're gonna load in the shader file: ``shader.wgsl``

``shader:string = load_shader(filename = "shader.wgsl")``

This calls a proc called load_shader. You can find this in the ``shader.odin`` file. This is a custom proc.
This proc uses the os2 stuff so when calling ``os2.read_entire_file_from_path`` in addtion to the name,
we also need to supply the allocator.

Important thing to note: instead of using our state's ctx value for this, we're going to use the load_shader's default context's allocator.
Using the states ctx value caused the application crash. Probably cause I'm not using it correctly.

From there, it's just standard Odin loading a file.

The following logic described going forward for this Shader portion of the breakdown is located in:
``shader.odin`` in the creat_shader_module proc

We know have our shader code loaded into memory. But we still have no shader for the GPU to use.
To fix this, we need to call a proc called ``DeviceCreateShaderModule``

````
DeviceCreateShaderModule :: proc(
  device: Device,
  descriptor: /* const */ ^ShaderModuleDescriptor
) -> ShaderModule ---
````

Notice how this proc follows the very similair proc signatures as when we creates our surface, our queue, etc in the init-window,
this will be the case for pretty much all of the examples going forward.

However, as with all the other examples going forward, these ``DeviceCreate...`` procs
are goign to be returned by my custom procs. I did this to reduce the amount of stuff going on in the main.odin file.

The device field is just our `state.device`.

The descriptor follows the same logic our surface's descriptor does. Only instead of putting it all into one struct,
it's broken down into smaller chuncks. Done this way for the sake of learning. For cohesion and maybe even best practice, probably
a good idea to not do this.

We set this before our render loop, but after we call `SurfaceConfig` in main.odin.


# Pipeline Layout (pipeline.odin)
Before we get to the pipeline, we need a pipeline layout. This is how the GPU knows how interpret
the things we're sending through our render pipeline:


````
DeviceCreatePipelineLayout :: proc(
  device: Device,
  descriptor: /* const */ ^PipelineLayoutDescriptor
) -> PipelineLayout ---

````

The proc is the same as usual. For the descriptor, you're only going to want to pas the label value to it:

````
	pipeline_layout_desc:wgpu.PipelineLayoutDescriptor = {
		label = "Main Pipeline Layout Desc",
	}

````

We are then going to set our state's pipeline_layout to this value. The same splace as the shader module in main.odin.


# Pipeline
Learn WGPU (https://sotrh.github.io/learn-wgpu/beginner/tutorial3-pipeline/) explains the pipeline better than I can:

>If you're familiar with OpenGL, you may remember using shader programs.
You can think of a pipeline as a more robust version of that.
A pipeline describes all the actions the GPU will perform when acting on a set of data.
In this section, we will be creating a RenderPipeline specifically.

Essentially, it's a blueprint of sorts that our GPU will use to decide how to use all the data we're feeding it.
(confusing when compared with the pipeline layout if I do say so myself)

The proc to create the pipeline
````

DeviceCreateRenderPipeline :: proc(
  device: Device,
  descriptor: /* const */ ^RenderPipelineDescriptor
) -> RenderPipeline ---

````

Unlike the pipeline layout however, the descriptor is actually used.

````
RenderPipelineDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	label: StringView,
	/* NULLABLE */ layout: PipelineLayout,
	vertex: VertexState,
	primitive: PrimitiveState,
	/* NULLABLE */ depthStencil: /* const */ ^DepthStencilState,
	multisample: MultisampleState,
	/* NULLABLE */ fragment: /* const */ ^FragmentState,
}

````
We don't use nextInChain here.

The proc looks like this:

````
	render_targets:[1]wgpu.ColorTargetState = {create_render_targets()}

	vertex_state:wgpu.VertexState = {
		module = state.module,
		entryPoint = "vs_main",
	}
	
	fragment_state: wgpu.FragmentState = {
		module = state.module,
		entryPoint = "fs_main",
		targetCount = 1,
		targets = raw_data(render_targets[:]),
	}

	sample_state:wgpu.MultisampleState = {
		count = 1,
		mask = 0xFFFFFFFF,
		alphaToCoverageEnabled = false,
	}

	pipeline_desc:wgpu.RenderPipelineDescriptor = {
		label = "Main Pipeline",
		layout = state.pipeline_layout,
		vertex = vertex_state,
		fragment = &fragment_state,
		primitive = primitive_triangle(),
		multisample = sample_state,
	}
	
	return wgpu.DeviceCreateRenderPipeline(
		device = state.device,
		descriptor = &pipeline_desc
	)// -> RenderPipeline

````
There's a lot going on here; but the tl:dr is we create a vertex state and a fragment state.
both have an entry point that's the `fn` name in shader.wgsl. The module for these is our shader module we created.

The fragment state does need targets. This `targets` is a Multipointer. So we need to create
and array that is one element big and of type ColorTargetState.

`render_targets:[1]wgpu.ColorTargetState = {create_render_targets()}`


All create_render_targets() does is return a ColorTargetState that has the format.BGRA8Unorm
and a write mask of .ColorWriteMaskFlags_All,

```
 return wgpu.ColorTargetState {
	format = .BGRA8Unorm,
	writeMask = wgpu.ColorWriteMaskFlags_All,
}
```

After that, we create are MultisampleState.
Then we get our primitive. The primitive is the shape that's going to be used to make up the triangle.
This primitive is in `primitive.odin`


````
return wgpu.PrimitiveState {
	topology = .TriangleList,
	stripIndexFormat = .Undefined,
	frontFace = .CCW,
	cullMode = .Back,
	unclippedDepth = false,
}

````
The toplogy is a .TriangleList.
FrontFace is .CCW, which is short for Counter Clock Wise.
While not super important right now, when we go to render indexes and vertex buffers,
this will matter. It tells the GPU how to interpret our vertices (however that's not in this example).

cullMode is .Back and unclippedDepth is false.

After all that is done and set, boom, pipeline created
All you gotta do is assing our state struct's pipeline value to the returned created pipeline.
Same as the shader and the pipeline layout.


## Render (main.odin)
So back to our render section.  After we start our command ecnoder's render pass,
we'll need to set our pipeline.

```
wgpu.RenderPassEncoderSetPipeline(
	renderPassEncoder = pass,
	pipeline = state.pipeline, 
)

```

And underneath that we'll need tell our render command encoder's render pass what we want to draw:
````
wgpu.RenderPassEncoderDraw(
	renderPassEncoder = pass,
	vertexCount = 3,
	instanceCount = 1,
	firstVertex = 0,
	firstInstance = 0
)
````

Essentially, we're drawing a shape with 3 vertex points (vertexCount),
we're only drawing one copy of this shape (instanceCount)
the first vertex is at slot 0 (firstVertex),
and we're going to draw the first instance (firstInstance)

Once we do that, we want to release our command encoders render pass after we finish using it.

````
wgpu.RenderPassEncoderEnd(pass)
wgpu.RenderPassEncoderRelease(pass)
````

## Clean Up
Like last time how we added releases to our code after we were done with the window but before it closes,
we have to release our render pipeline, the pipeline layout, and the shader module

````
wgpu.RenderPipelineRelease(renderPipeline = state.pipeline)
wgpu.PipelineLayoutRelease(pipelineLayout = state.pipeline_layout)
wgpu.ShaderModuleRelease(shaderModule = state.module)
````
And with that, the window should run an create a triangle.
The triangle should be RGB.
