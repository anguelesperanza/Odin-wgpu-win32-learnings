# Breakdown: Init Window

### Introduction
To window or not to window; that is the question. The answer is of course, windows!!!!

Really bad puns aside, there are a few different ways to create a window in Odin; Win32, Xlib, SDL2, SDL3, GLFW. For the sake of this
repository and it's examples, I'll be using Win32 to create the window and connect it to WGPU. For odin, there's
already examples on using GLFW and SDL3 found in the official Odin WGPU examples repo:

https://github.com/odin-lang/examples/tree/master/wgpu

If you're interested in using either of those, then I suggest you check out those examples then come back here.

And since there's already examples for those and not Win32, I figured I'd use Win32.

Withouth further adeu however, let's get on to the actual breakdown of this

## The imports
So for this we're going to handle are the imports we'll need for this file
```
import "core:fmt" // Used to print stuff out for debugging 
import "vendor:wgpu" // Our WGPU import
import win "core:sys/windows" // Used to make the window
import "base:runtime" // Used to handle the context
```
Due to Odin being all batteries included, there's no external dependencies to install

## Setting the context
While we go about using WGPU, we're going to want to keep our context consistant.
To do that, we're going to set our stat's ctx field to our main procs context.

``context = state.ctx``

Because the contex is implicitly passed through every procedure, we don't need to do any fance to access it. It's always there, watching...waiting...lerking....

## Creating the Window
There is a lot when it comes to creating a window in Win32 so first I'll provide the working code
for the window. Since the focus is on WGPU, I'm just going to skim over what this all does.

```
package main

import "core:fmt" // Used to print stuff out for debugging 
import "vendor:wgpu" // Our WGPU import
import win "core:sys/windows" // Used to make the window
import "base:runtime" // Used to handle the context

running := true
winsize:[2]u32 = {640, 480}

// Callback function for handling events
window_event_proc :: proc "stdcall" (
	window: win.HWND,
	message: win.UINT,
	wParam: win.WPARAM,
	lParam: win.LPARAM,
) -> win.LRESULT {
	context = runtime.default_context()

	switch message {
		case win.WM_SIZE:
			win.OutputDebugStringW(win.L("WM_SIZE\n"))
		case win.WM_DESTROY:
			running = false
		case win.WM_ACTIVATEAPP:
			win.OutputDebugStringW(win.L("WM_ACTIVATEAPP\n"))
		case win.WM_CREATE:
			win.OutputDebugStringW(win.L("WM_CREATE\n"))
		case win.WM_PAINT:
		case win.WM_KEYDOWN:
			// The event for handling key presses (like escape, shift, etc)
			switch wParam {
				case win.VK_ESCAPE:
					running = false
			}
	}

	return win.DefWindowProcW(window, message, wParam, lParam)
}

main :: proc() {
  window_instance := win.HINSTANCE(win.GetModuleHandleW(nil)) // Create Instance

  // create window class
  window_class := win.WNDCLASSW {
  	style = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW,
  	lpfnWndProc = window_event_proc, // [] created callback function
  	hInstance = window_instance,
  	lpszClassName = win.L("WgpuWindowClass"),		
  }

  win.RegisterClassW(lpWndClass = &window_class) // Register the class

  // Create window
  window := win.CreateWindowExW(
  	dwExStyle = 0,
  	lpClassName = window_class.lpszClassName,
  	lpWindowName = win.L("WGPU Init Window"),
  	dwStyle = win.WS_OVERLAPPED | win.WS_VISIBLE | win.WS_SYSMENU,
  	X = 0,
  	Y = 0,
  	nWidth = i32(winsize[0]),
  	nHeight = i32(winsize[1]),
  	hWndParent = nil,
  	hMenu = nil,
  	hInstance = window_instance,
  	lpParam = nil,
  )

	message:win.MSG
	for running {
		if win.PeekMessageW(lpMsg = &message, hWnd = nil, wMsgFilterMin = 0,wMsgFilterMax = 0,wRemoveMsg = win.PM_REMOVE){
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		}
	}
}
```
Like I said, a lot is going on here.

So essentially:

We create a window instance, a window class and then register that window class.
Well be needing this window instance when it comes to connecting to WGPU.

Then we create a new window
using the ```CreateWindowExW``` procedure. Then we have our game loop that we'll use for rendering using WGPU.


We store ```running``` as a global variable as we'll be using it as the condition for the for loop.
``Winsize`` is stored as a global.

