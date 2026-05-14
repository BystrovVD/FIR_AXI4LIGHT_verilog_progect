import sys
from systemrdl import RDLCompiler, RDLCompileError
from peakrdl_regblock import RegblockExporter
from peakrdl_regblock.cpuif.axi4lite import AXI4Lite_Cpuif
from peakrdl_regblock.udps import ALL_UDPS



input_files = ["my_regfile.rdl", "my_addrmap.rdl"]

rdlc = RDLCompiler()

for udp in ALL_UDPS:
    rdlc.register_udp(udp)

try:
    for f in input_files:
        rdlc.compile_file(f)

    root = rdlc.elaborate()
except RDLCompileError:
    sys.exit(1)

exporter = RegblockExporter()

exporter.export(
    root,"gen_rtl",
    cpuif_cls=AXI4Lite_Cpuif
)
print("complete in 'gen_rtl'")