function TUIwelcome()
    version = string(pkgversion(@__MODULE__))
    title = " Plasmatrace "*version*" \n"
    width = Base.length(title)-1
    println('-'^width*"\n"*title*'-'^width)
end

function TUIcheck(ctrl::AbstractDict,action::AbstractString)
    return ctrl["priority"][action] ? "[*]" : ""
end

function TUIread(ctrl::AbstractDict)
    if ctrl["template"]
        if ctrl["multifile"]
            push!(ctrl["chain"],"loadICPdir")
        else
            push!(ctrl["chain"],"loadICPfile")
        end
    else
        push!(ctrl["chain"],"instrument")
    end
end

function TUIinstrument!(ctrl::AbstractDict,
                        response::AbstractString)
    if response=="a"
        ctrl["instrument"] = "Agilent"
    elseif response=="t"
        ctrl["instrument"] = "ThermoFisher"
    else
        @warn "Unsupported instrument"
        return "x"
    end
    return "dir|file"
end

function TUIloadICPdir!(ctrl::AbstractDict,response::AbstractString)
    ctrl["run"] = load(response;
                       instrument=ctrl["instrument"],
                       head2name=ctrl["head2name"])
    ctrl["priority"]["load"] = false
    ctrl["multifile"] = true
    ctrl["dname"] = response
    if ctrl["template"]
        return "x"
    else
        return "xxx"
    end
end

function TUIloadICPfile!(ctrl::AbstractDict,response::AbstractString)
    ctrl["dname"] = response
    return "loadLAfile"
end

function TUIloadLAfile!(ctrl::AbstractDict,response::AbstractString)
    ctrl["run"] = load(ctrl["dname"],response;
                       instrument=ctrl["instrument"])
    ctrl["priority"]["load"] = false
    ctrl["head2name"] = true
    ctrl["multifile"] = false
    if ctrl["template"]
        return "xx"
    else
        return "xxxx"
    end
end

function TUImethod!(ctrl::AbstractDict,response::AbstractString)
    methods = _PT["methods"].method
    i = parse(Int,response)
    if i > length(methods)
        return "x"
    else
        ctrl["method"] = methods[i]
    end
    return "columns"
end

function TUItabulate(ctrl::AbstractDict)
    summarise(ctrl["run"])
end

function TUIcolumns!(ctrl::AbstractDict,response::AbstractString)
    labels = names(getDat(ctrl["run"][1]))
    selected = parse.(Int,split(response,","))
    PDd = labels[selected]
    ctrl["channels"] = Dict("d" => PDd[3], "D" => PDd[2], "P" => PDd[1])
    ctrl["priority"]["method"] = false
    return "xx"
end

function TUIchooseStandard!(ctrl::AbstractDict,
                            response::AbstractString)
    i = parse(Int,response)
    standards = collect(keys(_PT["refmat"][ctrl["method"]]))
    ctrl["cache"] = standards[i]
    if !(standards[i] in ctrl["standards"])
        push!(ctrl["standards"],standards[i])
    end
    return "addStandardGroup"
end

function TUIaddStandardsByPrefix!(ctrl::AbstractDict,
                                  response::AbstractString)
    setGroup!(ctrl["run"],response,ctrl["cache"])
    ctrl["priority"]["standards"] = false
    return "xxx"
end

function TUIaddStandardsByNumber!(ctrl::AbstractDict,
                                  response::AbstractString)
    selection = parse.(Int,split(response,","))
    setGroup!(ctrl["run"],selection,ctrl["cache"])
    ctrl["priority"]["standards"] = false
    return "xxx"
end

function TUIremoveAllStandards!(ctrl::AbstractDict)
    setGroup!(ctrl["run"],"sample")
    ctrl["standards"] = AbstractString[]
    ctrl["priority"]["standards"] = true
    return "xx"
end

function TUIremoveStandardsByNumber!(ctrl::AbstractDict,
                                     response::AbstractString)
    selection = parse.(Int,split(response,","))
    setGroup!(ctrl["run"],selection,"sample")
    groups = unique(getGroups(ctrl["run"]))
    keep = (in).(ctrl["standards"],Ref(groups))
    ctrl["standards"] = ctrl["standards"][keep]
    ctrl["priority"]["standards"] = length(ctrl["standards"])<1
    return "xxx"
end

function TUIrefmatTab(ctrl::AbstractDict)
    for (key, value) in _PT["refmat"][ctrl["method"]]
        print(key)
        print(": ")
        if !ismissing(value.t[1])
            print("t=")
            print(value.t[1])
            print("Ma, ")
        end
        print("y0=")
        print(value.y0[1])
        print("\n")
    end
    return "x"