We're calling ```PeekMessageW``` in order to see if there are any events for the window to run. Calling this instead of
``GetMessageW``should be non blocking as it just looks to see if there's an event, and not wait for an event like ``GetMessageW`` does.

Finally there's ```window_event_proc ```. The is the callback procedure that Win32 uses for events.
The only important part here for now is this:

```
case win.WM_KEYDOWN:
// The event for handling key presses (like escape, shift, etc)
	switch wParam {
		case win.VK_ESCAPE:
			running = false
}
````
This just sets running to false when the escape key is pressed; which in turn, ends our loop, thus,
ending the application and closing our program.

Now with that out of the way, onto the WGPU stuff.

## WGPU: state struct
There's going to be a lot of stuff to setup in the beginning (well all the time I guess with WGPU)
so having a single struct to manage it all is a life saver!

Originally copied from the official Odin Example for WGPU and SDL3, we have this modified state struct here:

```
state: struct {
	ctx:            runtime.Context,

	// All of the below are of type: distinct rawptr
	instance:       wgpu.Instance,
	surface:        wgpu.Surface, 
	adapter:        wgpu.Adapter, 
	device:         wgpu.Device,
	config:         wgpu.SurfaceConfiguration,
	queue:          wgpu.Queue,
	module:         wgpu.ShaderModule,
}
	
```
This struct is a global struct so it goes outside the main proc. Because I'm only focused on using Win32, I didn't need any of the OS stuff the official examples had.
This struct does layout a good overview of what we'll need.

An important thing to note is that all of the items in this struct (with the exception of ctx)
are all of type: ``distinct rawptr``.

``instance`` is our instance to WGPU.

``surface``  is the area of our window that we'll be rendering the graphics to.

``adapter``  This will be our computer's actual GPU.

``device``   This (despite being called a device) will be what we use to gather our commands for the GPU.

``config``   A config for the surface.

``queue``    This is used to send our gathered commands to our GPU.

``module``   This is the shader.

This is all you'll need to get a basic window connection setup


## WGPU: Creating an Instance
First up is creating an instance in WGPU.

Now this, the surface and the adapter all come after creating the window
```
state.ctx = context

state.instance = wgpu.CreateInstance(nil)
if state.instance == nil{
	panic("WebGPU (WGPU) is not supported")
}
````

This all goes in the main proc. I have it set after ``window := win.CreateWindowExW``
We're setting the context here. This is going to be useful for our callback procs later

Then we call ``wgpu.CreateInstance(nil)`` to create a new instance and assign the result to state.instance
We'll check if it's nil or not. If so, panic as we cannot run WGPU on the OS!

There; instance has been created. Eazy Peezy Lemon Squeezy.

## WGP: Creating the Surface Part 1
You'll find that a lot of WGPU's create procs follow a simliar signature: 
A distinct rawptr and a pointer to a descriptor for distinct rawptr we're creating.
They return the distict rawptr of the thing they're creating.

Take the instance create surface proc:

``InstanceCreateSurface :: proc(instance: Instance, descriptor: /* const */ ^SurfaceDescriptor) -> Surface --- ``

This takes an instance rawptr, and a descriptor for our surface. And returns our surface.

This ends up looking a little complicated once it's all put together though.

```
state.surface = wgpu.InstanceCreateSurface(
	instance = state.instance,
	descriptor = &wgpu.SurfaceDescriptor {
		nextInChain = &wgpu.SurfaceSourceWindowsHWND {
			chain = wgpu.ChainedStruct {
				sType = .SurfaceSourceWindowsHWND,
			}, // end of wgpu.ChainedStruct
			hinstance = window_instance,
			hwnd = window,
		}, // end of &wgpu.SurfaceSourceWindowsHWND
	}, // end of &wgpu.SurfaceDescriptor
)// end of wgpu.InstanceCreateSurface

```

We set our state struct's surface to be the result of this proc. Our state's isntance (our created WGPU instance)
is the instance value we'll be using in this proc. The descriptor is where things get a little complicated.


So this is what the ``SurfaceDescriptor`` struct looks like:

