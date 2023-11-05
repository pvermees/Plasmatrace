function check(priority,key)
    if priority[key] return "[*]" else return "" end
end

function check!(priority,key)
    priority[key] = false
    priority["load"] = priority["instrument"] || priority["read"]
    priority["bulk"] = priority["bwin"] || priority["swin"] || priority["prefixes"]
end

function unsupported(pd,pars,action)
    println("This feature is not available yet.")
    return nothing
end

function chooseMethod!(pd,pars,action)
    if action=="1"
        method = "LuHf"
    else
        return nothing
    end
    DRSmethod!(pd,method=method)
    check!(pars.prioritylist,"method")
    return "channels"
end

function selectChannels!(pd,pars,action)
    samples = getSamples(pd)
    selected = parse.(Int,split(action,","))
    labels = names(getDat(samples[1]))[3:end]
    pars.channels = labels[selected]
    pars.den = nothing
end

function chooseChannels!(pd,pars,action)
    selectChannels!(pd,pars,action)
    DRSchannels!(pd,channels=pars.channels)
    return "xx"
end

function viewChannels!(pd,pars,action)
    selectChannels!(pd,pars,action)
    viewer(pd=pd,pars=pars)
    return "x"
end

function string2windows(pd,pars,action;single=false)
    if single
        parts = split(action,',')
        stime = [parse(Float64,parts[1])]
        ftime = [parse(Float64,parts[2])]
        nw = 1
    else
        parts = split(action,['(',')',','])
        stime = parse.(Float64,parts[2:4:end])
        ftime = parse.(Float64,parts[3:4:end])
        nw = Int(round(size(parts,1)/4))
    end
    windows = Vector{window}(undef,nw)
    t = getDat(pd,i=pars.i)[:,2]
    nt = size(t,1)
    maxt = t[end]
    for i in 1:nw
        if stime[i]>t[end]
            stime[i] = t[end-1]
            println("Warning: start point out of bounds and truncated to ")
            print(string(stime[i]) * " seconds.")
        end
        if ftime[i]>t[end]
            ftime[i] = t[end]
            println("Warning: end point out of bounds and truncated to ")
            print(string(maxt) * " seconds.")
        end
        start = max(1,Int(round(nt*stime[i]/maxt)))
        finish = min(nt,Int(round(nt*ftime[i]/maxt)))
        windows[i] = (start,finish)
    end
    windows
end

function allAutoBlankWindows!(pd,pars,action)
    setBlanks!(pd)
    check!(pars.prioritylist,"bwin")
    return "x"
end
function allAutoSignalWindows!(pd,pars,action)
    setSignals!(pd)
    check!(pars.prioritylist,"swin")
    return "x"
end
function allSingleBlankWindows!(pd,pars,action)
    println("allSingleBlankWindows!")
    windows = string2windows(pd,pars,action;single=true)
    setBlanks!(pd,windows=windows)
    check!(pars.prioritylist,"bwin")
    return "xx"
end
function allSingleSignalWindows!(pd,pars,action)
    windows = string2windows(pd,pars,action;single=true)
    setSignals!(pd,windows=windows)
    check!(pars.prioritylist,"swin")
    return "xx"
end
function allMultiBlankWindows!(pd,pars,action)
    windows = string2windows(pd,pars,action)
    setBlanks!(pd,windows=windows)
    check!(pars.prioritylist,"bwin")
    return "xx"
end
function allMultiSignalWindows!(pd,pars,action)
    windows = string2windows(pd,pars,action)
    setSignals!(pd,windows=windows)
    check!(pars.prioritylist,"swin")
    return "xx"
end

function loadInstrument!(pd,pars,action)
    if action=="1" instrument = "Agilent"
    else return nothing end
    check!(pars.prioritylist,"instrument")
    setInstrument!(pd,instrument)
    return "x"
end

function loader!(pd,pars,action)
    load!(pd,dname=action)
    check!(pars.prioritylist,"read")
    return "x"
end

function listSamples(pd,pars,action)
    snames = getSnames(pd)
    for sname in snames
        println(sname)
    end
    return nothing
end

function viewer(;pd,pars)
    samp = getSamples(pd)[pars.i]
    p = plot(samp,channels=pars.channels,den=pars.den)
    display(p)
end

function viewnext!(pd,pars,action)
    pars.i = pars.i<length(pd) ? pars.i+1 : 1
    viewer(pd=pd,pars=pars)
    return nothing
end

function viewprevious!(pd,pars,action)
    pars.i = pars.i>1 ? pars.i-1 : length(pd)
    viewer(pd=pd,pars=pars)
    return nothing
end

function setDen!(pd,pars,action)
    pars.den = action=="r" ? nothing : [pars.channels[parse(Int,action)]]
    viewer(pd=pd,pars=pars)
    return "x"
end

function setStandardPrefixes!(pd,pars,action)
    prefixes = string.(split(action,","))
    markStandards!(pd,standard=0) # reset
    for i in eachindex(prefixes)
        markStandards!(pd,prefix=prefixes[i],standard=i)
    end
    check!(pars.prioritylist,"prefixes")
    return "refmat"
end


function chooseRefMat!(pd,pars,action)
    method = getMethod(pd)
    refmats = collect(keys(referenceMaterials[method]))
    i = parse.(Int,split(action,","))
    pars.refmats = refmats[i]
    return "xxx"
end

function process!(pd,pars,action)
    println("Fitting blanks...")
    fitBlanks!(pd,n=pars.n[1])
    println("Fitting standards...")
    fitStandards!(pd,refmat=pars.refmats,n=pars.n[2])
    return nothing
end

function setSamplePrefixes!(pd,pars,action)
    pars.prefixes = string.(split(action,','))
    return "export"
end
function clearSamplePrefixes!(pd,pars,action)
    pars.prefixes = nothing
    return "export"
end

function export2csv(pd,pars,action)
    i = findSamples(pd,prefix=pars.prefixes)
    out = fitSamples(pd,i=i)
    CSV.write(action,out)
    if isnothing(pars.prefixes) return "xx"
    else return "xxxx" end
end

function savelog!(pd,pars,action)
    println("Enter the path and name of the log file:")
    fpath = readline()
    pars.history = delete!(pars.history,nrow(pars.history))
    CSV.write(fpath,pars.history)
    return "x"
end

function restorelog!(pd,pars,action)
    println("Provide the path of the log file:")
    fpath = readline()
    hist = CSV.read(fpath,DataFrame)
    empty!(pars.history)
    append!(pars.history,hist)
    return "restorelog"
end
