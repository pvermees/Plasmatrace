using Debugger

odir = pwd()
cd(@__DIR__)

include("../src/include.jl")
include("tests.jl")
#PT("logs/emacs.log")

myrun = load("/home/pvermees/Documents/Plasmatrace/14_10_22_grt_cc_fluo",
             instrument="Agilent");

blk = fitBlanks(myrun,n=2);
standards = Dict("ME-1" => "ME1");
setStandards!(myrun,standards);
anchors = getAnchor("Lu-Hf",standards);
channels = Dict("d"=>"Hf178 -> 260",
                "D"=>"Hf176 -> 258",
                "P"=>"Lu175 -> 175");

fit = fractionation(myrun,blank=blk,channels=channels,
                    anchors=anchors,nf=1,nF=0,mf=1,
                    verbose=true);

ratios = averat(myrun,channels=channels,pars=fit,blank=blk);
selection = subset(ratios,"Adrian_cc");
export2IsoplotR("Adrian.json",selection,"Lu-Hf");

cd(odir)
