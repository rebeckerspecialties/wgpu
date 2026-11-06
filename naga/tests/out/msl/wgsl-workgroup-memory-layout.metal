// language: metal3.2
#include <metal_stdlib>
#include <simd/simd.h>

using metal::uint;

struct _mslBufferSizes {
    uint size4;
};

struct type_1 {
    uint inner[513];
};
struct type_4 {
    metal::uint3 inner[3];
};
struct Padded {
    metal::packed_uint3 xyz;
    uint tail;
};
typedef uint type_5[1];
constant uint N = 513u;
constant uint W = 64u;

uint initial_sum(
    threadgroup type_1& scratch,
    threadgroup metal::atomic_uint& counter,
    threadgroup type_4& vectors,
    threadgroup Padded& padded
) {
    uint sum_1 = {};
    uint i_1 = 0u;
    uint j_1 = 0u;
    uint _e1 = metal::atomic_load_explicit(&counter, metal::memory_order_relaxed);
    uint _e4 = padded.tail;
    sum_1 = _e1 + _e4;
    uint2 loop_bound = uint2(4294967295u);
    bool loop_init = true;
    while(true) {
        if (metal::all(loop_bound == uint2(0u))) { break; }
        loop_bound -= uint2(loop_bound.y == 0u, 1u);
        if (!loop_init) {
            uint _e19 = i_1;
            i_1 = _e19 + 1u;
        }
        loop_init = false;
        uint _e9 = i_1;
        if (_e9 < N) {
        } else {
            break;
        }
        {
            uint _e12 = sum_1;
            uint _e14 = i_1;
            uint _e16 = scratch.inner[_e14];
            sum_1 = _e12 + _e16;
        }
    }
    uint2 loop_bound_1 = uint2(4294967295u);
    bool loop_init_1 = true;
    while(true) {
        if (metal::all(loop_bound_1 == uint2(0u))) { break; }
        loop_bound_1 -= uint2(loop_bound_1.y == 0u, 1u);
        if (!loop_init_1) {
            uint _e46 = j_1;
            j_1 = _e46 + 1u;
        }
        loop_init_1 = false;
        uint _e23 = j_1;
        if (_e23 < 3u) {
        } else {
            break;
        }
        {
            uint _e26 = sum_1;
            uint _e28 = j_1;
            uint _e31 = vectors.inner[_e28].x;
            uint _e33 = j_1;
            uint _e36 = vectors.inner[_e33].y;
            uint _e39 = j_1;
            uint _e42 = vectors.inner[_e39].z;
            sum_1 = _e26 + ((_e31 + _e36) + _e42);
        }
    }
    uint _e48 = sum_1;
    uint _e52 = padded.xyz[0];
    uint _e57 = padded.xyz[1];
    uint _e62 = padded.xyz[2];
    return ((_e48 + _e52) + _e57) + _e62;
}

void write_shared(
    uint i_2,
    uint group_3,
    threadgroup type_1& scratch,
    threadgroup metal::atomic_uint& counter
) {
    uint j_2 = {};
    j_2 = i_2;
    uint2 loop_bound_2 = uint2(4294967295u);
    bool loop_init_2 = true;
    while(true) {
        if (metal::all(loop_bound_2 == uint2(0u))) { break; }
        loop_bound_2 -= uint2(loop_bound_2.y == 0u, 1u);
        if (!loop_init_2) {
            uint _e15 = j_2;
            j_2 = _e15 + W;
        }
        loop_init_2 = false;
        uint _e3 = j_2;
        if (_e3 < N) {
        } else {
            break;
        }
        {
            uint _e7 = j_2;
            uint _e9 = j_2;
            scratch.inner[_e7] = (_e9 + 1u) + (group_3 * 100u);
        }
    }
    uint _e20 = metal::atomic_fetch_add_explicit(&counter, 1u, metal::memory_order_relaxed);
    return;
}

