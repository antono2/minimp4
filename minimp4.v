@[translated]
module minimp4

//
//    https://github.com/aspt/mp4
//    https://github.com/lieff/minimp4
//    To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide.
//    This software is distributed without any warranty.
//    See <http://creativecommons.org/publicdomain/zero/1.0/>.
//
//***********************************
//                  Build configuration
//***********************************
// Max chunks nesting level
// Support indexing of MP4 files over 4 GB.
// If disabled, files with 64-bit offset fields is still supported,
// but error signaled if such field contains too big offset
// This switch affect return type of MP4D_frame_offset() function
// Debug trace
// Support parsing of supplementary information, not necessary for decoding:
// duration, language, bitrate, metadata tags, etc
// Enable code, which prints to stdout supplementary MP4 information:
// Enable TrackFragmentBaseMediaDecodeTimeBox support
//***********************************
//          Some values of MP4(E/D)_track_t->object_type_indication
//***********************************
// MPEG-4 AAC (all profiles)
// MPEG-2 AAC, Main profile
// MPEG-2 AAC, LC profile
// MPEG-2 AAC, SSR profile
// H.264 (AVC) video
// H.265 (HEVC) video
// http://www.mp4ra.org/object.html 0xC0-E0  && 0xE2 - 0xFE are specified as "user private"
//***********************************
//          API error codes
//***********************************
//***********************************
//          Sample kind for MP4E_put_sample()
//***********************************
// (beginning of) audio or video frame
// mark sample as random access point (key frame)
// Not a sample, but continuation of previous sample (new slice)
//***********************************
//                  Portable 64-bit type definition
//***********************************
pub type Boxsize_t = u64

pub type MP4D_file_offset_t = u64

pub const mp4d_handler_type_vide = u32(0x76696465)
pub const mp4_object_type_avc = u32(0x21)
pub const mp4_object_type_hevc = u32(0x23)
pub const mp4e_status_ok = 0
pub const mp4e_status_bad_arguments = -1
pub const mp4e_status_no_memory = -2
pub const mp4e_status_file_write_error = -3
pub const mp4e_status_only_one_dsi_allowed = -4
pub const mp4e_sample_default = 0
pub const mp4e_sample_random_access = 1
pub const mp4e_sample_continuation = 2

//***********************************
//          Some values of MP4D_track_t->handler_type
//***********************************
// Video track : 'vide'
// Audio track : 'soun'
// General MPEG-4 systems streams (without specific handler).
// Used for private stream, as suggested in http://www.mp4ra.org/handler.html
//***********************************
//          Data structures
//***********************************
enum Track_media_kind_t {
	e_audio
	e_video
	e_private
}

pub struct MP4E_track_t {

	// MP4 object type code, which defined codec class for the track.
	// See MP4E_OBJECT_TYPE_* values for some codecs
pub mut:
	object_type_indication u32
	// Track language: 3-char ISO 639-2T code: "und", "eng", "rus", "jpn" etc...
	language         [4]u8
	track_media_kind Track_media_kind_t
	// 90000 for video, sample rate for audio
	time_scale       u32
	default_duration u32
	u                TrackUnion
}

pub union TrackUnion {
	a ChannelCount
	v WidthHeight
}

pub struct ChannelCount {
pub mut:
	channelcount u32
}

pub struct WidthHeight {
pub mut:
	width  int
	height int
}

pub struct MP4D_track_t {