end

function TUIchooseGlass!(ctrl::AbstractDict,
                         response::AbstractString)
    i = parse(Int,response)
    glass = collect(keys(_PT["glass"]))
    ctrl["cache"] = glass[i]
    if !(glass[i] in ctrl["glass"])
        push!(ctrl["glass"],glass[i])
    end
    return "addGlassGroup"
end

function TUIaddGlassByPrefix!(ctrl::AbstractDict,
                              response::AbstractString)
    setGroup!(ctrl["run"],response,ctrl["cache"])
    ctrl["priority"]["glass"] = false
    return "xxx"
end

function TUIaddGlassByNumber!(ctrl::AbstractDict,
                              response::AbstractString)
    selection = parse.(Int,split(response,","))
    setGroup!(ctrl["run"],selection,ctrl["cache"])
    ctrl["priority"]["glass"] = false
    return "xxx"
end

function TUIremoveAllGlass!(ctrl::AbstractDict)
    setGroup!(ctrl["run"],"sample")
    ctrl["glass"] = Dict()
    ctrl["priority"]["glass"] = true
    return "xx"
end

function TUIremoveGlassByNumber!(ctrl::AbstractDict,
                                 response::AbstractString)
    selection = parse.(Int,split(response,","))
    setGroup!(ctrl["run"],selection,"sample")
    groups = unique(getGroups(ctrl["run"]))
    keep = (in).(ctrl["glass"],Ref(groups))
    ctrl["glass"] = ctrl["glass"][keep]
    ctrl["priority"]["glass"] = length(ctrl["glass"])<1
    return "xxx"
end

function TUIglassTab(ctrl::AbstractDict)
    for (key, value) in _PT["glass"]
        println(key)
    end
    return "x"
end

function TUIviewer!(ctrl::AbstractDict)
    TUIplotter(ctrl)
    push!(ctrl["chain"],"view")
end

function TUIplotter(ctrl::AbstractDict)
    samp = ctrl["run"][ctrl["i"]]
    if haskey(ctrl,"channels")
        channels = ctrl["channels"]
    else
        channels = names(samp.dat)[3:end]
    end
    if isnothing(ctrl["blank"]) | (samp.group=="sample")
        p = plot(samp,channels,den=ctrl["den"],transformation=ctrl["transformation"])
    else
        if isnothing(ctrl["PAcutoff"])
            par = ctrl["par"]
        else
            analog = isAnalog(samp,ctrl["channels"],ctrl["PAcutoff"])
            par = analog ? ctrl["par"].analog : ctrl["par"].pulse
        end
        anchors = getAnchors(ctrl["run"],ctrl["standards"],ctrl["glass"])
        p = plot(samp,channels,ctrl["blank"],par,ctrl["standards"],ctrl["glass"],
                 den=ctrl["den"],transformation=ctrl["transformation"])
    end
    if !isnothing(ctrl["PAcutoff"])
        TUIaddPAline!(p,ctrl["PAcutoff"])
    end
    display(p)
end

function TUIaddPAline!(p,cutoff::AbstractFloat)
    ylim = Plots.ylims(p)
    if  sqrt(cutoff) < 1.1*ylim[2]
        Plots.plot!(p,collect(Plots.xlims(p)),
                    fill(sqrt(cutoff),2),
                    seriestype=:line,label="",
                    linewidth=2,linestyle=:dash)
    end
end

function TUInext!(ctrl::AbstractDict)
    ctrl["i"] += 1
    if ctrl["i"]>length(ctrl["run"]) ctrl["i"] = 1 end
    TUIplotter(ctrl)
end

function TUIprevious!(ctrl::AbstractDict)
    ctrl["i"] -= 1
    if ctrl["i"]<1 ctrl["i"] = length(ctrl["run"]) end
    TUIplotter(ctrl)
end

function TUIgoto!(ctrl::AbstractDict,response::AbstractString)
    ctrl["i"] = parse(Int,response)
    if ctrl["i"]>length(ctrl["run"]) ctrl["i"] = 1 end
    if ctrl["i"]<1 ctrl["i"] = length(ctrl["run"]) end
    TUIplotter(ctrl)
    return "x"
end

