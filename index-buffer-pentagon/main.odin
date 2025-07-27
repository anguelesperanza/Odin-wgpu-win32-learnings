package main


import "core:fmt"
import "vendor:wgpu"
import win "core:sys/windows"
import "base:runtime"
import "core:os/os2"

/*
	WGPU Examples: Index Buffer Pentagon 
	====================================================
	Disclaimer: I am not a win32 expert. I am not a WGPU expert.
	As such, this example is pulled together using the following resources:
	-----------------------------------------------------------------------
	This example is based on:
		https://sotrh.github.io/learn-wgpu/beginner/tutorial4-buffer/#we-re-finally-talking-about-them
	Rather than using the shader.wgsl to determine the verticies and color,
	they are created in main.odin (this file) in the:
		Vertex struct
		verticies array

	This file is for the later half of the above github.io article -- the index buffer
	for the vertex buffer, please refer to: https://github.com/anguelesperanza/Odin-wgpu-win32-learnings/tree/main/vertex-buffer-rgb-triangle

	This makes a megenta/violet looking pentagon
	-----------------------------------------------------------------------
*/

// Structs -- no OS in state as only using on windows
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
	pipeline_layout: wgpu.PipelineLayout,
	pipeline:       wgpu.RenderPipeline,
	vertex_buffer: wgpu.Buffer,
	index_buffer: wgpu.Buffer,
}

Vertex :: struct {
	position:[3]f32,
	color:[3]f32,
}

vertices:[5]Vertex = {
  { position = {-0.0868241, 0.49240386, 0.0}, color = {0.5, 0.0, 0.5} }, // A
  { position = {-0.49513406, 0.06958647, 0.0}, color = {0.5, 0.0, 0.5} }, // B
  { position = {-0.21918549, -0.44939706, 0.0}, color = {0.5, 0.0, 0.5} }, // C
  { position = {0.35966998, -0.3473291, 0.0}, color = {0.5, 0.0, 0.5} }, // D
  { position = {0.44147372, 0.2347359, 0.0}, color = {0.5, 0.0, 0.5} }, // E
}


// REason why indices are [10]u16 and not [9]u16
// In wgpu, data needs to be aligned to 4 bytes.
// [9]u16 == 18 bytes) | the extra 0 makes indices 20 bytes long
// However, we don't need the extra data, so when calling the size of indices,
// we need to '- 1' from the number, to get 9
//   - This is why there is len(indices) - 1 in the code, to get the 9 points points and not the 10th 
indices:[10]u16 = {
	0, 1, 4,
	1, 2, 4,
	2, 3, 4,
	0,
}

  
// Main loop for windows
running := true

//Window Size -- Win32 is i32 and WGPU is U32 to typecasing Win32 usage as i32
winsize:[2]u32 = {640, 480}

on_device :: proc "c" (status: wgpu.RequestDeviceStatus, device: wgpu.Device, message: string, userdata1, userdata2: rawptr) {
		context = state.ctx
		if status != .Success || device == nil {
			fmt.panicf("request device failure: [%v] %s", status, message)
		}
		state.device = device 
}

