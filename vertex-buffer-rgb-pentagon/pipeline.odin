package main


/*
	This file contains the code for the pipeline

	First: Create a Render Pipeline (wgpu.DeviceCreateRenderPipeline)

	The things you need:
	Shader Modules:
	Vertex State
	Fragment State
	Pipeline Layout
	Primite State
	Depth/Stencil (optional)
	render target
*/

import "vendor:wgpu"


create_render_targets :: proc() -> wgpu.ColorTargetState {
	return wgpu.ColorTargetState {
		format = .BGRA8Unorm,
		writeMask = wgpu.ColorWriteMaskFlags_All,
	}


}

create_pipeline_layout :: proc() -> wgpu.PipelineLayout {
	
	pipeline_layout_desc:wgpu.PipelineLayoutDescriptor = {
		label = "Main Pipeline Layout Desc",
	}

	return wgpu.DeviceCreatePipelineLayout(
		device = state.device,
		descriptor = &pipeline_layout_desc
	) // -> PipelineLayout ---


}

create_pipeline :: proc() -> wgpu.RenderPipeline {

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
		layout = create_pipeline_layout(),
		vertex = vertex_state,
		fragment = &fragment_state,
		primitive = primitive_triangle(),
		multisample = sample_state,
	}
	
	return wgpu.DeviceCreateRenderPipeline(
		device = state.device,
		descriptor = &pipeline_desc
	)// -> RenderPipeline

}

// create_pipeline_layout_with_vertex_buffer :: proc() -> wgpu.PipelineLayout {
	
// 	pipeline_layout_desc:wgpu.PipelineLayoutDescriptor = {
// 		label = "Main Pipeline Layout Desc",
// 	}

// 	return wgpu.DeviceCreatePipelineLayout(
// 		device = state.device,
// 		descriptor = &pipeline_layout_desc
// 	) // -> PipelineLayout ---


// }

create_pipeline_with_vertex_buffer :: proc(vb_layout:[]wgpu.VertexBufferLayout) -> wgpu.RenderPipeline {

	render_targets:[1]wgpu.ColorTargetState = {create_render_targets()}

	vertex_state:wgpu.VertexState = {
		module = state.module,
		entryPoint = "vs_main",
		buffers = raw_data(vb_layout[:]),
		bufferCount = 1,
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
		layout = create_pipeline_layout(),
		vertex = vertex_state,
		fragment = &fragment_state,
		primitive = primitive_triangle(),
		multisample = sample_state,
	}
	
	return wgpu.DeviceCreateRenderPipeline(
		device = state.device,
		descriptor = &pipeline_desc
	)// -> RenderPipeline

}

