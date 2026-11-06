override N: u32 = 31;
override W: u32 = 32;
var<workgroup> scratch: array<u32, N>;
var<workgroup> counter: atomic<u32>;
var<workgroup> vectors: array<vec3u, 3>;
struct Padded { @align(16) xyz: vec3u, tail: u32 }
var<workgroup> padded: Padded;
var<workgroup> unused_shared: array<u32, 16384>;
@group(0) @binding(0) var<storage, read_write> output: array<u32>;
fn initial_sum() -> u32 {
    var sum = atomicLoad(&counter) + padded.tail;
    for (var i = 0u; i < N; i++) { sum += scratch[i]; }
    for (var j = 0u; j < 3u; j++) { sum += vectors[j].x + vectors[j].y + vectors[j].z; }
    return sum + padded.xyz.x + padded.xyz.y + padded.xyz.z;
}
fn write_shared(i: u32, group: u32) {
    for (var j = i; j < N; j += W) { scratch[j] = j + 1u + group * 100u; }
    atomicAdd(&counter, 1u);
}
@compute @workgroup_size(W)
fn main(@builtin(local_invocation_index) i: u32, @builtin(workgroup_id) group: vec3u) {
    let base = group.x * 4u;
    if (i == 0u) { output[base] = initial_sum(); }
    workgroupBarrier();
    write_shared(i, group.x);
    if (i == 0u) {
        vectors[0] = vec3u(3u, 5u, 7u);
        vectors[1] = vec3u(11u, 13u, 17u);
        vectors[2] = vec3u(19u, 23u, 29u);
        padded.xyz = vec3u(31u, 37u, 41u);
        padded.tail = 43u;
    }
    workgroupBarrier();
    if (i == 0u) {
        var sum = 0u;
        for (var j = 0u; j < N; j++) { sum += scratch[j]; }
        output[base + 1u] = sum;
        output[base + 2u] = atomicLoad(&counter);
        output[base + 3u] = vectors[0].z + vectors[1].y + vectors[2].x + padded.xyz.z + padded.tail;
    }
}
@compute @workgroup_size(1)
fn no_shared(@builtin(workgroup_id) group: vec3u) {
    let base = group.x * 4u;
    output[base] = 123u;
    output[base + 1u] = group.x;
    output[base + 2u] = 456u;
    output[base + 3u] = 789u;
}
@compute @workgroup_size(1)
fn padded_only(@builtin(workgroup_id) group: vec3u) {
    let base = group.x * 4u;
    output[base] = padded.xyz.x + padded.xyz.y + padded.xyz.z + padded.tail;
    padded.xyz = vec3u(31u, 37u, 41u);
    padded.tail = 43u;
    output[base + 1u] = padded.xyz.z + padded.tail;
    output[base + 2u] = group.x;
    output[base + 3u] = 8u;
}
