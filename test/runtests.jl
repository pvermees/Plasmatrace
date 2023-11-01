using Plasmatrace

# aliases to access non-exported functions
const blankData = Plasmatrace.blankData
const getBPar = Plasmatrace.getBPar
const parseBPar = Plasmatrace.parseBPar
const polyVal = Plasmatrace.polyVal
const setAB! = Plasmatrace.setAB!
const findSamples = Plasmatrace.findSamples
const setSPar! = Plasmatrace.setSPar!
const getChannels = Plasmatrace.getChannels
const findSamples = Plasmatrace.findSamples
const run = Plasmatrace.run

include("tests.jl")
