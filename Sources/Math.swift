#if os(WASI)
@_exported import func WASILibc.pow
@_exported import func WASILibc.log10
@_exported import func WASILibc.log
@_exported import func WASILibc.sin
@_exported import func WASILibc.cos
#elseif canImport(Bionic)
@_exported import func Bionic.pow
@_exported import func Bionic.acosf
@_exported import func Bionic.log10
@_exported import func Bionic.log
@_exported import func Bionic.sin
@_exported import func Bionic.sinf
@_exported import func Bionic.cos
@_exported import var Bionic.CLOCK_REALTIME
@_exported import func Bionic.clock_gettime
@_exported import struct Bionic.timespec
@_exported import struct Bionic.clockid_t
#elseif canImport(Darwin)
@_exported import func Foundation.pow
@_exported import func Foundation.log10
@_exported import func Foundation.log
@_exported import func Foundation.sin
@_exported import func Foundation.cos
@_exported import func Foundation.clock_gettime
@_exported import struct Foundation.timespec
#endif
