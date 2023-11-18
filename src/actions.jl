function check(priority,key)
    if priority[key] return "[*]" else return "" end
end

function check!(priority,key)
    priority[key] = false
    priority["load"] = priority["instrument"] || priority["read"]
    priority["bulk"] = priority["bwin"] || priority["swin"] || priority["prefixes"]
end

function unsupported(pd,pars,action)
    if action=="x" return "x" end
    println("This feature is not available yet.")
    return nothing
end

function chooseMethod!(pd,pars,action)
    if action=="1"
        method = "LuHf"
    elseif action=="x"
        return action
    else
        return nothing
    end
    DRSmethod!(pd,method=method)
    check!(pars.prioritylist,"method")
    return "channels"
end

function selectChannels!(pd,pars,action)
    if action=="x" return "x" end
    samples = getSamples(pd)
    selected = parse.(Int,split(action,","))
    labels = names(getDat(samples[1]))[3:end]
    pars.channels = labels[selected]
    pars.den = nothing
end

function chooseChannels!(pd,pars,action)
    if action=="x" return "x" end
    selectChannels!(pd,pars,action)
    DRSchannels!(pd,channels=pars.channels)
    return "xx"
end

function viewChannels!(pd,pars,action)
    if action=="x" return "x" end
    selectChannels!(pd,pars,action)
    viewer(pd=pd,pars=pars)
    return "x"
end

function string2windows(pd,pars,action;single=false)
    if action=="x" return "x" end
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
            print("Warning: start point out of bounds and truncated to ")
            print(string(stime[i]) * " seconds.")
        end
        if ftime[i]>t[end]
            ftime[i] = t[end]
            print("Warning: end point out of bounds and truncated to ")
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
function oneAutoBlankWindow!(pd,pars,action)
    setBlanks!(pd,i=pars.i)
    viewer(pd=pd,pars=pars)
    return "x"
end
function allAutoSignalWindows!(pd,pars,action)
    setSignals!(pd)
    check!(pars.prioritylist,"swin")
    return "x"
end
function oneAutoSignalWindow!(pd,pars,action)
    setSignals!(pd,i=pars.i)
    viewer(pd=pd,pars=pars)
    return "x"
end
function allSingleBlankWindows!(pd,pars,action)
    if action=="x" return "x" end
    windows = string2windows(pd,pars,action;single=true)
    setBlanks!(pd,windows=windows)
    check!(pars.prioritylist,"bwin")
    return "xx"
end
function oneSingleBlankWindow!(pd,pars,action)
    if action=="x" return "x" end
    windows = string2windows(pd,pars,action;single=true)
    setBlanks!(pd,windows=windows,i=pars.i)
    viewer(pd=pd,pars=pars)
    return "xx"
end
function allSingleSignalWindows!(pd,pars,action)
    if action=="x" return "x" end
    windows = string2windows(pd,pars,action;single=true)
    setSignals!(pd,windows=windows)
    check!(pars.prioritylist,"swin")
    return "xx"
end
function oneSingleSignalWindow!(pd,pars,action)
    if action=="x" return "x" end
    windows = string2windows(pd,pars,action;single=true)
    setSignals!(pd,windows=windows,i=pars.i)
    viewer(pd=pd,pars=pars)
    return "xx"
end
function allMultiBlankWindows!(pd,pars,action)
    if action=="x" return "x" end
    windows = string2windows(pd,pars,action)
    setBlanks!(pd,windows=windows)
    check!(pars.prioritylist,"bwin")
    return "xx"
end
function oneMultiBlankWindow!(pd,pars,action)
    if action=="x" return "x" end
    windows = string2windows(pd,pars,action)
    setBlanks!(pd,windows=windows,i=pars.i)
    viewer(pd=pd,pars=pars)
    return "xx"
end
function allMultiSignalWindows!(pd,pars,action)
    if action=="x" return "x" end
    windows = string2windows(pd,pars,action)
    setSignals!(pd,windows=windows)
    check!(pars.prioritylist,"swin")
    return "xx"
end
function oneMultiSignalWindow!(pd,pars,action)
    if action=="x" return "x" end
    windows = string2windows(pd,pars,action)
    setSignals!(pd,windows=windows,i=pars.i)
    viewer(pd=pd,pars=pars)
    return "xx"