on_adapter :: proc "c" (status: wgpu.RequestAdapterStatus, adapter: wgpu.Adapter, message:wgpu.StringView, userdata1:rawptr, userdata2:rawptr){
	/*Requesting an instance adapater requires a callback proc
	This is that callbakc proc*/
	context = state.ctx
	if status != .Success || adapter == nil {
		fmt.panicf("Request Adapter Failure: [%v] %s", status, message)
	}

	state.adapter = adapter
}

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
	
	// Reading in the shader from a file. For the pipeline, the shader code is a string (well, StringView)
	// You can pass the shader in as a string directly, but if its saved to a file,
	// you cannot pass in file name, but the actual contents of the file; thus,
	// reading in the file first, converiting it to a string, and passing that.
	// Reading shader so early as switching context causes it to read an empty list
	//     -- not familiar with how context works at all to work around this to know the proper way of doing this

	shader_data, err := os2.read_entire_file_from_path(name = "./shader.wgsl", allocator = context.allocator)
	if err != nil {
		panic("Cannot read shader file") // panicing cause I don't know what else to do, probably not the most advised option
	}
	
	shader_text := string(shader_data)

	context = state.ctx

	// Setup Win32
	window_instance := win.HINSTANCE(win.GetModuleHandleW(nil)) // Create Instance

	// create window class
	window_class := win.WNDCLASSW {
		style = win.CS_OWNDC | win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc = window_event_proc, // [] created callback function
		hInstance = window_instance,
		lpszClassName = win.L("VertexRGBTriangleWgpuWindowClass"),		
	}

	win.RegisterClassW(lpWndClass = &window_class) // Register the class

	// Create window
	window := win.CreateWindowExW(
		dwExStyle = 0,
		lpClassName = window_class.lpszClassName,
		lpWindowName = win.L("WGPU Vertex RBG Triangle Window"),
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

	// Setup WGPU
	state.ctx = context
	state.instance = wgpu.CreateInstance(nil)
	if state.instance == nil{
		panic("WebGPU (WGPU) is not supported")
	}

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

	// Handle to our graphics card
	wgpu.InstanceRequestAdapter(
		instance = state.instance,
		options = &{compatibleSurface = state.surface},
		callbackInfo = {callback = on_adapter},
	)

	wgpu.AdapterRequestDevice(
		adapter = state.adapter,
		descriptor = nil,
		callbackInfo = {callback = on_device},
	)

	state.queue = wgpu.DeviceGetQueue(device = state.device)
	
	surface_config:wgpu.SurfaceConfiguration = {
		usage = { .RenderAttachment},
		format = .BGRA8Unorm,
		width = winsize[0],
		height = winsize[1],
		presentMode = .Fifo,
		device = state.device,
	}

	wgpu.SurfaceConfigure(surface = state.surface, config = &surface_config)

	// triangle:Triangle
	// triangle.buffer = make_triangle_buffer(state.device)
	// triangle.vertex_buffer_layout = get_triangle_buffer_layout() 

	// Pipeline -- Shaders: Using WGLS as shader language
	state.module = wgpu.DeviceCreateShaderModule(
		device = state.device,
		descriptor = &wgpu.ShaderModuleDescriptor {
			label = "Shader",
			nextInChain = &wgpu.ShaderSourceWGSL {
				chain = wgpu.ChainedStruct {
					sType = .ShaderSourceWGSL,
				}, //end of &wgpu.ChainedStruct
				code = shader_text
			}, // end of &wgpu.ShaderSourceWGSL
		}, // end of &ShaderModuleDescriptor
	)

	// Create a buffer Descriptor
	// -- Using a buffer with data so using this version
	buffer_with_data_desc:wgpu.BufferWithDataDescriptor =  wgpu.BufferWithDataDescriptor {
		label = "Data Supplied Triangle Buffer Desc",
		usage = {.Vertex}
	}

	state.vertex_buffer = wgpu.DeviceCreateBufferWithDataSlice(
		device = state.device,
		descriptor = &buffer_with_data_desc,
		data = vertices[:]
	)


	index_buffer_with_data_desc:wgpu.BufferWithDataDescriptor =  wgpu.BufferWithDataDescriptor {
		label = "Data Supplied Pentagon Buffer Desc",
		usage = {.Index, .CopySrc}
	}

	state.index_buffer = wgpu.DeviceCreateBufferWithDataSlice(
		device = state.device,
		descriptor = &index_buffer_with_data_desc,
		data = indices[:]
	)
	
	vertex_attributes:[2]wgpu.VertexAttribute = {
		wgpu.VertexAttribute {
			format = .Float32x3,
			offset = 0,
			shaderLocation = 0,
		},
		wgpu.VertexAttribute {
			format = .Float32x3,
			offset = size_of([3]f32),
			shaderLocation = 1,
		},
	}
	vertex_buffer_layout:wgpu.VertexBufferLayout = {
		stepMode = .Vertex,
		arrayStride = size_of(Vertex),
		attributeCount = 2,
		attributes = raw_data(vertex_attributes[:]),
	}

	total_buffer_layout:[1]wgpu.VertexBufferLayout
	total_buffer_layout[0] = vertex_buffer_layout

	// Pipeline -- Pipeline Layout
	state.pipeline_layout = wgpu.DeviceCreatePipelineLayout	(
		device = state.device,
		descriptor = &{}, // end of &wgpu.RenderPipelineDescriptor
	)
	// Pipeline -- The pipeline
	state.pipeline = wgpu.DeviceCreateRenderPipeline (
		device = state.device,
		descriptor = &wgpu.RenderPipelineDescriptor {
			label = "RenderPipline",
			layout = state.pipeline_layout,
			vertex = wgpu.VertexState {
				module = state.module, // Shader
				entryPoint = "vs_main",
				buffers = raw_data(total_buffer_layout[:]),
				bufferCount = 1,
			}, // end of wgpu.VertexState
			fragment = &wgpu.FragmentState {
				module = state.module, // Shader
				entryPoint = "fs_main",
				targetCount = 1,
				targets = &wgpu.ColorTargetState {
					format = .BGRA8Unorm,
					writeMask = wgpu.ColorWriteMaskFlags_All,
				},
			}, // end of &wgpu.FragmentState
			primitive = {
				topology = .TriangleList,
			}, // end of primitive (shape to draw)

			multisample = {
				count = 1,
				mask = 0xFFFFFFFF,
			} // end of multisample
			
		}, // en dof &wgpu.RenderPipelineDescriptor
	)

	// message/event loop
	message:win.MSG
	for running {
		if win.GetMessageW(lpMsg = &message, hWnd = nil, wMsgFilterMin = 0, wMsgFilterMax = 0) > 0 {
			win.TranslateMessage(lpMsg = &message)
			win.DispatchMessageW(lpMsg = &message)
		}

		// Render loop 
		// Get next frame
		surface_texture:wgpu.SurfaceTexture
		texture_view:wgpu.TextureView
		view_desc:wgpu.TextureViewDescriptor

		surface_texture = wgpu.SurfaceGetCurrentTexture(surface = state.surface)

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

		texture_view = wgpu.TextureCreateView(
			texture = surface_texture.texture,
			descriptor = nil
		)
		
		// Clear Screen -- All of this will clear the screen and draw a blue/purple screen on it
		encoder := 	wgpu.DeviceCreateCommandEncoder(
			device = state.device,
			descriptor = nil,
		)
		color_attachment:wgpu.RenderPassColorAttachment
		color_attachment.view = texture_view
		color_attachment.loadOp = .Clear
		color_attachment.clearValue = {0.2, 0.2, 0.4, 1.0}
		color_attachment.storeOp = .Store

		render_pass:wgpu.RenderPassDescriptor
		render_pass.colorAttachmentCount = 1
		render_pass.colorAttachments = &color_attachment

		pass:wgpu.RenderPassEncoder = wgpu.CommandEncoderBeginRenderPass(
			commandEncoder = encoder,
			descriptor = &render_pass
		)

		wgpu.RenderPassEncoderSetPipeline(
			renderPassEncoder = pass,
			pipeline = state.pipeline,
		)

		wgpu.RenderPassEncoderSetVertexBuffer(
			renderPassEncoder = pass,
			slot = 0,
			buffer = state.vertex_buffer,
			offset = 0,
			size = size_of(vertices), // Can cause error if higher than 0...find out why
		)

		
		wgpu.RenderPassEncoderSetIndexBuffer(
			renderPassEncoder = pass,
			buffer = state.index_buffer,
			format = .Uint16,
			offset = 0,
			size = size_of(indices) - 1
		)

		wgpu.RenderPassEncoderDrawIndexed(
			renderPassEncoder = pass ,
			indexCount = len(indices) - 1,
			instanceCount = 1,
			firstIndex = 0,
			baseVertex = 0,
			firstInstance = 0,
		)

		wgpu.RenderPassEncoderEnd(pass)
		wgpu.RenderPassEncoderRelease(pass)

		cmd_buffer:wgpu.CommandBuffer =	wgpu.CommandEncoderFinish(
			commandEncoder = encoder,
			descriptor = nil
		)
		wgpu.QueueSubmit(queue = state.queue, commands = {cmd_buffer})

		// Present
		wgpu.SurfacePresent(surface = state.surface)

		// release
		wgpu.TextureViewRelease(textureView = texture_view)
		wgpu.TextureRelease (texture = surface_texture.texture)
		wgpu.CommandBufferRelease(cmd_buffer)
	}

	// Release resources
	wgpu.RenderPipelineRelease(renderPipeline = state.pipeline)
	wgpu.PipelineLayoutRelease(pipelineLayout = state.pipeline_layout)
	wgpu.ShaderModuleRelease(shaderModule = state.module)
	wgpu.DeviceRelease(device = state.device)
	wgpu.AdapterRelease(adapter = state.adapter)
	wgpu.SurfaceRelease(surface = state.surface)
	wgpu.InstanceRelease(instance = state.instance)
}
