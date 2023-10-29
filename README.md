# TSCrunch 6502 Decompressor Acorn BeebAsm Port

This is a BeebAsm 6502 port of https://github.com/tonysavon/TSCrunch/

An optimal, byte-aligned, LZ+RLE hybrid encoder, designed to maximize decoding speed on NMOS 6502 and derived CPUs

TSCrunch is designed for ultra-fast decrunching while keeping a decent compression ratio. Being a byte-cruncher, it falls short of popular bit-crunchers, such as exomizer or B2, when comparing compression efficiency, but it is usually much faster at decoding. Furthermore, you can expect a 20% to 40% speed bump compared to popular byte-crunchers with similar compression efficiency. 