struct main_Input {
};
[[max_total_threads_per_threadgroup(64)]] kernel void main_(
  uint i [[thread_index_in_threadgroup]]
, metal::uint3 group [[threadgroup_position_in_grid]]
, device type_5& output [[buffer(0)]]
, constant _mslBufferSizes& _buffer_sizes [[buffer(1)]]
) {
    struct nagaWorkgroupMemoryType {
        type_1 scratch;
        metal::atomic_uint counter;
        type_4 vectors;
        Padded padded;
    };
    threadgroup nagaWorkgroupMemoryType nagaWorkgroupMemory;
    threadgroup type_1& scratch = nagaWorkgroupMemory.scratch;
    threadgroup metal::atomic_uint& counter = nagaWorkgroupMemory.counter;
    threadgroup type_4& vectors = nagaWorkgroupMemory.vectors;
    threadgroup Padded& padded = nagaWorkgroupMemory.padded;
    if (i == 0u) {
        for (int __i0 = 0; __i0 < 513; __i0++) {
            scratch.inner[__i0] = {};
        }
        metal::atomic_store_explicit(&counter, 0, metal::memory_order_relaxed);
        vectors = {};
        padded = {};
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    uint sum = 0u;
    uint j = 0u;
    uint base = group.x * 4u;
    if (i == 0u) {
        uint _e9 = initial_sum(scratch, counter, vectors, padded);
        output[base] = _e9;
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    write_shared(i, group.x, scratch, counter);
    if (i == 0u) {
        vectors.inner[0] = metal::uint3(3u, 5u, 7u);
        vectors.inner[1] = metal::uint3(11u, 13u, 17u);
        vectors.inner[2] = metal::uint3(19u, 23u, 29u);
        padded.xyz = metal::uint3(31u, 37u, 41u);
        padded.tail = 43u;
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    if (i == 0u) {
        uint2 loop_bound_3 = uint2(4294967295u);
        bool loop_init_3 = true;
        while(true) {
            if (metal::all(loop_bound_3 == uint2(0u))) { break; }
            loop_bound_3 -= uint2(loop_bound_3.y == 0u, 1u);
            if (!loop_init_3) {
                uint _e56 = j;
                j = _e56 + 1u;
            }
            loop_init_3 = false;
            uint _e46 = j;
            if (_e46 < N) {
            } else {
                break;
            }
            {
                uint _e49 = sum;
                uint _e51 = j;
                uint _e53 = scratch.inner[_e51];
                sum = _e49 + _e53;
            }
        }
        uint _e62 = sum;
        output[base + 1u] = _e62;
        uint _e68 = metal::atomic_load_explicit(&counter, metal::memory_order_relaxed);
        output[base + 2u] = _e68;
        uint _e76 = vectors.inner[0].z;
        uint _e80 = vectors.inner[1].y;
        uint _e85 = vectors.inner[2].x;
        uint _e90 = padded.xyz[2];
        uint _e94 = padded.tail;
        output[base + 3u] = (((_e76 + _e80) + _e85) + _e90) + _e94;
        return;
    } else {
        return;
    }
}


struct no_sharedInput {
};
[[max_total_threads_per_threadgroup(1)]] kernel void no_shared(
  metal::uint3 group_1 [[threadgroup_position_in_grid]]
, device type_5& output [[buffer(0)]]
, constant _mslBufferSizes& _buffer_sizes [[buffer(1)]]
) {
    uint base_1 = group_1.x * 4u;
    output[base_1] = 123u;
    output[base_1 + 1u] = group_1.x;
    output[base_1 + 2u] = 456u;
    output[base_1 + 3u] = 789u;
    return;
}


struct padded_onlyInput {
};
[[max_total_threads_per_threadgroup(1)]] kernel void padded_only(
  metal::uint3 group_2 [[threadgroup_position_in_grid]]
, uint __local_invocation_index [[thread_index_in_threadgroup]]
, device type_5& output [[buffer(0)]]
, constant _mslBufferSizes& _buffer_sizes [[buffer(1)]]
) {
    struct nagaWorkgroupMemoryType_1 {
        Padded padded;
    };
    threadgroup nagaWorkgroupMemoryType_1 nagaWorkgroupMemory_1;
    threadgroup Padded& padded = nagaWorkgroupMemory_1.padded;
    if (__local_invocation_index == 0u) {
        padded = {};
    }
    metal::threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    uint base_2 = group_2.x * 4u;
    uint _e9 = padded.xyz[0];
    uint _e13 = padded.xyz[1];
    uint _e18 = padded.xyz[2];
    uint _e22 = padded.tail;
    output[base_2] = ((_e9 + _e13) + _e18) + _e22;
    padded.xyz = metal::uint3(31u, 37u, 41u);
    padded.tail = 43u;
    uint _e40 = padded.xyz[2];
    uint _e43 = padded.tail;
    output[base_2 + 1u] = _e40 + _e43;
    output[base_2 + 2u] = group_2.x;
    output[base_2 + 3u] = 8u;
    return;
}
