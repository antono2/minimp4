module minimp4

struct MemoryFile {
mut:
	data []u8
}

fn write_memory(offset i64, buffer voidptr, size usize, token voidptr) int {
	if offset < 0 || isnil(token) {
		return 1
	}
	unsafe {
		mut file := &MemoryFile(token)
		end := int(offset) + int(size)
		if end > file.data.len {
			file.data << []u8{len: end - file.data.len}
		}
		vmemcpy(&u8(file.data.data) + int(offset), buffer, size)
	}
	return 0
}

fn read_memory(offset i64, buffer voidptr, size usize, token voidptr) int {
	if offset < 0 || isnil(token) {
		return 1
	}
	unsafe {
		file := &MemoryFile(token)
		end := int(offset) + int(size)
		if end > file.data.len {
			return 1
		}
		vmemcpy(buffer, &u8(file.data.data) + int(offset), size)
	}
	return 0
}

fn test_public_constants_and_structures() {
	assert mp4d_handler_type_vide == u32(0x76696465)
	assert mp4_object_type_avc == u32(0x21)
	assert mp4_object_type_hevc == u32(0x23)
	assert sizeof(MP4D_demux_t) > 0
	assert sizeof(MP4D_track_t) > 0
	assert mp4e_status_ok == 0
	assert mp4e_status_bad_arguments < 0
	assert mp4e_sample_random_access == 1
}

fn test_demux_rejects_empty_input() {
	mut file := MemoryFile{}
	mut demux := MP4D_demux_t{}
	assert mp4d_open(&demux, read_memory, &file, 0) == 0
	assert demux.track_count == 0
}

fn test_mux_demux_round_trip_preserves_sample_timing() {
	mut file := MemoryFile{}
	mux := mp_4_e_open(0, 0, &file, write_memory)
	assert !isnil(mux)

	track := MP4E_track_t{
		object_type_indication: mp4_object_type_avc
		language: [u8(`u`), `n`, `d`, 0]!
		track_media_kind: .e_video
		time_scale: 90000
		default_duration: 3000
		u: TrackUnion{
			v: WidthHeight{
				width: 16
				height: 16
			}
		}
	}
	track_id := mp_4_e_add_track(mux, &track)
	assert track_id >= 0

	sps := [u8(0x67), 0x64, 0x00, 0x28, 0xac, 0xb4, 0x03, 0xc0]
	pps := [u8(0x68), 0xee, 0x0d, 0x8b]
	sample := [u8(0x00), 0x00, 0x00, 0x02, 0x65, 0x88]
	assert mp_4_e_set_sps(mux, track_id, sps.data, sps.len) == mp4e_status_ok
	assert mp_4_e_set_pps(mux, track_id, pps.data, pps.len) == mp4e_status_ok
	assert mp_4_e_put_sample(mux, track_id, sample.data, sample.len, 3000, mp4e_sample_random_access) == mp4e_status_ok
	assert mp_4_e_close(mux) == mp4e_status_ok
	assert file.data.len > sample.len

	mut demux := MP4D_demux_t{}
	assert mp4d_open(&demux, read_memory, &file, file.data.len) == 1
	defer {
		mp4d_close(&demux)
	}
	assert demux.track_count == 1
	sample_count := unsafe { demux.track[0].sample_count }
	assert sample_count == 1
	mut frame_bytes := u32(0)
	mut timestamp := u32(0)
	mut duration := u32(0)
	offset := mp4d_frame_offset(&demux, 0, 0, &frame_bytes, &timestamp, &duration)
	assert offset > 0
	assert frame_bytes == u32(sample.len)
	assert timestamp == 0
	assert duration == 3000
}
