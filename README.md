
# minimp4 bindings for V

Low-level V bindings for the bundled
[`lieff/minimp4`](https://github.com/lieff/minimp4) single-header library.
The module exposes MP4 demuxing and muxing structures and functions, including
sample offsets/timestamps and AVC parameter-set access used by
[`v_vulkan_video`](https://github.com/antono2/v_vulkan_video).

This is a container library, not an audio or video codec. It does not decode
compressed samples into pixels or audio.

## Install

```bash
v install https://github.com/antono2/minimp4
```

The C implementation and header are compiled from this module; users do not
need to install a separate `minimp4` system package. A working C compiler is
required when building an application that imports it.

## API scope

The public API intentionally follows the upstream C names closely. Important
entry points include `mp4d_open`, `mp4d_frame_offset`, `mp4d_read_sps`,
`mp4d_read_pps`, and `mp4d_close`, plus the `mp_4_e_*` muxing functions.

Callers own the input/output callbacks and their backing data. Validate file
sizes, track indexes, sample indexes, offsets, and returned pointers before
using data from untrusted media.

## Tests

Run the software-only binding smoke tests with:

```bash
v test .
```

These compile and link the bundled C implementation and verify representative
public constants and ABI structures. End-to-end MP4 playback is tested by the
Vulkan Video player.
