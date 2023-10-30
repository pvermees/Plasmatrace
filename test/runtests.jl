using Plasmatrace

# aliases to access non-exported functions
const blankData = Plasmatrace.blankData
const getBPar = Plasmatrace.getBPar
const parseBPar = Plasmatrace.parseBPar
const polyVal = Plasmatrace.polyVal
const label2index = Plasmatrace.label2index
const getLabels = Plasmatrace.getLabels
const setDRS! = Plasmatrace.setDRS!
const findSamples = Plasmatrace.findSamples
const setSPar! = Plasmatrace.setSPar!
const getChannels = Plasmatrace.getChannels
const findSamples = Plasmatrace.findSamples

include("tests.jl")

include("testsets.jl")
