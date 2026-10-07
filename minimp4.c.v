// Compiles the bundled minimp4 implementation into importing applications.
// Feature macros here select the C implementation used by the V declarations.
module minimp4

#flag -I @VMODROOT/include

#define MINIMP4_IMPLEMENTATION
/*
#define MP4D_PRINT_INFO_SUPPORTED
#define MINIMP4_TRANSCODE_SPS_ID
#define MP4D_TRACE_TIMESTAMPS
#define MP4D_TRACE_SUPPORTED
#define MP4D_64BIT_SUPPORTED
#define MP4D_AVC_SUPPORTED
#define MP4D_INFO_SUPPORTED
#define MP4D_TIMESTAMPS_SUPPORTED
#define MINIMP4_IMPLEMENTATION
#define MP4D_PRINT_INFO_SUPPORTED
*/
#include "minimp4.h"
