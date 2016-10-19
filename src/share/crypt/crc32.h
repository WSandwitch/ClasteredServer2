#ifndef CRC32_HEADER
#define CRC32_HEADER

#include <stdint.h>
namespace share {

	uint32_t crc32(const void *buf, size_t size);
}
#endif