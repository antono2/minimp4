
# minimp4 bindings for V

[Project portfolio](https://oreskin.de/projects_en.php)

Low-level V bindings for the bundled
[`lieff/minimp4`](https://github.com/lieff/minimp4) single-header library.
The module exposes MP4 demuxing and muxing structures and functions, including
sample offsets/timestamps and AVC parameter-set access used by
[`v_vulkan_video`](https://github.com/antono2/v_vulkan_video).

This is a container library, not an audio or video codec. It does not decode
compressed samples into pixels or audio.

## Install

```bash
v install antono2.minimp4
```

The C implementation and header are compiled from this module; users do not
need to install a separate `minimp4` system package. A working C compiler is
required when building an application that imports it.

## Platform support

The bundled C implementation is tested on Linux and on Windows Server 2022
with MSVC. Windows 10/11 x64 users do not need a separate minimp4 package;
install V with a working Microsoft C toolchain and use the same `v install`
command shown above.

## API scope

The public API intentionally follows the upstream C names closely. Important
entry points include `mp4d_open`, `mp4d_frame_offset`, `mp4d_read_sps`,
`mp4d_read_pps`, and `mp4d_close`, plus the `mp_4_e_*` muxing functions.

Callers own the input/output callbacks and their backing data. Validate file
sizes, track indexes, sample indexes, offsets, and returned pointers before
using data from untrusted media.

Read and write callbacks must return `i32`, matching the bundled C library's
32-bit status result, rather than V's platform-sized `int`. Return zero for
success and a nonzero value for an I/O error. When updating older callers,
change the callback's return type from `int` to `i32`; its offset, buffer, size,
and token arguments are unchanged. This also makes forwarded callbacks safe
with V3 on 64-bit platforms.

## Resource lifetime and timing

`mp4d_open` returns 1 on success and 0 on failure. After a successful open,
arrange a matching `mp4d_close` to release the demuxer's internal allocations.
Keep the callback token and backing input alive while the demuxer is in use.
Track arrays and SPS/PPS pointers belong to the demuxer; copy any data you need
to retain before closing it.

`mp4d_frame_offset` locates a sample; it does not read the sample bytes for you.
Use the returned offset and byte count to read from your backing input.
Timestamps and durations use the selected track's `timescale`, not milliseconds:
divide by a nonzero `timescale` to convert to seconds. Validate track and sample
indexes against `track_count` and the track's `sample_count` first.

`mp_4_e_open` returns a null pointer on failure. Keep the output callback and its
token usable through `mp_4_e_close`: closing can write the final MP4 indexes and
return an I/O error. Check that return value before treating the output as
complete. Closing the muxer does not close your backing file or stream.
The [round-trip test](minimp4_test.v) shows callback signatures, track creation,
parameter-set setup, sample writing, finalization, and demux queries together.

## Source layout

- `minimp4.v` contains the translated public structures, constants, and C
  wrappers, with upstream API comments. Callback ABI adjustments are maintained
  in the committed binding.
- `minimp4.c.v` selects and compiles the bundled C implementation.
- `minimp4_test.v` checks callback forwarding and container operations in memory.
- `include/minimp4.h` is the bundled upstream library; preserve its documentation
  and license. `include/c2v.toml` records translation flags, but the repository
  currently has no pinned, end-to-end regeneration script. Review translation
  changes against the committed ABI rather than blindly replacing the binding.

## Tests

Run the software-only binding smoke tests with:

```bash
v test .
```

On Windows, the CI-equivalent command is:

```powershell
v -cc msvc test .
```

These compile and link the bundled C implementation and verify representative
public constants and ABI structures, reject truncated input, and exercise an
in-memory mux/demux round trip with sample offset, size, timestamp, and duration
checks. End-to-end MP4 playback is tested by the Vulkan Video player.

CI also runs strict V3 callback tests with TinyCC on Linux and MSVC on Windows.
Compiler/bootstrap revisions are pinned in the workflow. The Windows lane
uses the stack's last validated V3 snapshot while current upstream V has an
MSVC self-build regression; the Linux lane covers the newer callback-width
diagnostic without falling back to the compatibility compiler.
For that pinned Windows V3 version, use
`v -new-compiler -cc msvc -cflags /DWIN32_LEAN_AND_MEAN test .` so that
Windows headers do not load legacy Winsock before Winsock2.

## License

The bindings and bundled upstream implementation are distributed under
[CC0-1.0](LICENSE), matching minimp4's public-domain dedication.