	//***********************************
	//                 mandatory public data
	//***********************************
	// How many 'samples' in the track
	// The 'sample' is MP4 term, denoting audio or video frame
pub mut:
	sample_count u32
	// Decoder-specific info (DSI) data
	dsi &u8
	// DSI data size
	dsi_bytes u32
	// MP4 object type code
	// case 0x00: return "Forbidden";
	// case 0x01: return "Systems ISO/IEC 14496-1";
	// case 0x02: return "Systems ISO/IEC 14496-1";
	// case 0x20: return "Visual ISO/IEC 14496-2";
	// case 0x40: return "Audio ISO/IEC 14496-3";
	// case 0x60: return "Visual ISO/IEC 13818-2 Simple Profile";
	// case 0x61: return "Visual ISO/IEC 13818-2 Main Profile";
	// case 0x62: return "Visual ISO/IEC 13818-2 SNR Profile";
	// case 0x63: return "Visual ISO/IEC 13818-2 Spatial Profile";
	// case 0x64: return "Visual ISO/IEC 13818-2 High Profile";
	// case 0x65: return "Visual ISO/IEC 13818-2 422 Profile";
	// case 0x66: return "Audio ISO/IEC 13818-7 Main Profile";
	// case 0x67: return "Audio ISO/IEC 13818-7 LC Profile";
	// case 0x68: return "Audio ISO/IEC 13818-7 SSR Profile";
	// case 0x69: return "Audio ISO/IEC 13818-3";
	// case 0x6A: return "Visual ISO/IEC 11172-2";
	// case 0x6B: return "Audio ISO/IEC 11172-3";
	// case 0x6C: return "Visual ISO/IEC 10918-1";
	object_type_indication u32
	//***********************************
	//                 informational public data
	//***********************************
	// handler_type when present in a media box, is an integer containing one of
	// the following values, or a value from a derived specification:
	// 'vide' Video track
	// 'soun' Audio track
	// 'hint' Hint track
	handler_type u32
	// Track duration: 64-bit value split into 2 variables
	duration_hi u32
	duration_lo u32
	// duration scale: duration = timescale*seconds
	timescale u32
	// Average bitrate, bits per second
	avg_bitrate_bps u32
	// Track language: 3-char ISO 639-2T code: "und", "eng", "rus", "jpn" etc...
	language [4]u8
	// MP4 stream type
	// case 0x00: return "Forbidden";
	// case 0x01: return "ObjectDescriptorStream";
	// case 0x02: return "ClockReferenceStream";
	// case 0x03: return "SceneDescriptionStream";
	// case 0x04: return "VisualStream";
	// case 0x05: return "AudioStream";
	// case 0x06: return "MPEG7Stream";
	// case 0x07: return "IPMPStream";
	// case 0x08: return "ObjectContentInfoStream";
	// case 0x09: return "MPEGJStream";
	stream_type          u32
	track_matrix         [9]i32
	display_width_fixed  u32
	display_height_fixed u32
	sampleDescription    SampleDescriptionUnion
	//***********************************
	//                 private data: MP4 indexes
	//***********************************
	entry_size            &u32
	sample_to_chunk_count u32
	sample_to_chunk       &MP4D_sample_to_chunk_t_tag
	chunk_count           u32
	chunk_offset          &MP4D_file_offset_t
	timestamp             &u32
	duration              &u32
}

pub struct MP4E_mux_tag {
pub mut:
	tracks minimp4_vector_t
}

pub struct minimp4_vector_t {
pub mut:
	data     &u8
	bytes    int
	capacity int
}

pub type MP4E_mux_t = MP4E_mux_tag

pub union SampleDescriptionUnion {
pub mut:
	audio AudioDescription
	video VideoDescription
}

pub struct AudioDescription {
pub mut:
	channelcount  u32
	samplerate_hz u32
}

pub struct VideoDescription {
pub mut:
	width  u32
	height u32
}

pub struct MP4D_demux_t {

	//***********************************
	//                 mandatory public data
	//***********************************
pub mut:
	read_pos      i64
	read_size     i64
	track         &MP4D_track_t = unsafe { nil }
	read_callback fn (i64, voidptr, usize, voidptr) int
	token         voidptr
	track_count   u32
	// number of tracks in the movie
	//***********************************
	//                 informational public data
	//***********************************
	// Movie duration: 64-bit value split into 2 variables
	duration_hi u32
	duration_lo u32
	// duration scale: duration = timescale*seconds
	timescale u32
	// Metadata tag (optional)
	// Tags provided 'as-is', without any re-encoding
	tag struct {
		title   &u8 = unsafe { nil }
		artist  &u8 = unsafe { nil }
		album   &u8 = unsafe { nil }
		year    &u8 = unsafe { nil }
		comment &u8 = unsafe { nil }
		genre   &u8 = unsafe { nil }
	}
}

pub struct MP4D_sample_to_chunk_t_tag {
pub mut:
	first_chunk       u32
	samples_per_chunk u32
}

pub struct H264_sps_id_patcher_t {
pub mut:
	sps_cache [32]voidptr
	pps_cache [256]voidptr
	sps_bytes [32]int
	pps_bytes [256]int
	map_sps   [32]int
	map_pps   [256]int
}

pub struct Mp4_h26x_writer_t {
pub mut:
	sps_patcher  H264_sps_id_patcher_t
	mux          &MP4E_mux_t
	mux_track_id int
	is_hevc      int
	need_vps     int
	need_sps     int
	need_pps     int
	need_idr     int
}

fn C.mp4_h26x_write_init(h &Mp4_h26x_writer_t, mux &MP4E_mux_t, width int, height int, is_hevc int) int

pub fn mp4_h26x_write_init(h &Mp4_h26x_writer_t, mux &MP4E_mux_t, width int, height int, is_hevc int) int {
	return C.mp4_h26x_write_init(h, mux, width, height, is_hevc)
}

fn C.mp4_h26x_write_close(h &Mp4_h26x_writer_t)

pub fn mp4_h26x_write_close(h &Mp4_h26x_writer_t) {
	C.mp4_h26x_write_close(h)
}

fn C.mp4_h26x_write_nal(h &Mp4_h26x_writer_t, nal &u8, length int, time_stamp90k_hz_next u32) int

