package main

import "core:fmt"
import "core:image"
import "core:image/png"
import "vendor:wgpu"


/*
	Render a texutre in wgpu
	------------------------
	GPU Resources
		- Texture
		- TextureView
		- Sampler

	Bind Groups and Bind Group Layers
		- BindGroup
		- BindGroupLayout

	Pipeline
		- Update pipeline layout to use bindings

	Vertex and Buffers
		- Vertex to store shapes position and UV data
	Update Shader

	Steps:
		Load image Data (with alpha channel added to image)
		Create texture (wgpu.DeviceCreateTexture)
		create texture view (wgpu.TextureCreateView)

	==========================================================

	
	Putting It All Together
	Initialize

	[x]Load image → PNG pixels

	[x]Create Texture, [x]TextureView, [x]Sampler

	Build BindGroupLayout → BindGroup

	Define VertexBufferLayout → vertex_buffer (+ index_buffer)

	Compile shaders → create RenderPipeline with PipelineLayout

	Render Each Frame

	(Optional) queue.writeTexture to update pixels

	Acquire swap-chain texture → begin pass

	Bind pipeline, bind groups, buffers

	Draw quad

	Submit & present	
*/

load_image :: proc(filename:string) -> ^png.Image {
	image_data, image_err := png.load_from_file(filename = filename, options = {.alpha_add_if_missing})
	if image_err != nil {
		panic("Cannot read shader file") // panicing cause I don't know what else to do, probably not the most advised option
	}

	return image_data
}


create_sampler :: proc() -> wgpu.Sampler {
	// [x]Works
	// load lodMinClamp, lodMaxClap, and compare fields missing
	// from sampler_desc as no lod is needed -- this is a static image

	sampler_desc:wgpu.SamplerDescriptor = {
		label = "Sampler Desc",
		addressModeU = .Repeat,
		addressModeV = .Repeat,
		addressModeW = .Repeat,
		magFilter = .Linear,
		minFilter = .Linear,
		mipmapFilter = .Nearest,
		maxAnisotropy = 1,
	}

	return wgpu.DeviceCreateSampler(
		device = state.device,
		descriptor = &sampler_desc,
	)// -> Sampler ---
}


create_texture_view :: proc() -> wgpu.TextureView {
	// [x] works
	/*
		for the field: format
			-> Either wgpu.TextureGetFormat() or .RGBA8UnormSrgb can be used
		 but in order to reduce typo related errors: using the proc
	 */

	texture_view_desc: wgpu.TextureViewDescriptor = {
		// nextInChain: /* const */ ^ChainedStruct,
		label = "Texture View Desc",
		format = wgpu.TextureGetFormat(texture = state.texture),
		dimension = ._2D,
		baseMipLevel = 0, // This is zero becuase the mipLevelCount is 1
		mipLevelCount = 1,
		baseArrayLayer = 0,
		arrayLayerCount = 1,
		aspect = .All,
		usage = {.TextureBinding, .CopyDst},
	}

	return wgpu.TextureCreateView(
		texture = state.texture,
		descriptor = &texture_view_desc,
	)// -> TextureView ---
}

create_texture :: proc() -> wgpu.Texture {
	// [x] works
	
	/*Creates a wgpu.Texture. Although this texture does not hold
	any information in it yet*/
	state.texture_size = {
		width = cast(u32)state.image.width,
		height = cast(u32)state.image.height,
		depthOrArrayLayers = 1, // No depth, flat, 2D image
	}

	texture_desc:wgpu.TextureDescriptor = {
		label = "Texture Desc (texture.odin)",
		usage = {.TextureBinding, .CopyDst}, // Find out why 
		dimension = ._2D,
		size = state.texture_size,
		format =.RGBA8UnormSrgb,
		mipLevelCount = 1, // How many mipMaps there are for the image. 1 means use full image
		sampleCount = 1,
		// viewFormatCount viewFormats left as default as
		// There is no alterntivate way we are passing to view the data
	}
	
	return wgpu.DeviceCreateTexture(
		device = state.device,
		descriptor = &texture_desc,
	)// -> Texture ---
}

create_texel_copy_buffer_layout :: proc() -> wgpu.TexelCopyBufferLayout {
	return wgpu.TexelCopyBufferLayout {
		offset = 0,
		bytesPerRow = u32(4 * state.image.width),
		rowsPerImage = u32(state.image.height),
	}
}

create_texel_copy_texture_info :: proc() -> wgpu.TexelCopyTextureInfo {
	return wgpu.TexelCopyTextureInfo {
		texture = state.texture,
		mipLevel = 0,
		origin = {0, 0, 0}, // Odin is Zero at init, so technically do not need to specify if origin is 0
		aspect = .All,
	}
}
