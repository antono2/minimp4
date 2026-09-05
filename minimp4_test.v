module minimp4

fn test_public_constants_and_structures() {
	assert mp4d_handler_type_vide == u32(0x76696465)
	assert mp4_object_type_avc == u32(0x21)
	assert mp4_object_type_hevc == u32(0x23)
	assert sizeof(MP4D_demux_t) > 0
	assert sizeof(MP4D_track_t) > 0
}
