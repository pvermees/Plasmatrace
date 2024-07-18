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
    blk = fitBlanks(myrun,nblank=2)
    return myrun, blk
end

function standardtest(verbatim=false)
    myrun, blk = blanktest()
    standards = Dict("BP" => "BP")
    setGroup!(myrun,standards)
    anchors = getAnchors("Lu-Hf",standards)
    if verbatim
        summarise(myrun)
    end
end

function predicttest()
    myrun, blk = blanktest()
    channels = Dict("d" => "Hf178 -> 260",
                    "D" => "Hf176 -> 258",
                    "P" => "Lu175 -> 175")
    glass = Dict("NIST612" => "NIST612p")
    setGroup!(myrun,glass)
    standards = Dict("BP" => "BP")
    setGroup!(myrun,standards)
    fit = Pars([4.2670587703673934], [0.0, 0.05197296298083967], 0.3838697441780825)
    Sanchors = getAnchors("Lu-Hf",standards,false)
    Ganchors = getAnchors("Lu-Hf",glass,true)
    anchors = merge(Sanchors,Ganchors)
    samp = myrun[4]
    if samp.group == "sample"
        println("Not a standard")
    else
        pred = predict(samp,fit,blk,channels,anchors)
        p = plot(samp,channels,blk,fit,anchors,transformation="log")
        @test display(p) != NaN
    end
    return pred
end

function fractionationtest()
    myrun, blk = blanktest()
    channels = Dict("d" => "Hf178 -> 260",
                    "D" => "Hf176 -> 258",
                    "P" => "Lu175 -> 175")
    glass = Dict("NIST612" => "NIST612p")
    setGroup!(myrun,glass)
    standards = Dict("BP" => "BP")
    setGroup!(myrun,standards)
    print("two separate steps: ")
    mf = fractionation(myrun,"Lu-Hf",blk,channels,glass)
    fit = fractionation(myrun,"Lu-Hf",blk,channels,standards,mf,ndrift=1,ndown=1)
    println(fit)
    print("no glass: ")
    fit = fractionation(myrun,"Lu-Hf",blk,channels,standards,nothing,ndrift=1,ndown=1)
    println(fit)
    print("two joint steps: ")
    fit = fractionation(myrun,"Lu-Hf",blk,channels,standards,glass,ndrift=1,ndown=1)
    println(fit)
    return myrun, blk, fit, channels, standards, glass
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
                                 nb=2,nf=2,nF=2,mf=1.4671,
                                 PAcutoff=cutoff,verbose=true)
    p = plot(myrun[2],channels,blk,fit,anchors,den="Hf176 -> 258",
             transformation="log")
    @test display(p) != NaN
end

function readmetest()
    myrun = load("data/Lu-Hf",instrument="Agilent")
    blk = fitBlanks(myrun,nb=2)
    standards = Dict("Hogsbo" => "hogsbo_ana")
    glass = Dict("NIST612" => "NIST612p")
    setGroup!(myrun,standards)
    setGroup!(myrun,glass)
    anchors = getAnchor("Lu-Hf",standards,glass)
    channels = Dict("d"=>"Hf178 -> 260",
                    "D"=>"Hf176 -> 258",
                    "P"=>"Lu175 -> 175")
    fit = fractionation(myrun,blank=blk,channels=channels,
                        anchors=anchors,nf=1,nF=0,mf=nothing,verbose=true)
    ratios = averat(myrun,channels=channels,pars=fit,blank=blk)
    return ratios
end

function PAtest()
    all = load("data/Lu-Hf",instrument="Agilent")
    channels = Dict("d"=>"Hf178 -> 260",
                    "D"=>"Hf176 -> 258",
                    "P"=>"Lu175 -> 175")
    standards = Dict("Hogsbo" => "hogsbo",
                     "NIST612" => "NIST612")
    cutoff = 1e7
    blk, anchors, fit = process!(all,"Lu-Hf",channels,standards,
                                 nb=2,nf=1,nF=1,mf=nothing,
                                 PAcutoff=cutoff)
    print(fit)
    p = plot(all[2],channels,blk,fit,anchors,
              transformation="log",den="Hf176 -> 258")
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
                                 standards,nf=1,nF=2,mf=1.0)
    p = plot(myrun[2],channels,blk,fit,anchors,
             transformation="log",den="Sr86 -> 102")
    @test display(p) != NaN
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
                                    standards,nb=2,nf=1,nF=2,mf=1,
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
                                 standards,nb=2,nf=2,nF=2,mf=1.0,
                                 verbose=false)
    p = plot(myrun[3],channels,blk,fit,anchors,
             transformation="",num=["Pb207"],den="Pb206",ylim=[-0.02,0.3])
    @test display(p) != NaN
end

function mftest()
    myrun = load("data/carbonate",instrument="Agilent")
    channels = Dict("d" => "Pb207",
                    "D" => "Pb206",
                    "P" => "U238")
    standards = Dict("WC1" => "WC1",
                     "NIST612" => "NIST612")
    blank, anchors, pars = process!(myrun,"U-Pb",channels,
                                    standards,nb=2,nf=1,nF=1,mf=nothing)
    println(pars)
    ratios = averat(myrun,channels=channels,pars=pars,blank=blank)
    selection = subset(ratios,"WC1")
    export2IsoplotR("WC1.json",selection,"U-Pb")
end

function TUItest()
    PT("logs/emacs.log")
end

Plots.closeall()

#=@testset "load" begin loadtest(true) end
@testset "plot raw data" begin plottest() end
@testset "set selection window" begin windowtest() end
@testset "set method and blanks" begin blanktest() end
@testset "assign standards" begin standardtest(true) end=#
@testset "plot fit" begin predicttest() end
#=@testset "fit fractionation" begin fractionationtest() end
@testset "crunch" begin crunchtest() end
@testset "process sample" begin sampletest() end
@testset "process run" begin processtest() end
@testset "readme example" begin readmetest() end
@testset "PA test" begin PAtest() end
@testset "export" begin exporttest() end
@testset "Rb-Sr" begin RbSrtest() end
@testset "U-Pb" begin UPbtest() end
@testset "iCap test" begin iCaptest() end
@testset "carbonate test" begin carbonatetest() end
@testset "mass fractionation test" begin mftest() end
@testset "TUI test" begin TUItest() end=#
