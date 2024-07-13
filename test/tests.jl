# include("/home/pvermees/git/Plasmatrace/test/emacs.jl")

using Test, CSV
import Plots

function loadtest(verbatim=false)
    myrun = load("data/Lu-Hf",instrument="Agilent")
    if verbatim summarise(myrun) end
    return myrun
end

function plottest()
    myrun = loadtest()
    p = plot(myrun[1],["Hf176 -> 258","Hf178 -> 260"])
    @test display(p) != NaN
    p = plot(myrun[1],["Hf176 -> 258","Hf178 -> 260"], den="Hf178 -> 260")
    @test display(p) != NaN
end

function windowtest()
    myrun = loadtest()
    i = 2
    setSwin!(myrun[i],[(70,90),(100,140)])
    p = plot(myrun[i],["Hf176 -> 258","Hf178 -> 260"])
    @test display(p) != NaN
end

function blanktest()
    myrun = loadtest()
    blk = fitBlanks(myrun,nb=2)
    return myrun, blk
end

function standardtest(verbatim=false)
    myrun, blk = blanktest()
    standards = Dict("BP" => "BP")
    setStandards!(myrun,standards)
    anchors = getAnchor("Lu-Hf",standards)
    if verbatim
        summarise(myrun)
    end
end

function fractionationtest()
    myrun, blk = blanktest()
    channels = Dict("d" => "Hf178 -> 260",
                    "D" => "Hf176 -> 258",
                    "P" => "Lu175 -> 175")
    standards = Dict("Hogsbo" => "hogsbo_ana")
    setStandards!(myrun,standards)
    anchors = getAnchor("Lu-Hf",standards)
    fit = fractionation(myrun,blank=blk,channels=channels,
                        anchors=anchors,nf=2,nF=1,
                        mf=1.4671,verbose=true)
    return myrun, blk, fit, channels, anchors
end

function predicttest()
    myrun, blk, fit, channels, anchors = fractionationtest()
    samp = myrun[2]
    if samp.group == "sample"
        print("Not a standard")
    else
        pred = predict(samp,fit,blk,channels,anchors)
    end
    return pred
end

function crunchtest()
    myrun, blk, fit, channels, anchors = fractionationtest()
    pooled = pool(myrun,signal=true,group="Hogsbo")
    (x0,y0,y1) = anchors["Hogsbo"]
    pred = predict(pooled,fit,blk,channels,x0,y0,y1)
    misfit = @. pooled[:,channels["d"]] - pred[:,"d"]
    p = Plots.histogram(misfit,legend=false)
    @test display(p) != NaN
end

function sampletest()
    myrun, blk, fit, channels, anchors = fractionationtest()
    t, T, P, D, d = atomic(myrun[1],channels=channels,pars=fit,blank=blk)
    ratios = averat(myrun,channels=channels,pars=fit,blank=blk)
    return ratios
end

function processtest()
    myrun = load("data/Lu-Hf",instrument="Agilent")
    method = "Lu-Hf"
    channels = Dict("d"=>"Hf178 -> 260",
                    "D"=>"Hf176 -> 258",
                    "P"=>"Lu175 -> 175")
    standards = Dict("Hogsbo" => "hogsbo")
    cutoff = 1e7
    blk, anchors, fit = process!(myrun,method,channels,standards,
                                 nb=2,nf=1,nF=0,mf=1.4671,
                                 PAcutoff=cutoff,verbose=false)
    p = plot(myrun[2],channels,blk,fit,anchors,den="Hf176 -> 258",
             transformation="log")
    @test display(p) != NaN
end

function readmetest()
    myrun = load("data/Lu-Hf",instrument="Agilent")
    blk = fitBlanks(myrun,nb=2)
    standards = Dict("Hogsbo" => "hogsbo_ana")
    setStandards!(myrun,standards)
    anchors = getAnchor("Lu-Hf",standards)
    channels = Dict("d"=>"Hf178 -> 260",
                    "D"=>"Hf176 -> 258",
                    "P"=>"Lu175 -> 175")
    fit = fractionation(myrun,blank=blk,channels=channels,
                        anchors=anchors,nf=1,nF=0,mf=1.4671)
    ratios = averat(myrun,channels=channels,pars=fit,blank=blk)
    return ratios
end

