#if os(WASI)
@_exported import func WASILibc.pow
@_exported import func WASILibc.log10
@_exported import func WASILibc.log2
@_exported import func WASILibc.sin
@_exported import func WASILibc.cos
#elseif canImport(Glibc)
@_exported import func Glibc.pow
@_exported import func Glibc.log10
@_exported import func Glibc.log2
@_exported import func Glibc.sin
@_exported import func Glibc.cos
@_exported import var Glibc.CLOCK_REALTIME
@_exported import func Glibc.clock_gettime
@_exported import struct Glibc.timespec
@_exported import struct Glibc.clockid_t
#elseif canImport(Darwin)
@_exported import func Foundation.pow
@_exported import func Foundation.log10
@_exported import func Foundation.log2
@_exported import func Foundation.sin
@_exported import func Foundation.cos
@_exported import func Foundation.clock_gettime
@_exported import struct Foundation.timespec
#endif
