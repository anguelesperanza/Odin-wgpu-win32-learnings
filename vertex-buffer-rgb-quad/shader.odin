package main

/*
	This file contains code related to the shader
	First you create a shader module (wgpu.DeviceCreateShaderModule)
		-> This takes a shader descriptor (wgpu.ShaderModuleDescriptor)
			-> This takes a chained struct (wgpu.ChainedStruct)
				->  This takes a chained struct ShaderSourceWGSL (wgpu.ShaderSourceWGSL)
					-> This takes the shader code
*/

// core
import "core:os/os2"
import "core:image"
import "core:image/png"

// vendor
import "vendor:wgpu"

load_shader :: proc(filename:string) -> string {
	shader_data, shader_err := os2.read_entire_file_from_path(name = "./shader.wgsl", allocator = context.allocator)
	if shader_err != nil {
		panic("Cannot read shader file") // panicing cause I don't know what else to do, probably not the most advised option
	}

	return string(shader_data)
	
}

create_shader_module :: proc(shader:string) -> wgpu.ShaderModule  {
	shader_source_wgsl:wgpu.ChainedStruct = {
		sType = .ShaderSourceWGSL,
	}

	// wgpu.ShaderSourceWGSL is a struct, but is using ChainedStruct
	shader_chained_struct:wgpu.ShaderSourceWGSL = {
		chain = shader_source_wgsl,
		code = shader
	}
	
	shader_desc:wgpu.ShaderModuleDescriptor = {
		nextInChain = &shader_chained_struct, 
		label = "Main Shader",
	}
	
	return wgpu.DeviceCreateShaderModule(
		device = state.device ,
		descriptor = &shader_desc,
	)// -> ShaderModule ---
}