```
SurfaceDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	label: StringView,
}
```
It takes a nextInChaint value, which is a pointer to a ChainedStruct and a label.
I recommend always putting a label value. It's a ``StringView`` type but that's really just a string,
so just put a string in for that field. When you evntually program a bug and WGPU crashes (as I've done many times); the label will tell you where it crashed.

The nextInChain is the confusing part. Admittidly, I do not know what nextInChain means or is supposed to do.
But, there are a bunch of structs that have ``using chain: ChainedStruct in them. This is what the nextInChain
is looking for. Not the actual ChainedStruct.

Let's look at this struct here:

```
SurfaceSourceWindowsHWND :: struct {
	using chain: ChainedStruct,
	hinstance: rawptr,
	hwnd: rawptr,
}
```

This is the struct that this nextInChain is looking for.
It's using ChainedStruct, which means this struct, has the values the ChainedStruct has as well.

This needs three peices of info:

``chain`` is the actual Chained struct:

```
ChainedStruct :: struct {

	next: ^ChainedStruct,
	sType: SType,
}
```

The ``next`` value can be ignored. The sType is an enum that has the same names as the structs that are using the ChainedStruct.
So for the surface, there is an sType enum value called ``SurfaceSourceWindowsHWND``. It is the same name as the struct.
So we use that enum value


``hinstance`` is the instance to the window we created when setting up the Win32 window: ``window_instance``

``hwnd`` is the window we created after registering the class: ``window``

And like that, the surface for our WGPU intance has been created.


I've noticed that at least early on, a lot of WGPU is just doing what we did to create the surface, just a bunch of times
to create the other things that we need. Either using the device, or the queue primarily (not always as is the case with creating the surface). But it's just a lot of the same thing.

We need to create something; that something needs a descriptor --> It is that descriptor though, where things start to get complicated fast.

You may have noticed that this is part 1 of creating the surface. Well, we can't set the surface configuration until we create our device.
So part 2 is later down this page.


## WGPU: Requesting the Adapter
Because the Adapter is our actual GPU that sits in our computer. Or if you're like me, my APU on my Framework, we don't techincally
create it since it already exists. Instead, we just request access to it. Specifically, we request that our WGPU instance has access to our GPU.

I wish I could tell you it's as simple as just calling the proc, but alas, I would be lying:


```
InstanceRequestAdapter :: proc(
	  instance: Instance,
		/* NULLABLE */ options: /* const */ ^RequestAdapterOptions,
		callbackInfo: RequestAdapterCallbackInfo
) -> Future ---
```

That proc has a bit going on with it. So first off, it takes our WGPU instance, the same instance we used
when creating our surface.

The options argument, which can be nullable, takes a pointer to the RequestAdapterOptions struct:

```
RequestAdapterOptions :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	featureLevel: FeatureLevel,
	powerPreference: PowerPreference,
	forceFallbackAdapter: b32,
	backendType: BackendType,
	/* NULLABLE */ compatibleSurface: Surface,
}
```
Thankfully, for this struct, the only value we care about is the last one, the nullable: ``compatibleSurce``.
And all this takes is our surface we created earlier. Everything else we can ignore for the time being.
WGPU will figure out things like power preference and such behind the scenes so we don't need to fill it out.

Is it a good idea to fill this stuff out? Probably? But the Learn WGPU Github page didn't go over it.

The last part of this proc is the ``callbackInfo`` field.

```
RequestAdapterCallback :: #type proc "c" (
	status: RequestAdapterStatus,
	adapter: Adapter,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr
)
```
WGPU is going to use this callbackProc when trying to request the adapter. We don't have to worry about passing
arguments into it, but we do have to create the proc with the same proc signature.

I called mine on_adapter. Essentally, if the status argument failed, we panic. Otherwise, we set the state's adapter to the
adapter received by the callback procedure.

```
on_adapter :: proc "c" (status: wgpu.RequestAdapterStatus, adapter: wgpu.Adapter, message:wgpu.StringView, userdata1:rawptr, userdata2:rawptr){
	/*Requesting an instance adapater requires a callback proc
	This is that callbakc proc*/
	context = state.ctx
	if status != .Success || adapter == nil {
		fmt.panicf("Request Adapter Failure: [%v] %s", status, message)
	}

	state.adapter = adapter
}

```
When it's all said and done: this is what you're InstanceRequestAdapter should look like:

```
// Handle to our graphics card
wgpu.InstanceRequestAdapter(
	instance = state.instance,
	options = &{compatibleSurface = state.surface},
	callbackInfo = {callback = on_adapter},
)
```

And like that, you've requested access to the GPU and recieved the adapter for it.

## WGPU: Requesting the Adapter Device
Now that we have the adapter, we have to request access to the ``device``, that is to say, the thing that will
gather all of our commands we want to send to the GPU. This doesn't send them to the GPU, that's the job of the Queue,
but this puts them all in a neat little package.

Well, it does more than that but for this example that's what we're primarily using it for.

It's very simliar to requesting the adapter.

```
	wgpu.AdapterRequestDevice(
		adapter = state.adapter,
		descriptor = nil,
		callbackInfo = {callback = on_device},
	)
```

It will use the adapter we received, it has no descriptor (thankfully) and has it's own callback proc:


```
RequestDeviceCallback :: #type proc "c" (
	status: RequestDeviceStatus,
	adapter: Device,
	message: StringView,
	userdata1: rawptr,
	userdata2: rawptr
)
```
It's pretty much the same procedure signature with only the first to argumetns being diffent
Same logic applies; check if stats was success full or we don't already have a device, and if so,
assign the device received by the callback proc to our state's device

```
on_device :: proc "c" (status: wgpu.RequestDeviceStatus, device: wgpu.Device, message: string, userdata1, userdata2: rawptr) {
		context = state.ctx
		if status != .Success || device == nil {
			fmt.panicf("request device failure: [%v] %s", status, message)
		}
		state.device = device 
}

```

## WGPU: Get Queue
Now that we have the adapter and our device, we need a way to send commands our device gets, to the GPU.

That is called the ``Queue``. And thankfully, setting it up is super easy.

``DeviceGetQueue :: proc(device: Device) -> Queue ---``

Pretty much, just call ``DeviceGetQueue``, pass our device as the argument, and set the returned value to our state's
queue.

``state.queue = wgpu.DeviceGetQueue(device = state.device)``

## WGP: Creating the Surface Part 2 (Surface Configuration)
Oh yeah, now we're on to part 2 of setting up the WGPU surface.

```
SurfaceConfiguration :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	device: Device,
	format: TextureFormat,
	usage: TextureUsageFlags,
	width: u32,
	height: u32,
	viewFormatCount: uint,
	viewFormats: /* const */ [^]TextureFormat `fmt:"v,viewFormatCount"`,
	alphaMode: CompositeAlphaMode,
	presentMode: PresentMode,
}
```
From this configuration, we only care about the following fields:

``usage``

``format``

``width``

``height``

``presentMode``

``device``



``width`` and ``height`` is the width and height of our window so ``Winsize``.

``device`` is our device we created earlier and stored in our struct.

``usage`` is a bit_set of the TextureUsage enum. That's going to be set to ``{.RenderAttachment}``.

``format`` is goign to be set to ``.BGRA8Unorm``.

``presentMode`` is going to be ``.Fifo``.

When put all together, the configuration will look like this:

```
surface_config:wgpu.SurfaceConfiguration = {
	usage = { .RenderAttachment},
	format = .BGRA8Unorm,
	width = winsize[0],
	height = winsize[1],
	presentMode = .Fifo,
	device = state.device,
}

```
Last part for the surface is to set the surface configuration

``SurfaceConfigure :: proc(surface: Surface, config: /* const */ ^SurfaceConfiguration) --- ``

It just takes the surface and config we just created

``wgpu.SurfaceConfigure(surface = state.surface, config = &surface_config)``

And with that, the surface is fully created. However, we still have some more things to do.

## WGPU: The Render Loop
So close to the home stretch you can almost taste it. There's just this part and the clean up.
All the code in this section is is going into the render loop, so here: 
```
	message:win.MSG
	for running {
		if win.PeekMessageW(lpMsg = &message, hWnd = nil, wMsgFilterMin = 0,wMsgFilterMax = 0,wRemoveMsg = win.PM_REMOVE){
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		}

		// THE LOGIC GOES UNDERNEATH THIS LINE
		
	}
}
```


First thing we're going to do is get our surface texture for the current frame.

The surface texture is our GPU's representation of the area we're rendering on; the canvas, the drawable area,
a sheet of paper you put stuff on (I'm runing out of analogies). Essentially, the things we render are displayed on the
surface texture to the user.

To get the surface texture for the current frame, we need to use this procedure.

``SurfaceGetCurrentTexture :: proc "c" (surface: Surface) -> (surface_texture: SurfaceTexture)``

We'll need this returned SurfaceTexture so make sure to save it to a variable.

````
surface_texture:wgpu.SurfaceTexture

texture_view:wgpu.TextureView // we'll talk about this later
view_desc:wgpu.TextureViewDescriptor // we'll talk about this later

surface_texture = wgpu.SurfaceGetCurrentTexture(surface = state.surface)
````
SurfaceTexture is a struc tthat returns the following:

```
SurfaceTexture :: struct {
	nextInChain: ^ChainedStructOut,
	texture: Texture,
	status: SurfaceGetCurrentTextureStatus,
}
```
We need to check the surface texture to make sure the result we got is something that we can use.
If not, we need to handle what happens when, for example, we lose a frame, or it somehow timesout.

For that, we need the status field of our surface texture, which is an enum. Since it's an enum,
it's easy to use a switch statement to check the results. 

```
switch surface_texture.status {
case .SuccessOptimal, .SuccessSuboptimal:
	// All good, could handle suboptimal here.
case .Timeout, .Outdated, .Lost:
	// Skip this frame, and re-configure surface.
	if surface_texture.texture != nil {
		wgpu.TextureRelease(surface_texture.texture)
	}
	
	new_surface_config:wgpu.SurfaceConfiguration = {
		usage = { .RenderAttachment},
		format = .BGRA8Unorm,
		width = winsize[0],
		height = winsize[1],
		presentMode = .Fifo,
		device = state.device,
	}
	
	wgpu.SurfaceConfigure(surface = state.surface, config = &surface_config)
	
	return
case .OutOfMemory, .DeviceLost, .Error:
	// Fatal error
	fmt.panicf("[triangle] get_current_texture status=%v", surface_texture.status)
}

```
To summarize what this does; if we get the success options, we're all good.

If the frame times out, is outdated or lost, we first check to make sure we have a texture for the current frame, and if we do,
we release it from memory, then we create a new config for our surface, and assign that config to our surface. This is
the same logic we used the first time, no major difference execpt we're using the new surface config

If we run out of memory, lost our device, or just had an error, than panic and exit.

Once we get the surface texture for our current frame, we then need a way to access that texture's data.
This is done using
 ````
TextureCreateView :: proc(
	texture: Texture,
	/* NULLABLE */ descriptor: /* const */ ^TextureViewDescriptor = nil
) -> TextureView ---
````

It looks complicated but it's really simple. The texture argument is the texture field of our texture surface struct, and there's no descriptor, so that stays as nil

````
texture_view = wgpu.TextureCreateView(
	texture = surface_texture.texture,
	descriptor = nil
)
````
With the texture view, we can access the data in the texture. Now we have to compile all the GPU commands we want the GPU to run on this texture.
The device is responsible for sending the commands to the GPU, however the specific part of the device that gathers these commands to send to the GPU
is called the ``CommandEncoder``. We'll use the device to create this command encoder.

````
DeviceCreateCommandEncoder :: proc(
	device: Device,
	/* NULLABLE */ descriptor: /* const */ ^CommandEncoderDescriptor = nil
) -> CommandEncoder ---
````

For this, we can leave the descriptor as nil, and only pass our state's device that we created earlier:

````
encoder := wgpu.DeviceCreateCommandEncoder(
	device = state.device,
	descriptor = nil,
)
````
We can get our surface's texture, access it's data to do stuff to it, and gather commands to send to the GPU.
Now we need to start using some commands so we can gather then and do stuff to our surface texture.

``CommandEncoderBeginRenderPass :: proc(commandEncoder: CommandEncoder, descriptor: /* const */ ^RenderPassDescriptor) -> RenderPassEncoder --- ``

This is the first command we'll be using. This tells the GPU you want to start drawing things to the screen. 

It takes our command encoder we creates above, as well as a descriptor. It returns a RenderPassEncoder so make sure
to save that value to a variable.

````
RenderPassDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	label: StringView,
	colorAttachmentCount: uint,
	colorAttachments: /* const */ [^]RenderPassColorAttachment `fmt:"v,colorAttachmentCount"`,
	/* NULLABLE */ depthStencilAttachment: /* const */ ^RenderPassDepthStencilAttachment,
	/* NULLABLE */ occlusionQuerySet: QuerySet,
	/* NULLABLE */ timestampWrites: /* const */ ^RenderPassTimestampWrites,
}
````
From this struct, we're only going to worry about:
1. colorAttachmentCount
2. colorAttachments
3. label 

The ``label`` is the same as always, but a string with something easy to ID it wil.
The ``colorAttachmentCount`` is going to be 1, becuase we are only going to have one colorAttachment.
The ``colorAttachments`` is an Multipointer / array to a series of ``RenderPassColorAttachment`` structs.


````
RenderPassColorAttachment :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/* NULLABLE */ view: TextureView,
	depthSlice: u32,
	/* NULLABLE */ resolveTarget: TextureView,
	loadOp: LoadOp,
	storeOp: StoreOp,
	clearValue: Color,
}
````
The ``view`` field is the texture view we created earlier
The ``loadOp`` is an enum value: ``.Clear``. This clears the screen before we start drawing on it.
The ``storeOp`` is an enum value: ``.Store``. This keeps things we asks the GPU to render, on the screen.
The ``clearValue`` is going to be a ``Color`` value, which is really just a ``[4]64`` value.
This is going to be the background color of our window/surface texture.