pub fn mp4_h26x_write_nal(h &Mp4_h26x_writer_t, nal &u8, length int, time_stamp90k_hz_next u32) int {
	return C.mp4_h26x_write_nal(h, nal, length, time_stamp90k_hz_next)
}

//***********************************
//          API
//***********************************
//*
//*  Parse given input stream as MP4 file. Allocate and store data indexes.
//*  return 1 on success, 0 on failure
//*  The MP4 indexes may be stored at the end of stream, so this
//*  function may parse all stream.
//*  It is guaranteed that function will read/seek sequentially,
//*  and will never jump back.
//
fn C.MP4D_open(mp4 &MP4D_demux_t, read_callback fn (i64, voidptr, usize, voidptr) int, token voidptr, file_size i64) int

pub type PFN_read_callback = fn (i64, voidptr, usize, voidptr) int

pub fn mp4d_open(mp4 &MP4D_demux_t, read_callback fn (i64, voidptr, usize, voidptr) int, token voidptr, file_size i64) int {
	return C.MP4D_open(mp4, read_callback, token, file_size)
}

//*
//*  Return position and size for given sample from given track. The 'sample' is a
//*  MP4 term for 'frame'
//*
//*  frame_bytes [OUT]   - return coded frame size in bytes
//*  timestamp [OUT]     - return frame timestamp (in mp4->timescale units)
//*  duration [OUT]      - return frame duration (in mp4->timescale units)
//*
//*  function return offset for the frame
//
fn C.MP4D_frame_offset(mp4 &MP4D_demux_t, ntrack u32, nsample u32, frame_bytes &u32, timestamp &u32, duration &u32) MP4D_file_offset_t

pub fn mp4d_frame_offset(mp4 &MP4D_demux_t, ntrack u32, nsample u32, frame_bytes &u32, timestamp &u32, duration &u32) MP4D_file_offset_t {
	return C.MP4D_frame_offset(mp4, ntrack, nsample, frame_bytes, timestamp, duration)
}

//*
//*  De-allocated memory
//
fn C.MP4D_close(mp4 &MP4D_demux_t)

pub fn mp4d_close(mp4 &MP4D_demux_t) {
	C.MP4D_close(mp4)
}

//*
//*  Helper functions to parse mp4.track[ntrack].dsi for H.264 SPS/PPS
//*  Return pointer to internal mp4 memory, it must not be free()-ed
//*
//*  Example: process all SPS in MP4 file:
//*      while (sps = MP4D_read_sps(mp4, num_of_avc_track, sps_count, &sps_bytes))
//*      {
//*          process(sps, sps_bytes);
//*          sps_count++;
//*      }
//
fn C.MP4D_read_sps(mp4 &MP4D_demux_t, ntrack u32, nsps int, sps_bytes &int) voidptr

pub fn mp4d_read_sps(mp4 &MP4D_demux_t, ntrack u32, nsps int, sps_bytes &int) voidptr {
	return C.MP4D_read_sps(mp4, ntrack, nsps, sps_bytes)
}

fn C.MP4D_read_pps(mp4 &MP4D_demux_t, ntrack u32, npps int, pps_bytes &int) voidptr

pub fn mp4d_read_pps(mp4 &MP4D_demux_t, ntrack u32, npps int, pps_bytes &int) voidptr {
	return C.MP4D_read_pps(mp4, ntrack, npps, pps_bytes)
}

//*
//*  Print MP4 information to stdout.
//*  Uses printf() as well as floating-point functions
//*  Given as implementation example and for test purposes
//
//*
//*  Allocates and initialize mp4 multiplexor
//*  Given file handler is transparent to the MP4 library, and used only as
//*  argument for given fwrite_callback() function.  By appropriate definition
//*  of callback function application may use any other file output API (for
//*  example C++ streams, or Win32 file functions)
//*
//*  return multiplexor handle on success; NULL on failure
//
fn C.MP4E_open(sequential_mode_flag int, enable_fragmentation int, token voidptr, write_callback fn (i64, voidptr, usize, voidptr) int) &MP4E_mux_t

pub fn mp_4_e_open(sequential_mode_flag int, enable_fragmentation int, token voidptr, write_callback fn (i64, voidptr, usize, voidptr) int) &MP4E_mux_t {
	return C.MP4E_open(sequential_mode_flag, enable_fragmentation, token, write_callback)
}

//*
//*  Add new track
//*  The track_data parameter does not referred by the multiplexer after function
//*  return, and may be allocated in short-time memory. The dsi member of
//*  track_data parameter is mandatory.
//*
//*  return ID of added track, or error code MP4E_STATUS_*
//
fn C.MP4E_add_track(mux &MP4E_mux_t, track_data &MP4E_track_t) int

pub fn mp_4_e_add_track(mux &MP4E_mux_t, track_data &MP4E_track_t) int {
	return C.MP4E_add_track(mux, track_data)
}

