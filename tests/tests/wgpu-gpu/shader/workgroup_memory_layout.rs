use wgpu_test::{apply, gpu_test, GpuTestConfiguration, GpuTestInitializer, TestParameters};

pub fn all_tests(tests: &mut Vec<GpuTestInitializer>) {
    tests.push(WORKGROUP_MEMORY_LAYOUT);
}

#[apply(gpu_test!)]
static WORKGROUP_MEMORY_LAYOUT: GpuTestConfiguration = GpuTestConfiguration::new()
    .parameters(
        TestParameters::default()
            .downlevel_flags(wgpu::DownlevelFlags::COMPUTE_SHADERS)
            .limits(wgpu::Limits::downlevel_defaults()),
    )
    .run_async(|ctx| async move {
        let module = ctx
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("mixed workgroup memory layout"),
                source: wgpu::ShaderSource::Wgsl(
                    include_str!("../../../../naga/tests/in/wgsl/workgroup-memory-layout.wgsl")
                        .into(),
                ),
            });
        let cases = [
            ("no_shared", 1u32, 1u32),
            ("main", 513, 64),
            ("main", 7, 32),
            ("padded_only", 1, 1),
            ("main", 129, 64),
            ("main", 31, 32),
            ("no_shared", 1, 1),
            ("main", 513, 64),
            ("padded_only", 1, 1),
            ("main", 7, 32),
        ];
        let mut pipelines = Vec::new();
        let mut outputs = Vec::new();
        let mut bindings = Vec::new();
        for &(entry_point, n, w) in &cases {
            let constants = [("N", f64::from(n)), ("W", f64::from(w))];
            let pipeline = ctx
                .device
                .create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
                    label: Some(entry_point),
                    layout: None,
                    module: &module,
                    entry_point: Some(entry_point),
                    compilation_options: wgpu::PipelineCompilationOptions {
                        constants: &constants,
                        zero_initialize_workgroup_memory: true,
                    },
                    cache: None,
                });
            let output = ctx.device.create_buffer(&wgpu::BufferDescriptor {
                label: Some(entry_point),
                size: 128,
                usage: wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_SRC,
                mapped_at_creation: false,
            });
            let binding = ctx.device.create_bind_group(&wgpu::BindGroupDescriptor {
                label: Some(entry_point),
                layout: &pipeline.get_bind_group_layout(0),
                entries: &[wgpu::BindGroupEntry {
                    binding: 0,
                    resource: output.as_entire_binding(),
                }],
            });
            pipelines.push(pipeline);
            outputs.push(output);
            bindings.push(binding);
        }
        let readback = ctx.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("workgroup layout readback"),
            size: (cases.len() * 128) as u64,
            usage: wgpu::BufferUsages::COPY_DST | wgpu::BufferUsages::MAP_READ,
            mapped_at_creation: false,
        });
        for _ in 0..16 {
            let mut encoder = ctx.device.create_command_encoder(&Default::default());
            {
                let mut pass = encoder.begin_compute_pass(&Default::default());
                for (pipeline, binding) in pipelines.iter().zip(&bindings) {
                    pass.set_pipeline(pipeline);
                    pass.set_bind_group(0, binding, &[]);
                    pass.dispatch_workgroups(8, 1, 1);
                }
            }
            for (index, output) in outputs.iter().enumerate() {
                encoder.copy_buffer_to_buffer(output, 0, &readback, (index * 128) as u64, 128);
            }
            ctx.queue.submit([encoder.finish()]);
            readback
                .slice(..)
                .map_async(wgpu::MapMode::Read, |result| result.unwrap());
            ctx.async_poll(wgpu::PollType::wait_indefinitely())
                .await
                .unwrap();
            {
                let bytes = readback.slice(..).get_mapped_range().unwrap();
                let words: &[u32] = bytemuck::cast_slice(&bytes);
                for (index, &(entry_point, n, w)) in cases.iter().enumerate() {
                    for group in 0..8u32 {
                        let offset = index * 32 + group as usize * 4;
                        let expected = match entry_point {
                            "no_shared" => [123, group, 456, 789],
                            "padded_only" => [0, 84, group, 8],
                            _ => [0, n * (n + 1) / 2 + n * group * 100, w, 123],
                        };
                        assert_eq!(
                            &words[offset..offset + 4],
                            &expected,
                            "{entry_point}, N={n}, group={group}"
                        );
                    }
                }
            }
            readback.unmap();
        }
    });