This is all the drawing the example does. So now, we need to tell the GPU we're done drawing things this frame.

``RenderPassEncoderEnd :: proc(renderPassEncoder: RenderPassEncoder) --- ``

We can do that by using this proc here. We just pass the render pass encoder we created
when calling the ``CommandEncoderBeingRenderPass`` procedure.

There's no other commands we'll be executing this example, so we can tell the command encoder we're done sending
commands this from as well:

``CommandEncoderFinish :: proc(commandEncoder: CommandEncoder, /* NULLABLE */ descriptor: /* const */ ^CommandBufferDescriptor = nil) -> CommandBuffer --- ``

There's no descriptor so that can stay as nil, and our ``CommandEncoder`` is the command encoder we created earlier.
This will return a ``CommandBuffer``. Save that to a variable as well use with the queue next.



All together, your command to for drawing/should look something like this:

Update 11/13/2025: Due to recent update to WGPU bindings, color_attachment needs to specify
the depthSlice with a value. Since this is just an empty window / 2D, wgpu.DEPTH_SLICE_UNDEFINED must be used.
As the WGPU code base has changed this to be a rust Some(u32) type, and if it's not 3D, this value must be not be number
There's probably a more technical reason, I just don't get it.


````
color_attachment:wgpu.RenderPassColorAttachment
color_attachment.view = texture_view
color_attachment.loadOp = .Clear
color_attachment.clearValue = {0.2, 0.2, 0.4, 1.0}
color_attachment.storeOp = .Store
color_attachment.depthSlice = wgpu.DEPTH_SLICE_UNDEFINED