end

function loadInstrument!(pd,pars,action)
    if action=="1" instrument = "Agilent"
    elseif action=="x" return "x" 
    else return nothing end
    check!(pars.prioritylist,"instrument")
    setInstrument!(pd,instrument)
    return "x"
end

function loader!(pd,pars,action)
    if action=="x" return "x" end
    load!(pd,dname=action)
    check!(pars.prioritylist,"read")
    return "x"
end

function listSamples(pd,pars,action)
    samples = getSamples(pd)
    standards = getStandard(pd)
    nstand = size(unique(standards),1)-1
    for i in eachindex(samples)
        str = string(i)*". "*getSname(samples[i])
        std = standards[i]
        if std>0
            str *= " [standard"
            str *= nstand>1 ? " "*string(std)*"]" : "]"
        end
        println(str)
    end
    return nothing
end

function goto!(pd,pars,action)
    if action=="x" return "x" end
    samples = getSamples(pd)
    pars.i = parse(Int,action)
    viewer(pd=pd,pars=pars)
    return "x"
end

function viewer(;pd,pars)
    p = plot(pd,i=pars.i,channels=pars.channels,den=pars.den)
    display(p)
end

function initialView(pd,pars,action)
    if !isnothing(getSamples(pd))
        viewer(pd=pd,pars=pars)
    end
    return "view"
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
    if action=="x" return "x" end
    pars.den = action=="r" ? nothing : [pars.channels[parse(Int,action)]]
    viewer(pd=pd,pars=pars)
    return "x"
end

function setStandardPrefixes!(pd,pars,action)
    if action=="x" return "x" end
    prefixes = string.(split(action,","))
    markStandards!(pd,standard=0)
    for i in eachindex(prefixes)
        markStandards!(pd,prefix=prefixes[i],standard=i)
    end
    check!(pars.prioritylist,"prefixes")
    return "refmat"
end

function setNblank!(pd,pars,action)
    if action=="x" return "x" end
    pars.n[1] = parse(Int,action)
    return "x"
end
function setNdrift!(pd,pars,action)
    if action=="x" return "x" end
    pars.n[2] = parse(Int,action)
    return "x"
end
function setNdown!(pd,pars,action)
    if action=="x" return "x" end
    pars.n[3] = parse(Int,action)
    return "x"
end

function listStandards(pd,pars,action)
    standards = getStandard(pd)
    nstand = size(unique(standards),1)-1
    samples = getSamples(pd)
    for i in eachindex(samples)
        if standards[i]>0
            sample = samples[i]
            message = string(i)*". "*getSname(sample)
            if nstand>1 message*=" [standard "*string(standards[i])*"]" end
            println(message)
        end
    end
    return nothing
end

function removeStandards!(pd,pars,action)
    if action=="x" return "x" end
    i = parse.(Int,split(action,","))
    setStandard!(pd,i=i,standard=0)
    return nothing
end

function chooseRefMat!(pd,pars,action)
    if action=="x" return "x" end
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
    fitStandards!(pd,refmat=pars.refmats,n=pars.n[2],m=pars.n[3])
    check!(pars.prioritylist,"process")
    return nothing
end

function setSamplePrefixes!(pd,pars,action)
    if action=="x" return "x" end
    pars.prefixes = string.(split(action,','))
    return "export"
end
function clearSamplePrefixes!(pd,pars,action)
    pars.prefixes = nothing
    return "export"
end

function export2csv(pd,pars,action)
    if action=="x" return "x" end
    i = findSamples(pd,prefix=pars.prefixes)
    out = fitSamples(pd,i=i,snames=true)
    CSV.write(action,out)
    return "xxx"
end

function savelog!(pd,pars,action)
    if action=="x" return "x" end
    println("Enter the path and name of the log file:")
    fpath = readline()
    pars.history = delete!(pars.history,nrow(pars.history))
    CSV.write(fpath,pars.history)
    return "x"
end

function restorelog!(pd,pars,action)
    if action=="x" return "x" end
    println("Provide the path of the log file:")
    fpath = readline()
    hist = CSV.read(fpath,DataFrame)
    empty!(pars.history)
    append!(pars.history,hist)
    return "restorelog"
end