function PAtest()
    all = load("data/Lu-Hf",instrument="Agilent")
    channels = Dict("d"=>"Hf178 -> 260",
                    "D"=>"Hf176 -> 258",
                    "P"=>"Lu175 -> 175")
    standards = Dict("Hogsbo" => "hogsbo")
    cutoff = 1e7
    blk, anchors, fit = process!(all,"Lu-Hf",channels,standards,
                                 nb=2,nf=1,nF=1,PAcutoff=cutoff)
    p = plot(all[1],channels,blk,fit,anchors,
              transformation="log")#,den="Hf176 -> 258")
    @test display(p) != NaN
end

function exporttest()
    ratios = readmetest()
    selection = subset(ratios,"BP") # "hogsbo"
    CSV.write("BP.csv",selection)
    export2IsoplotR("BP.json",selection,"Lu-Hf")
end

function RbSrtest()
    myrun = load("data/Rb-Sr",instrument="Agilent")
    standards = Dict("MDC" => "MDC -")
    channels = Dict("d"=>"Sr86 -> 102",
                    "D"=>"Sr87 -> 103",
                    "P"=>"Rb85 -> 85")
    blk, anchors, fit = process!(myrun,"Rb-Sr",channels,
                                 standards,nf=1,nF=1,mf=1.0)
    println(fit)
    ratios = averat(myrun,channels=channels,pars=fit,blank=blk)
    selection = subset(ratios,"Entire")
    export2IsoplotR("Entire.json",selection,"Rb-Sr")
    return ratios
end

function UPbtest()
    
    myrun = load("data/U-Pb",instrument="Agilent",head2name=false)
    standards = Dict("91500" => "91500")
    channels = Dict("d"=>"Pb207","D"=>"Pb206","P"=>"U238")
    
    blank, anchors, pars = process!(myrun,"U-Pb",channels,
                                    standards,nb=2,nf=1,nF=1,mf=1,
                                    verbose=true)

    samp = myrun[29]
    p = plot(samp,channels,blank,pars,anchors,transformation="log")
    
    @test display(p) != NaN
    
    ratios = averat(myrun,channels=channels,pars=pars,blank=blank)
    selection = subset(ratios,"91500")
    export2IsoplotR("91500.json",selection,"U-Pb")
    return ratios
    
end

function iCaptest(verbatim=true)
    myrun = load("data/iCap",instrument="ThermoFisher")
    if verbatim summarise(myrun) end
end

function carbonatetest(verbatim=true)
    myrun = load("data/carbonate",instrument="Agilent")
    standards = Dict("WC1"=>"WC1")
    channels = Dict("d"=>"Pb207","D"=>"Pb206","P"=>"U238")
    blk, anchors, fit = process!(myrun,"U-Pb",channels,
                                 standards,nb=2,nf=1,nF=1,mf=nothing,
                                 verbose=false)
    println(fit)
    ratios = averat(myrun,channels=channels,pars=fit,blank=blk)
    selection = subset(ratios,"MEX")
    export2IsoplotR("MEX.json",selection,"U-Pb")
    #p = plot(myrun[3],channels,blk,fit,anchors,
    #         transformation="",num=["Pb207"],den="Pb206",ylim=[-0.02,0.3])
    #@test display(p) != NaN
end

function mftest()
    all = load("data/carbonate",instrument="Agilent")
    standards = Dict("WC1" => "WC1")
    glass = Dict("NIST612" => "612")
    channels = Dict("d"=>"Pb207","D"=>"Pb206","P"=>"U238")
    blk = fitBlanks(all,nb=2)
    mf = glass2mf!(all,blank=blk,channels=channels,glass=glass)
end

function TUItest()
    PT("logs/test.log")
end

Plots.closeall()

#=@testset "load" begin loadtest(true) end
@testset "plot raw data" begin plottest() end
@testset "set selection window" begin windowtest() end
@testset "set method and blanks" begin blanktest() end
@testset "assign standards" begin standardtest(true) end
@testset "fit fractionation" begin fractionationtest() end
@testset "plot fit" begin predicttest() end
@testset "crunch" begin crunchtest() end
@testset "process sample" begin sampletest() end
@testset "process run" begin processtest() end
@testset "readme example" begin readmetest() end
@testset "PA test" begin PAtest() end
@testset "export" begin exporttest() end
@testset "Rb-Sr" begin RbSrtest() end
@testset "U-Pb" begin UPbtest() end
@testset "iCap test" begin iCaptest() end
@testset "carbonate test" begin carbonatetest() end=#
@testset "mass fractionation test" begin mftest() end
#=@testset "TUI test" begin TUItest() end=#
