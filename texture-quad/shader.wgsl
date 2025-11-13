// Vertex shader
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) tex_coords: vec2<f32>,
}

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
}

@vertex
fn vs_main(
    model: VertexInput,
) -> VertexOutput {
    var out: VertexOutput;
    out.tex_coords = model.tex_coords;
    out.clip_position = vec4<f32>(model.position, 1.0);
    return out;
}

// Fragment shader

@group(0) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(0) @binding(1)
var s_diffuse: sampler;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    return textureSample(t_diffuse, s_diffuse, in.tex_coords);
}



// Copilot provided this code here: A neat trick to finding out why
// textures are skewed/warped when placed on the quad
// If the gradiant this created
// What is shows:
// top left (0, 0) is black
// top right (1, 0) is red
// bottom right is (1, 1) yellow
// bottom left is (0, 1) greenish black
// This shows that the vetrex cooridates are mapped correctly
// So no issue there
// @fragment
// fn fs_main(@location(0) tex_coords: vec2<f32>) -> @location(0) vec4<f32> {
//     return vec4(tex_coords, 0.0, 1.0);  // red = U, green = V
// }
