package main

import "vendor:wgpu"



create_bind_group_layout :: proc() -> wgpu.BindGroupLayout {
	// [x] Works

	entries:[2]wgpu.BindGroupLayoutEntry
	entries[0] = {
		binding = 0,
		visibility = {.Fragment},
		texture =  wgpu.TextureBindingLayout {
			sampleType = .Float,
			viewDimension = ._2D,
			multisampled = false,
		},
	}
	
	entries[1] = {
		binding = 1,
		visibility = {.Fragment},
		sampler = wgpu.SamplerBindingLayout {
			type = .Filtering,
		},
	}

	bind_group_layout_desc:wgpu.BindGroupLayoutDescriptor = {
		label = "Bind Group Layout Desc",
		entryCount = 2,
		entries = raw_data(entries[:]),
	}
		
	return wgpu.DeviceCreateBindGroupLayout(
		device = state.device,
		descriptor = &bind_group_layout_desc,
	)//-> BindGroupLayout ---
}

create_bind_group :: proc() -> wgpu.BindGroup {
	// [x] Work
	entries:[2]wgpu.BindGroupEntry

	entries[0] = {
		binding = 0,
		textureView = state.texture_view,
	}
	entries[1] = {
		binding = 1,
		sampler = state.sampler,
	}

	bind_group_desc:wgpu.BindGroupDescriptor = {
		label = "Bind Group Desc",
		layout = state.bind_group_layout,
		entryCount = 2,
		entries = raw_data(entries[:]),
	}
	
	return wgpu.DeviceCreateBindGroup(
		device = state.device ,
		descriptor = &bind_group_desc,
	)// -> BindGroup ---
}