render_pass:wgpu.RenderPassDescriptor
render_pass.colorAttachmentCount = 1
render_pass.colorAttachments = &color_attachment
render_pass.label = "Render Pass Descriptor"

pass:wgpu.RenderPassEncoder = wgpu.CommandEncoderBeginRenderPass(
	commandEncoder = encoder,
	descriptor = &render_pass
)

wgpu.RenderPassEncoderEnd(pass)

cmd_buffer:wgpu.CommandBuffer =	wgpu.CommandEncoderFinish(
	commandEncoder = encoder,
	descriptor = nil
)
````

Now that we have all the commands we want to send to the GPU in this example,
we have to actually send them to the GPU.

``QueueSubmit :: proc "c" (queue: Queue, commands: []CommandBuffer)``

Using this proc here, we can do just that. It takes our stats queue, and teh command buffer we just created.

``wgpu.QueueSubmit(queue = state.queue, commands = {cmd_buffer})``

We've sent our commands to the GPU, now it's time to tell the GPU "Hey, show me the stuff".

``SurfacePresent :: proc(surface: Surface) -> Status ---``

This just takes our state's surface.

With all that being done, we need to release our texture view, our texture, and our command buffer.
We don't want to carry those over into the next frame after all.

```
wgpu.TextureViewRelease(textureView = texture_view)
wgpu.TextureRelease (texture = surface_texture.texture)
wgpu.CommandBufferRelease(cmd_buffer)
````
This will free those up. since it's thre very simliar procs, I just shared the code I wrote rather than the proc itself.

## WGPU: The Clean Up
And now we're at the home stretch.

We've connected our Win32 Window to WGPU, send some commands to the GPU to draw. We've finished our render loop
and are ready to close out the application.

Now we have to release our Device, Adapter, Surface and instance.
This code goes before the final } in the main proc.

````
// Release resources
wgpu.DeviceRelease(device = state.device)
wgpu.AdapterRelease(adapter = state.adapter)
wgpu.SurfaceRelease(surface = state.surface)
wgpu.InstanceRelease(instance = state.instance)
````

And boom, with that, we've finished this example. Assuming everything runs well, you should have a window with a
bluish purple background.

