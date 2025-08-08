package main

/*
	This contains all the primite information for the pipeline render desc.
*/


import "vendor:wgpu"

primitive_triangle :: proc() -> wgpu.PrimitiveState {
	return wgpu.PrimitiveState {
		topology = .TriangleList,
		stripIndexFormat = .Undefined,
		frontFace = .CCW,
		cullMode = .Back,
		unclippedDepth = false,
	}
}