//*
//*  Add new sample to specified track
//*  The tracks numbered starting with 0, according to order of MP4E_add_track() calls
//*  'kind' is one of MP4E_SAMPLE_... defines
//*
//*  return error code MP4E_STATUS_*
//*
//*  Example:
//*      MP4E_put_sample(mux, 0, data, data_bytes, duration, MP4E_SAMPLE_DEFAULT);
//
fn C.MP4E_put_sample(mux &MP4E_mux_t, track_num int, data voidptr, data_bytes int, duration int, kind int) int

pub fn mp_4_e_put_sample(mux &MP4E_mux_t, track_num int, data voidptr, data_bytes int, duration int, kind int) int {
	return C.MP4E_put_sample(mux, track_num, data, data_bytes, duration, kind)
}

//*
//*  Finalize MP4 file, de-allocated memory, and closes MP4 multiplexer.
//*  The close operation takes a time and disk space, since it writes MP4 file
//*  indexes.  Please note that this function does not closes file handle,
//*  which was passed to open function.
//*
//*  return error code MP4E_STATUS_*
//
fn C.MP4E_close(mux &MP4E_mux_t) int

pub fn mp_4_e_close(mux &MP4E_mux_t) int {
	return C.MP4E_close(mux)
}

//*
//*  Set Decoder Specific Info (DSI)
//*  Can be used for audio and private tracks.
//*  MUST be used for AAC track.
//*  Only one DSI can be set. It is an error to set DSI again
//*
//*  return error code MP4E_STATUS_*
//
fn C.MP4E_set_dsi(mux &MP4E_mux_t, track_id int, dsi voidptr, bytes int) int

pub fn mp_4_e_set_dsi(mux &MP4E_mux_t, track_id int, dsi voidptr, bytes int) int {
	return C.MP4E_set_dsi(mux, track_id, dsi, bytes)
}

//*
//*  Set VPS data. MUST be used for HEVC (H.265) track.
//*
//*  return error code MP4E_STATUS_*
//
fn C.MP4E_set_vps(mux &MP4E_mux_t, track_id int, vps voidptr, bytes int) int

pub fn mp_4_e_set_vps(mux &MP4E_mux_t, track_id int, vps voidptr, bytes int) int {
	return C.MP4E_set_vps(mux, track_id, vps, bytes)
}

//*
//*  Set SPS data. MUST be used for AVC (H.264) track. Up to 32 different SPS can be used in one track.
//*
//*  return error code MP4E_STATUS_*
//
fn C.MP4E_set_sps(mux &MP4E_mux_t, track_id int, sps voidptr, bytes int) int

pub fn mp_4_e_set_sps(mux &MP4E_mux_t, track_id int, sps voidptr, bytes int) int {
	return C.MP4E_set_sps(mux, track_id, sps, bytes)
}

//*
//*  Set PPS data. MUST be used for AVC (H.264) track. Up to 256 different PPS can be used in one track.
//*
//*  return error code MP4E_STATUS_*
//
fn C.MP4E_set_pps(mux &MP4E_mux_t, track_id int, pps voidptr, bytes int) int

pub fn mp_4_e_set_pps(mux &MP4E_mux_t, track_id int, pps voidptr, bytes int) int {
	return C.MP4E_set_pps(mux, track_id, pps, bytes)
}

//*
//*  Set or replace ASCII test comment for the file. Set comment to NULL to remove comment.
//*
//*  return error code MP4E_STATUS_*
//
fn C.MP4E_set_text_comment(mux &MP4E_mux_t, comment &i8) int

pub fn mp_4_e_set_text_comment(mux &MP4E_mux_t, comment &i8) int {
	return C.MP4E_set_text_comment(mux, comment)
}

