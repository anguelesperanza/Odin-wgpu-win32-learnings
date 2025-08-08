package main

/*
	This file contains procs to create shapes via indices and index buffers

	Making a shape with indices and index buffers
		-> Using device (place to execute GPU commands), create a buffer (wgpu.DeviceCreateBufferWithDataSlice)
			-> Pointer to a Buffer with data descriptor struct (wgpu.BufferWithDataDescriptor)
			-> A slice to our verticies array (vertices[:])
		-> using the *WithDataSlice create buffer proc the shape verticies are hard coded

	Also, the pipeline needs to know how to handle this vertex data. Do this by using VertexAttribute
	
	
*/

import "vendor:wgpu"

// Structs
Vertex :: struct {
	position:[3]f32,
	color:[3]f32,
}


// Global Arrays
va:[2]wgpu.VertexAttribute


// TRIANGLES
create_triangle_vertex_buffer :: proc () -> wgpu.Buffer {
	vertices:[3]Vertex = {
		{position = {0.0, 0.5, 0.0}, color = {1.0, 0.0, 0.0}},
		{position = {-0.5, -0.5, 0.0}, color = {0.0, 1.0, 0.0}},
		{position = {0.5, -0.5, 0.0}, color = {0.0, 0.0, 1.0 }},
	}
	
	buffer_with_data_desc:wgpu.BufferWithDataDescriptor =  wgpu.BufferWithDataDescriptor {
		label = "Data Supplied Triangle Buffer Desc",
		usage = {.Vertex}
	}
	
	return wgpu.DeviceCreateBufferWithDataSlice(
		device = state.device,
		descriptor = &buffer_with_data_desc,
		data = vertices[:]
	) // -> (buf: Buffer)
}

create_triangle_vertex_buffer_layout:: proc() -> wgpu.VertexBufferLayout {
	// va short for Vertex Attribute
	// va:[2]wgpu.VertexAttribute
	va[0] = wgpu.VertexAttribute {
		format = .Float32x3, // will be the datatype for position in Vertex Struct
		offset = 0,
		shaderLocation = 0,
	}

	va[1] = wgpu.VertexAttribute {
		format = .Float32x3, // will be the datatype for color in Vertex Struct
		offset = 12, // the location in the Vertex Struct color data
		// offset = size_of([3]f32), // the location in the Vertex Struct color data
		shaderLocation = 1,
	}

	return wgpu.VertexBufferLayout {
		stepMode = .Vertex ,
		arrayStride = 24,
		// arrayStride = size_of(Vertex),
		attributeCount = 2, // There's two elments in the vertex attribute array
		attributes = raw_data(va[:]), // Attributes is a multipointer
	}
}
// END OF TRIANGLES

// PENTAGONS
create_pentagon :: proc() -> (wgpu.Buffer, wgpu.Buffer) {
	vertices:[5]Vertex = {
	    { position = {-0.0868241, 0.49240386, 0.0}, color = {1, 0.0, 0.5} }, // A
	    { position = {-0.49513406, 0.06958647, 0.0}, color = {0, 0.0, 1} }, // B
	    { position = {-0.21918549, -0.44939706, 0.0}, color = {0.5,1, 0.5} }, // C
	    { position = {0.35966998, -0.3473291, 0.0}, color = {0.4, 0.0, 0.5} }, // D
	    { position = {0.44147372, 0.2347359, 0.0}, color = {0.5, 0.0, 0.2} }, // E
	}

	// Indices is really the first 9 bytes
	// the extra 0 is to pad it out to be 20 bytes aligned
	indices:[10]u16 = {
		0, 1, 4,
		1, 2, 4,
		2, 3, 4,
		0,
	}
	
	vertex_buffer_with_data_desc:wgpu.BufferWithDataDescriptor =  wgpu.BufferWithDataDescriptor {
		label = "Data Supplied Pentagon Vertex Buffer Desc",
		usage = {.Vertex}
	}

	index_buffer_with_data_desc:wgpu.BufferWithDataDescriptor =  wgpu.BufferWithDataDescriptor {
		label = "Data Supplied Pentagon Index Buffer Desc",
		usage = {.Index}
	}
	
	vb:wgpu.Buffer = wgpu.DeviceCreateBufferWithDataSlice(
		device = state.device,
		descriptor = &vertex_buffer_with_data_desc,
		data = vertices[:]
	) // -> (buf: Buffer)

	ib:wgpu.Buffer = wgpu.DeviceCreateBufferWithDataSlice(
		device = state.device,
		descriptor = &index_buffer_with_data_desc,
		data = indices[:]
	) // -> (buf: Buffer)


	return vb, ib
	
}
// END OF PENTAGONS 
