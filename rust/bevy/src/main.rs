mod errors;
use bevy::prelude::*;
pub fn main() {
    App::new()
        .insert_resource(ClearColor(Color::BLACK))
        .add_plugins((
            DefaultPlugins,
            bevy_debug_grid::DebugGridPlugin::without_floor_grid(),
            bevy_panorbit_camera::PanOrbitCameraPlugin,
        ))
        .add_systems(Startup, setup)
        .run();
}

fn setup(mut commands: Commands) {
    commands.spawn((
        bevy_panorbit_camera::PanOrbitCamera {
            axis: [Vec3::X, Vec3::Z, Vec3::Y],
            allow_upside_down: true,
            zoom_smoothness: 0.0,
            target_focus: Vec3::new(10.0, 10.0, 10.0),
            target_radius: 10.0,
            ..default()
        },
        Transform::from_xyz(50.0, -50.0, 50.0).looking_at(Vec3::ZERO, Vec3::Z),
    ));
    commands.spawn((
        bevy_debug_grid::Grid {
            spacing: 10.0_f32,
            count: 16,
            ..default()
        },
        bevy_debug_grid::SubGrid::default(),
        bevy_debug_grid::GridAxis::new_rgb(),
        bevy_debug_grid::TrackedGrid {
            alignment: bevy_debug_grid::GridAlignment::Z,
            ..default()
        },
        Transform::default(),
        Visibility::default(),
    ));
}
