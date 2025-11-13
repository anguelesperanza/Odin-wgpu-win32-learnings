package main


import "core:fmt" // Used to print stuff out for debugging
import "vendor:wgpu" // Our WGPU import
import win "core:sys/windows" // Used to make the window
import "base:runtime" // Used to handle the context

/*
	WGPU Examples: Making a win32 compatible WGPU window
		This only creates a win32 window and a WGPU instance
		and connect them together. No drawing or render done here
		(well, outside of turning the screen like a dark blue/purplish color)
	====================================================
	Disclaimer: I am not a win32 expert. I am not a WGPU expert.
	As such, this example is pulled together using the following resources:
	-----------------------------------------------------------------------
	AI Tools (to generate different examples to refernece)
		Phind (ai tool generating c examples (odin examples are always messy and wrong)): https://www.phind.com/
		Copilot (To further generate examples using a different tool): https://copilot.microsoft.com/
		Chatgpt (To futher genreate exmaples using a different tool): https://chatgpt.com/
		--> AI was not 100% correct 100% of the time; 'fun' times
	Odin WGPU Examples Repository: https://github.com/odin-lang/examples/tree/master/wgpu
	Learn Wgpu (Good reference; written in rust so hard to read, good paragraphs): https://sotrh.github.io/learn-wgpu/
	My general knowledge on win32 (when using GDI): https://github.com/anguelesperanza/Odin-Win32-Graphics-Examples/tree/main
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

	fmt.println("main")
	context = state.ctx

	// Setup Win32
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

	// Setup WGPU
	state.ctx = context
	state.instance = wgpu.CreateInstance(nil)
	if state.instance == nil{
		panic("WebGPU (WGPU) is not supported")
	}

	// The parts of the window/screen that is drawn to
	// This part is confusing as there's a lot of structs
	// It's easy to lose the order of it all
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

	// WGPU doesn't use a Swap Chain (deprecated and removed from the API)
	// Instead, the surface is used directly -- AI lead me down the wrong path at first with Swap Chain; 'fun' times part 2

	surface_config:wgpu.SurfaceConfiguration = {
		usage = { .RenderAttachment},
		format = .BGRA8Unorm,
		width = winsize[0],
		height = winsize[1],
		presentMode = .Fifo,
		device = state.device,
	}

	wgpu.SurfaceConfigure(surface = state.surface, config = &surface_config)

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

			wgpu.SurfaceConfigure(surface = state.surface, config = &new_surface_config)

			return
		case .OutOfMemory, .DeviceLost, .Error:
			// Fatal error
			fmt.panicf("[init-window] get_current_texture status=%v", surface_texture.status)
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
			descriptor = nil,
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
	wgpu.DeviceRelease(device = state.device)
	wgpu.AdapterRelease(adapter = state.adapter)
	wgpu.SurfaceRelease(surface = state.surface)
	wgpu.InstanceRelease(instance = state.instance)
}