function TUIratios!(ctrl::AbstractDict,response::AbstractString)
    if response=="n"
        ctrl["den"] = nothing
    elseif response=="x"
        return "xx"
    else
        i = parse(Int,response)
        if haskey(ctrl,"channels")
            channels = collect(values(ctrl["channels"]))
        else
            channels = names(ctrl["run"][1].dat)[3:end]
        end
        ctrl["den"] = channels[i]
    end
    TUIplotter(ctrl)
    return "x"
end

function TUIoneAutoBlankWindow!(ctrl::AbstractDict)
    setBwin!(ctrl["run"][ctrl["i"]])
    TUIplotter(ctrl)
end

function TUIoneSingleBlankWindow!(ctrl::AbstractDict,
                                  response::AbstractString)
    samp = ctrl["run"][ctrl["i"]]
    bwin = string2windows(samp,response,true)
    setBwin!(samp,bwin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIoneMultiBlankWindow!(ctrl::AbstractDict,
                                 response::AbstractString)
    samp = ctrl["run"][ctrl["i"]]
    bwin = string2windows(samp,response,false)
    setBwin!(samp,bwin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIallAutoBlankWindow!(ctrl::AbstractDict)
    setBwin!(ctrl["run"])
    TUIplotter(ctrl)
end

function TUIallSingleBlankWindow!(ctrl::AbstractDict,
                                  response::AbstractString)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        bwin = string2windows(samp,response,true)
        setBwin!(samp,bwin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUIallMultiBlankWindow!(ctrl::AbstractDict,
                                 response::AbstractString)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        bwin = string2windows(samp,response,false)
        setBwin!(samp,bwin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUIoneAutoSignalWindow!(ctrl::AbstractDict)
    setSwin!(ctrl["run"][ctrl["i"]])
    TUIplotter(ctrl)
end

function TUIoneSingleSignalWindow!(ctrl::AbstractDict,
                                   response::AbstractString)
    samp = ctrl["run"][ctrl["i"]]
    swin = string2windows(samp,response,true)
    setSwin!(samp,swin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIoneMultiSignalWindow!(ctrl::AbstractDict,
                                  response::AbstractString)
    samp = ctrl["run"][ctrl["i"]]
    swin = string2windows(samp,response,false)
    setSwin!(samp,swin)
    TUIplotter(ctrl)
    return "x"
end

function TUIallAutoSignalWindow!(ctrl::AbstractDict)
    setSwin!(ctrl["run"])
    TUIplotter(ctrl)
end

function TUIallSingleSignalWindow!(ctrl::AbstractDict,
                                   response::AbstractString)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        swin = string2windows(samp,response,true)
        setSwin!(samp,swin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUIallMultiSignalWindow!(ctrl::AbstractDict,
                                  response::AbstractString)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        swin = string2windows(samp,response,false)
        setSwin!(samp,swin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUItransformation!(ctrl::AbstractDict,
                            response::AbstractString)
    if response=="L"
        ctrl["transformation"] = "log"
    elseif response=="s"
        ctrl["transformation"] = "sqrt"
    else
        ctrl["transformation"] = ""
    end
    TUIplotter(ctrl)
    return "x"
end

function TUIprocess!(ctrl::AbstractDict)
    ctrl["anchors"] = getAnchors(ctrl["method"],ctrl["standards"],ctrl["glass"])
    println("Fitting blanks...")
    ctrl["blank"] = fitBlanks(ctrl["run"],nblank=ctrl["options"]["blank"])
    println("Fractionation correction...")
    ctrl["par"] = fractionation(ctrl["run"],
                                ctrl["method"],
                                ctrl["blank"],
                                ctrl["channels"],
                                ctrl["standards"],
                                ctrl["glass"];
                                ndrift=ctrl["options"]["drift"],
                                ndown=ctrl["options"]["down"],
                                PAcutoff=ctrl["PAcutoff"])
    ctrl["priority"]["process"] = false
    println("Done")
end

function TUIsubset!(ctrl::AbstractDict,response::AbstractString)
    if response=="a"
        ctrl["cache"] = 1:length(ctrl["run"])
    elseif response=="s"
        ctrl["cache"] = findall(contains("sample"),getGroups(ctrl["run"]))
    elseif response=="x"
        return "x"
    else
        ctrl["cache"] = findall(contains(response),getSnames(ctrl["run"]))
    end
    return "format"
end

function TUIexport2csv(ctrl::AbstractDict,response::AbstractString)
    ratios = averat(ctrl["run"],ctrl["channels"],ctrl["par"],ctrl["blank"];
                    PAcutoff=ctrl["PAcutoff"])
    fname = splitext(response)[1]*".csv"
    CSV.write(fname,ratios[ctrl["cache"],:])
    return "xxx"
end

function TUIexport2json(ctrl::AbstractDict,response::AbstractString)
    ratios = averat(ctrl["run"],ctrl["channels"],ctrl["par"],ctrl["blank"];
                    PAcutoff=ctrl["PAcutoff"])
    fname = splitext(response)[1]*".json"
    export2IsoplotR(ratios[ctrl["cache"],:],ctrl["method"];fname=fname)
    return "xxx"
end

function TUIimportLog!(ctrl::AbstractDict,response::AbstractString)
    history = CSV.read(response,DataFrame)
    ctrl["history"] = DataFrame(task=String[],action=String[])
    for row in eachrow(history)
        try
            dispatch!(ctrl,key=row[1],response=row[2])
        catch e
            println(e)
        end
    end
    return "xx"
end

function TUIexportLog(ctrl::AbstractDict,response::AbstractString)
    pop!(ctrl["history"])
    pop!(ctrl["history"])
    CSV.write(response,ctrl["history"])
    return "xx"
end

function TUIopenTemplate!(ctrl::AbstractDict,response::AbstractString)
    include(response)
    ctrl["instrument"] = instrument
    ctrl["head2name"] = head2name
    ctrl["multifile"] = multifile
    ctrl["channels"] = channels
    ctrl["options"] = options
    ctrl["PAcutoff"] = PAcutoff
    ctrl["transformation"] = transformation
    ctrl["priority"]["method"] = false
    ctrl["template"] = true
    return "xx"
end

function TUIsaveTemplate(ctrl::AbstractDict,response::AbstractString)
    PAcutoff = isnothing(ctrl["PAcutoff"]) ? "nothing" : string(ctrl["PAcutoff"])
    open(response, "w") do file
        write(file,"instrument = \"" * ctrl["instrument"] * "\"\n")
        write(file,"multifile = " * string(ctrl["multifile"]) * "\n")
        write(file,"head2name = " * string(ctrl["head2name"]) * "\n")
        write(file,"channels = " * dict2string(ctrl["channels"]) * "\n")
        write(file,"options = " * dict2string(ctrl["options"]) * "\n")
        write(file,"PAcutoff = " * PAcutoff * "\n")
        write(file,"transformation = \"" * ctrl["transformation"] * "\"\n")
    end
    return "xx"
end

function TUIsetNblank!(ctrl::AbstractDict,response::AbstractString)
    ctrl["options"]["blank"] = parse(Int,response)
    return "x"
end

function TUIsetNdrift!(ctrl::AbstractDict,response::AbstractString)
    ctrl["options"]["drift"] = parse(Int,response)
    return "x"    
end

function TUIsetNdown!(ctrl::AbstractDict,response::AbstractString)
    ctrl["options"]["down"] = parse(Int,response)
    return "x"    
end

function TUIPAlist(ctrl::AbstractDict)
    snames = getSnames(ctrl["run"])
    for i in eachindex(snames)
        dat = getDat(ctrl["run"][i],ctrl["channels"])
        maxval = maximum(Matrix(dat))
        formatted = @sprintf("%.*e", 3, maxval)
        println(formatted*" ("*snames[i]*")")
    end
    return "x"
end

function TUIsetPAcutoff!(ctrl::AbstractDict,response::AbstractString)
    cutoff = tryparse(Float64,response)
    ctrl["PAcutoff"] = cutoff
    return "xx"
end

function TUIclearPAcutoff!(ctrl::AbstractDict)
    ctrl["PAcutoff"] = nothing
    return "xx"
end

function TUIaddStandard!(ctrl::AbstractDict,response::AbstractString)
    setReferenceMaterials!(response)
    return "x"
end

function TUIaddGlass!(ctrl::AbstractDict,response::AbstractString)
    setGlass!(response)
    return "x"
end

function TUIhead2name!(ctrl::AbstractDict,response::AbstractString)
    ctrl["head2name"] = response=="h"
    return "x"
end

function TUIrefresh!(ctrl::AbstractDict)
    TUIload!(ctrl,ctrl["dname"])
    snames = getSnames(ctrl["run"])
    for (refmat,prefix) in ctrl["standards"]
        setGroup!(ctrl["run"],prefix,refmat)
    end
    for (refmat,prefix) in ctrl["glasss"]
        setGroup!(ctrl["run"],prefix,refmat)
    end
    TUIprocess!(ctrl)
    return nothing
end
