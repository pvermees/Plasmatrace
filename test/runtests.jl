using Plasmatrace

# aliases to access non-exported functions
const blankData = Plasmatrace.blankData
const getBlankPars = Plasmatrace.getBlankPars
const parseBPar = Plasmatrace.parseBPar
const polyVal = Plasmatrace.polyVal
const setAB! = Plasmatrace.setAB!
const findSamples = Plasmatrace.findSamples
const setDriftPars! = Plasmatrace.setDriftPars!
const setDownPars! = Plasmatrace.setDownPars!
const setMassPars! = Plasmatrace.setMassPars!
const getChannels = Plasmatrace.getChannels
const findSamples = Plasmatrace.findSamples
const run = Plasmatrace.run

include("tests.jl")