// MINIMP4_H
// ChunkLargeOffsetAtomType
// ChunkOffsetAtomType
// ClockReferenceMediaHeaderAtomType
// CompositionOffsetAtomType
// CopyrightAtomType
// DataEntryURLAtomType
// DataEntryURNAtomType
// DataInformationAtomType
// DataReferenceAtomType
// DegradationPriorityAtomType
// EditAtomType
// EditListAtomType
// ExtendedAtomType
// FreeSpaceAtomType
// HandlerAtomType
// HintMediaHeaderAtomType
// HintTrackReferenceAtomType
// MediaAtomType
// MediaDataAtomType
// MediaHeaderAtomType
// MediaInformationAtomType
// MovieAtomType
// MovieHeaderAtomType
// SampleDescriptionAtomType
// SampleSizeAtomType
// CompactSampleSizeAtomType
// SampleTableAtomType
// SampleToChunkAtomType
// ShadowSyncAtomType
// SkipAtomType
// SoundMediaHeaderAtomType
// SyncSampleAtomType
// TimeToSampleAtomType
// TrackAtomType
// TrackHeaderAtomType
// TrackReferenceAtomType
// UserDataAtomType
// VideoMediaHeaderAtomType
// GenericVisualSampleEntryAtomType
// GenericAudioSampleEntryAtomType
// V2 atoms
// FileTypeAtomType
// PaddingBitsAtomType
// MP4 Atoms
// SceneDescriptionMediaHeaderAtomType
// StreamDependenceAtomType
// ObjectDescriptorAtomType
// ObjectDescriptorMediaHeaderAtomType
// ODTrackReferenceAtomType
// MPEGMediaHeaderAtomType
// ESDAtomType
// OCRReferenceAtomType
// IPIReferenceAtomType
// MPEGSampleEntryAtomType
// MPEGAudioSampleEntryAtomType
// MPEGVisualSampleEntryAtomType
// http://www.itscj.ipsj.or.jp/sc29/open/29view/29n7644t.doc
// H264/HEVC
// 3GPP atoms
// AMRSampleEntryAtomType
// WB_AMRSampleEntryAtomType
// AMRConfigAtomType
// H263SampleEntryAtomType
// H263ConfigAtomType
// V2 atoms - Movie Fragments
// MovieExtendsAtomType
// TrackExtendsAtomType
// MovieFragmentAtomType
// MovieFragmentHeaderAtomType
// TrackFragmentAtomType
// TrackFragmentHeaderAtomType
// TrackFragmentBaseMediaDecodeTimeBox
// TrackFragmentRunAtomType
// MovieExtendsHeaderBox
// Object Descriptors (OD) data coding
// These takes only 1 byte; this implementation translate <od_tag> to
// <od_tag> + OD_BASE to keep API uniform and safe for string functions
//
// SDescriptor_Tag
// DecoderConfigDescriptor_Tag
// DecoderSpecificInfo_Tag
// SLConfigDescriptor_Tag
// Metagata tags, see http://atomicparsley.sourceforge.net/mpeg-4files.html
// album
// artist
// album artist
// comment
// year (as string)
// title
// custom genre (as string or as byte!)
// track number (byte)
// disk number (byte)
// composer
// encoder
// bpm (byte)
// compilation (byte)
// cover art (JPEG/PNG)
// rating/advisory (byte)
// grouping
// stik (byte)  0 = Movie   1 = Normal  2 = Audiobook  5 = Whacked Bookmark  6 = Music Video  9 = Short Film  10 = TV Show  11 = Booklet  14 = Ringtone
// podcast (byte)
// category
// keyword
// podcast URL (byte)
// episode global unique ID (byte)
// description
// lyrics (may be > 255 bytes)
// tv episode number
// tv episode (byte)
// tv network name
// tv show name
// tv season (byte)
// purchase date
// Gapless Playback (byte)
// BOX_aart   = FOUR_CHAR_INT( 'a', 'a', 'r', 't' ),     // Album artist
// artist
// 3GPP metatags  (http://cpansearch.perl.org/src/JHAR/MP4-Info-1.12/Info.pm)
// author
// title
// description
// performer
//
//
//
// these from http://lists.mplayerhq.hu/pipermail/ffmpeg-devel/2008-September/053151.html
// album
// album
// Video track : 'vide'
// Audio track : 'soun'
// General MPEG-4 systems streams (without specific handler).
// Used for private stream, as suggested in http://www.mp4ra.org/handler.html
// sample descriptor
// or dsi for audio
// not used for audio
// used for HEVC
// flag, indicating streaming-friendly 'fragmentation' mode
// # of fragments in 'fragmentation' mode
// as in ffmpeg
//*
//*  Endian-independent byte-write macros
//
// Finish atom: update atom size field
// Initiate atom: save position of size field on stack
// Atom with 'FullAtomVersionFlags' field
//*
//    Allocate vector with given size, return 1 on success, 0 on fail
//
//*
//    Deallocates vector memory
//
//*
//    Reallocate vector memory to the given size
//
//*
//    Allocates given number of bytes at the end of vector data, increasing
//    vector memory if necessary.
//    Return allocated memory.
//
//*
//    Append data to the end of the vector (accumulate ot enqueue)
//
//*
//*  Allocates and initialize mp4 multiplexer
//*  return multiplexor handle on success; NULL on failure
//
// Write fixed header: 'ftyp' box
// Write filler, which would be updated later
// box_ftyp + box_free for 32bit or 64bit size encoding
//*
//*  Add new track
//
// only one DSI allowed
// if have pending sample && have at least one sample in the index
// Complete pending sample
// Write each sample to a separate atom
// Separate atom needed for sequential_mode only
// Update sample descriptor with size and offset
// Write data
// reset buffer
//*
//*  Write Movie Fragment: 'moof' box
//
// atoms nesting stack
// start from 1
// default-sample-flags-present
// default-sample-duration-present
// track_ID
// default_sample_flags
// version 1
// upper timestamp
// lower timestamp
// data-offset-present
// sample-size-present
// sample_count
// save ptr to data_offset
// sample_size
// data-offset-present
// first-sample-flags-present
// sample-duration-present
// sample-size-present
// sample_count
// save ptr to data_offset
// first_sample_flags
// sample_duration
// sample_size
// data-offset-present
// sample-duration-present
// sample-size-present
// sample_count
// save ptr to data_offset
// sample_duration
// sample_size
//*
//*  Add new sample to specified track
//
// NOTE: assume a constant `duration` to calculate current timestamp
// write file headers before 1st sample
// write MOOF + MDAT + sample data
// write MDAT box for each sample
// write continuation, but there are no samples in the index
// Accumulate size of the continuation in the sample descriptor
//*
//*  calculate size of length field of OD box
//
//*
//*  Add or remove MP4 file text comment according to Apple specs:
//*  https://developer.apple.com/library/mac/documentation/QuickTime/QTFF/Metadata/Metadata.html#//apple_ref/doc/uid/TP40000939-CH1-SW1
//*  http://atomicparsley.sourceforge.net/mpeg-4files.html
//*  note that ISO did not specify comment format.
//
//*
//*  Write file index 'moov' box with all its boxes and indexes
//
// atoms nesting stack
// How much memory needed for indexes
// Experimental data:
// file with 1 track = 560 bytes
// file with 2 tracks = 972 bytes
// track size = 412 bytes;
// file header size = 148 bytes
// fixed amount (implementation-dependent)
// may need extra 4 bytes for duration field + 4 bytes for worst-case random access box
// update size of mdat box.
// One of 2 points, which requires random file access.
// Second is optional duration update at beginning of file in fragmentation mode.
// This can be avoided using "till eof" size code, but in this case indexes must be
// written before the mdat....
// Write index atoms; order taken from Table 1 of [1]
// creation_time
// modification_time
// take 1st track
// duration
// duration
// rate
// volume
// reserved
// reserved
// reserved
// matrix[9]
// pre_defined[6]
// next_track_ID is a non-zero integer that indicates a value to use for the track ID of the next track to be
// added to this presentation. Zero is not a valid track ID value. The value of next_track_ID shall be
// larger than the largest track-ID in use.
// skip empty track
// flag: 1=trak enabled; 2=track in movie; 4=track in preview
// creation_time
// modification_time
// track_ID
// reserved
// reserved[2]
// layer
// alternate_group
// volume {if track_is_audio 0x0100 else 0};
// reserved
// matrix[9]
// width
// height
// width
// height
// creation_time
// modification_time
// duration
// language
// pre_defined
// pre_defined
// handler_type
// reserved[3]
// name is a null-terminated string in UTF-8 characters which gives a human-readable name for the track type (for debugging and inspection purposes).
// set mdia hdlr name field to what quicktime uses.
// Sony smartphone may fail to decode short files w/o handler name
// Sound Media Header Box
// balance
// reserved
// mandatory Video Media Header Box
// graphicsmode
// opcolor[3]
// entry_count
// If the flag is set indicating that the data is in the same file as this box, then no string (not even an empty one)
// shall be supplied in the entry field.
// ASP the correct way to avoid supply the string, is to use flag 1
// otherwise ISO reference demux crashes
// entry_count;
// AudioSampleEntry() assume MP4E_HANDLER_TYPE_SOUN
// SampleEntry
// reserved[6]
// data_reference_index; - this is a tag for descriptor below
// AudioSampleEntry
// reserved[2]
// channelcount
// samplesize
// pre_defined+reserved
// samplerate == = {timescale of media}<<16;
//  - two bytes size field
// OD_ESD
// ES_ID(2) // TODO - what is this?
// flags(1)
// OD_DCD
// OD_DCD
// stream_type == AudioStream
// http://xhelmboyx.tripod.com/formats/mp4-layout.txt
// 208 = private video
// stream_type == user private
// bufferSizeDB in bytes, constant as in reference decoder
// maxBitrate TODO
// avg_bitrate_bps TODO
// OD_DSI
// VisualSampleEntry  8.16.2
// extends SampleEntry
// reserved
// reserved
// reserved
// data_reference_index
// pre_defined
// reserved
// pre_defined
// pre_defined
// pre_defined
// horizresolution = 72 dpi
// vertresolution  = 72 dpi
// reserved
// frame_count
//  compressorname
// depth
// pre_defined
// AVCDecoderConfigurationRecord 5.2.4.1.1
// configurationVersion
// 0xfc + NALU_len - 1
// TODO: read actual params from stream
// configurationVersion
// Profile Space (2), Tier (1), Profile (5)
// Profile Compatibility
// progressive, interlaced, non packed constraint, frame only constraint flags
// constraint indicator flags
// level_idc
// Min Spatial Segmentation
// Parallelism Type
// Chroma Format
// Luma Depth
// Chroma Depth
// Avg Frame Rate
// ConstantFrameRate (2), NumTemporalLayers (3), TemporalIdNested (1), LengthSizeMinusOne (2)
// Num Of Arrays
// Array Completeness + NAL Unit Type
//***********************************
//      indexes
//***********************************
// Time to Sample Box
// Sample To Chunk Box
// entry_count
// entry_count
// first_chunk;
// samples_per_chunk;
// sample_description_index;
// Sample Size Box
// sample_size  If this field is set to 0, then the samples have different sizes, and those sizes
//  are stored in the sample size table.
// sample_count;
// Chunk Offset Box
// Sync Sample Box
// If the sync sample box is not present, every sample is a random access point.
// tracks loop
// pre_defined
// handler_type
// reserved[3]
// name is a null-terminated string in UTF-8 characters which gives a human-readable name for the track type (for debugging and inspection purposes).
// type
// lang
// duration
// track_ID
// default_sample_description_index
// default_sample_duration
// default_sample_size
// default_sample_flags
// moov atom
// Look-ahead bit cache: MSB aligned, 17 bits guaranteed, zero stuffing
// Bit counter = 16 - (number of bits in wCache)
// cache refilled when cache_free_bits >= 0
// Current read position
// original data buffer
// original data buffer length, bytes
// Current bitbuffer position =
// position of next wobits in the internal buffer
// minus bs, available in bit cache wobits
//*
//*  Unsigned Golomb code
//
// get_bits(bs, clz + 1);
//*
//*  Output bitstream
//
// bit position in the cache
// bit cache
// current position
// initial position
//*
//*  Golomb code
//*  0 => 1
//*  1 => 01 0
//*  2 => 01 1
//*  3 => 001 00
//*  4 => 001 01
//*
//*  [0]     => 1
//*  [1..2]  => 01x
//*  [3..6]  => 001xx
//*  [7..14] => 0001xxx
//*
//
// found
// put in
// no room
//*
//*  7.4.1.1. "Encapsulation of an SODB within an RBSP"
//
// cabac_zero_word: no action
// TODO: assume end-of-nal
// return 0;
// while (--j > i) src[j] = 0;
//*
//*  Put NAL escape codes to the output bitstream
//
// start code
// cut extra zeros after stop-bit
// max = 31
// max = 255
// max = 31
//*
//*  Set pointer just after start code (00 .. 00 01), or to EOF if not found:
//*
//*  NZ NZ ... NZ 00 00 00 00 01 xx xx ... xx (EOF)
//*                              ^            ^
//*  non-zero head.............. here ....... or here if no start code found
//*
//
//*
//*  Locate NAL unit in given buffer, and calculate it's length
//
// printf("payload_type=%d, intra=%d\n", payload_type, is_intra);
// access unit delimiter, nothing to be done
// Transcode SPS, PPS and slice headers, reassigning ID's for SPS and  PPS:
// - assign unique ID's to different SPS and PPS
// - assign same ID's to equal (except ID) SPS and PPS
// - save all different SPS and PPS
// flow through
// unsigned slice_type = ue_bits(bs);
// No SPS/PPS transcoding
// This branch assumes that encoder use correct SPS/PPS ID's
// flow through
//*
//*  Read given number of bytes from input stream
//*  Used to read box headers
//
//*
//*  Read given number of bytes, but no more than *ayload_bytes specifies...
//*  Used to read box payload
//
//*
//*  Skips given number of bytes.
//*  Avoid math operations with fpos_t
//
//
//*  On error: release resources.
//
//
//*  Any errors, occurred on top-level hierarchy is passed to exit check: 'if (!mp4->track_count) ... '
//
// box stack size
// remaining bytes for box in the stack
// kind of box children's: OD chunks handled in the same manner as name chunks
// path of current element: List0/List1/... etc
// start with atom box
// never accessed
// List of boxes, derived from 'FullBox'
//                ~~~~~~~~~~~~~~~~~~~~~
// need read version field and check version for these boxes
// Android can produce meta box without 'FullBox' field, comment this line to simulate the bug
// esds does not use track, but switches to OD mode. Check here, to avoid OD check
// List of boxes, which contains other boxes ('envelopes')
// Parser will descend down for boxes in this list, otherwise parsing will proceed to
// the next sibling box
// OD boxes handled in the same way as atom boxes...
// TODO: BOX_esds can be used for both audio and video, but this code supports audio only!
// {BOX_moof, BOX_ATOM},
// {BOX_avc2, BOX_ATOM},
// {BOX_svc1, BOX_ATOM},
// Read header box type and it's length
// normal exit
// Decode box size
// standard indication of 'till eof' size
// some files uses non-standard 'till eof' signaling
// 64-bit sizes
// Read and check box version for some boxes
// Fix invalid BOX_meta, found in some Android-produced MP4
// This branch is optional: bad box would be skipped
// +4 need for missing header
// FIX_BAD_ANDROID_META_BOX
// stack[depth].format == BOX_OD
// 1-byte box type
// Check that box size <= parent size
// Skip box with bad size
// Read box header
// ISO/IEC 14496-1 Page 38. Section 8.17.2 - Sample Size Box.
// ISO/IEC 14496-12 Page 38. Section 8.18 - Sample To Chunk Box.
// sample_description_index
// ISO/IEC 14496-12 Page 39. Section 8.19 - Chunk Offset Box.
// the rest of this box is skipped by default ...
// When this box is within 'meta' box, the track may not be avaialable
// pre_defined
// typically hdlr box does not contain any useful info.
// the rest of this box is skipped by default ...
// Set pointer to tag to be read...
// entry_count, BOX_mp4a & BOX_mp4v boxes follows immediately
// private stream
// Base SampleEntry
// Base SampleEntry
// samplesize
// AVCSampleEntry extends VisualSampleEntry
//         case BOX_avc2:   - no test
//         case BOX_svc1:   - no test
// Base SampleEntry
// frame_count is always 1
// compressorname is rarely set..
// frame_count
// compressorname
// ^^^ end of VisualSampleEntry
// now follows for BOX_avc1:
//      BOX_avcC
//      BOX_btrt (optional)
//      BOX_m4ds (optional)
// for BOX_mp4v:
//      BOX_esds
// AVCDecoderConfigurationRecord()
// hack: AAC-specific DSI field reused (for it have same purpoose as sps/pps)
// TODO: check this hack if BOX_esds co-exist with BOX_avcC
// bit(6) reserved =
// clears 3 msb for SPS
// MP4D_AVC_SUPPORTED
// ES_ID(2) + flags(1)
// steamdependflag
// dependsOnESID
// urlflag
// skip URL
// ocrflag (was reserved in MPEG-4 v.1)
// OCRESID
// ISO/IEC 14496-1 Page 28. Section 8.6.5 - DecoderConfigDescriptor.
// ensured by g_fullbox[] check
// bufferSizeDB
// maxBitrate
// ISO/IEC 14496-1 Page 28. Section 8.6.5 - DecoderConfigDescriptor.
// ensured by g_fullbox[] check
// These bytes available due to check above
// Read tag is tag pointer is set
// zero-terminated string
// New track found: allocate memory using realloc()
// Typically there are 1 audio track for AAC audio file,
// 4 tracks for movie file,
// 3-5 tracks for scalable audio (CELP+AAC)
// and up to 50 tracks for BSAC scalable audio
// if realloc fails, it does not deallocate old pointer!
// Avoid update of 'hdlr' box, which may contains in the 'meta' box
// If this box is envelope, save it's size in box stack
// if box is not envelope, just skip it
// remove empty boxes from stack
// don't touch box with index 0 (which indicates whole file)
//*
//*  Find chunk, containing given sample.
//*  Returns chunk number, and first sample in this chunk.
//
// stuck at last entry till EOF
// Chunks counted starting with '1'
// next group?
// TODO: this can be calculated once per file
// Exported API function
// Exported API function
// SPS/PPS are specific for AVC format only
// Skip all SPS
// Skip sps/pps before the given target
//***********************************
//  Purely informational part, may be removed for embedded applications
//***********************************
//
// Decodes ISO/IEC 14496 MP4 stream type to ASCII string
//
//
// Decodes ISO/IEC 14496 MP4 object type to ASCII string
//
//*
//*  Print MP4 information to stdout.
//*  Subject for customization to particular application
//
// Output Example #1: movie file
//
// MP4 FILE: 7 tracks found. Movie time 104.12 sec
//
// No|type|lng| duration           | bitrate| Stream type            | Object type
// 0|odsm|fre|   0.00 s      1 frm|       0| Forbidden              | Forbidden
// 1|sdsm|fre|   0.00 s      1 frm|       0| Forbidden              | Forbidden
// 2|vide|```| 104.12 s   2603 frm| 1960559| VisualStream           | Visual ISO/IEC 14496-2   -  720x304
// 3|soun|ger| 104.06 s   2439 frm|  191242| AudioStream            | Audio ISO/IEC 14496-3    -  6 ch 24000 hz
// 4|soun|eng| 104.06 s   2439 frm|  194171| AudioStream            | Audio ISO/IEC 14496-3    -  6 ch 24000 hz
// 5|subp|ger|  71.08 s     25 frm|       0| Forbidden              | Forbidden
// 6|subp|eng|  71.08 s     25 frm|       0| Forbidden              | Forbidden
//
// Output Example #2: audio file with tags
//
// MP4 FILE: 1 tracks found. Movie time 92.42 sec
// title = 86-Second Blowout
// artist = Yo La Tengo
// album = May I Sing With Me
// year = 1992
//
// No|type|lng| duration           | bitrate| Stream type            | Object type
// 0|mdir|und|  92.42 s   3980 frm|  128000| AudioStream            | Audio ISO/IEC 14496-3MP4 FILE: 1 tracks found. Movie time 92.42 sec
//
//
// MP4D_PRINT_INFO_SUPPORTED
