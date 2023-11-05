function unsupported(pd,pars,action)
    println("This feature is not available yet.")
    return nothing
end,

function chooseMethod!(pd,pars,action)
    if action=="1"
        method = "LuHf"
    else
        return nothing
    end
    DRSmethod!(pd,method=method)
    return "channels"
end

function channelMessage(pd,pars)
    isotopes = getIsotopes(pd)
    samples = getSamples(pd)
    if isnothing(isotopes)
        println("Choose a geochronometer first.")
    elseif isnothing(samples)
        println("Load the data first.")
    else
        println("Choose from the following list of channels:\n")
        labels = names(getDat(samples[1]))[3:end]
        for i in eachindex(labels)
            println(string(i)*". "*labels[i])
        end
    end
end

function chooseChannelMessage(pd,pars)
    isotopes = getIsotopes(pd)
    channelMessage(pd,pars)
    println("\nand select the channels corresponding to " *
            "the following isotopes or their proxies: ")
    println(join(isotopes,","))
    println("Specify your selection as a comma-separated list of numbers:")
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

function viewChannelMessage(pd,pars)
    channelMessage(pd,pars)
    println("\nSpecify your selection as a comma-separated list of numbers:")
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
    return "x"
end
function allAutoSignalWindows!(pd,pars,action)
    setSignals!(pd)
    return "x"
end
function allSingleBlankWindows!(pd,pars,action)
    println("allSingleBlankWindows!")
    windows = string2windows(pd,pars,action;single=true)
    setBlanks!(pd,windows=windows)
    return "xx"
end
function allSingleSignalWindows!(pd,pars,action)
    windows = string2windows(pd,pars,action;single=true)
    setSignals!(pd,windows=windows)
    return "xx"
end
function allMultiBlankWindows!(pd,pars,action)
    windows = string2windows(pd,pars,action)
    setBlanks!(pd,windows=windows)
    return "xx"
end
function allMultiSignalWindows!(pd,pars,action)
    windows = string2windows(pd,pars,action)
    setSignals!(pd,windows=windows)
    return "xx"
end

function load_i!(pd,pars,action)
    if action=="1" instrument = "Agilent"
    else return nothing end
    setInstrument!(pd,instrument)
    return "x"
end

function loader!(pd,pars,action)
    load!(pd,dname=action)
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

function setDenMessage(pd,pars)
    println("Choose one of the following denominators:")
    for i in eachindex(pars.channels)
        println(string(i)*". "*pars.channels[i])
    end
    println("or")
    println("r. No denominator. Plot the raw signals")
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
    return "refmat"
end

function chooseRefMatMessage(pd,pars)
    nst = size(unique(getStandard(pd)),1)
    if nst>2
        println("Now match this/these prefix(es) with "*
                "the following reference materials:")
    else
        println("Now match this prefix with one of "*
                "the following reference materials:")
    end
    method = getMethod(pd)
    if isnothing(method) PTerror("undefinedMethod") end
    refMats = collect(keys(referenceMaterials[method]))
    for i in eachindex(refMats)
        println(string(i)*". "*refMats[i])
    end
    if nst>2
        println("Enter your choices as number or a comma-separated list of "*
                "numbers matching the order in which you entered the prefixes.")
    end
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
    else return "xxx" end
end

function savelog!(pd,pars,action)
    println("Enter the path and name of the log file:")
    fpath = readline()
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

tree = Dict(
    "welcome" => 
    "===========\n"*
    "Plasmatrace\n"*
    "===========",
    "top" => (
        message =
        "f: Load the data files\n"*
        "m: Specify a method\n"*
        "b: Bulk settings\n"*
        "v: View and adjust each sample\n"*
        "p: Process the data\n"*
        "e: Export the results\n"*
        "l: Import/export a session log\n"*
        "x: Exit",
        actions = Dict(
            "f" => "load",
            "m" => "method",
            "b" => "bulk",
            "v" => "view",
            "p" => process!,
            "e" => "samples",
            "l" => "log",
            "x" => "x"
        )
    ),
    "load" => (
        message =
        "i. Specify your instrument [default=Agilent]\n"*
        "r. Open and read the data files\n"*
        "l. List all the samples in the session\n"*
        "x. Exit",
        actions = Dict(
            "i" => "instrument",
            "r" => "read",
            "l" => listSamples,
            "x" => "x"
        )
    ),
    "method" => (
        message =
        "Choose an application:\n"*
        "1. Lu-Hf",
        actions = chooseMethod!
    ),
    "bulk" => (
        message =
        "b. Set default blank windows\n"*
        "s. Set default signal windows\n"*
        "p. Add a standard by prefix\n"*
        "n. Adjust the order of the polynomial fits\n"*
        "r. Remove a standard\n"*
        "l. List all the standards\n"*
        "x. Exit",
        actions = Dict(
            "b" => "allBlankWindows",
            "s" => "allSignalWindows",
            "p" => "setStandardPrefixes",
            "n" => unsupported,
            "r" => unsupported,
            "l" => unsupported,
            "x" => "x"
        )
    ),
    "view" => (
        message =
        "n: next\n"*
        "p: previous\n"*
        "c: Choose which channels to show\n"*
        "r: Plot signals or ratios?\n"*
        "b: Select blank window(s)\n"*
        "w: Select signal window(s)\n"*
        "s: (un)mark as standard\n"*
        "x: Exit",
        actions = Dict(
            "n" => viewnext!,
            "p" => viewprevious!,
            "c" => "viewChannels",
            "r" => "setDen",
            "b" => unsupported,
            "w" => unsupported,
            "s" => unsupported,
            "x" => "x"
        )
    ),
    "samples" => (
        message =
        "Enter the prefix of the samples to export.\n"*
        "Alternatively, type 'a' to export all the samples.",
        actions = setSamplePrefixes!
    ),
    "export" => (
        message = 
        "j: export to .json\n"*
        "c: export to .csv\n"*
        "x. Exit",
        actions = Dict(
            "j" => "json",
            "c" => "csv",
            "x" => "xx"
        )
    ),
    "log" => (
        message =
        "s: save session to a log file\n"*
        "r: restore the log of a previous session\n"*
        "x. Exit",
        actions = Dict(
            "s" => savelog!,
            "r" => restorelog!,
            "x" => "x"
        )
    ),
    "instrument" => (
        message = 
        "Choose a file format:\n"*
        "1. Agilent",
        actions = load_i!
    ),
    "allBlankWindows" => (
        message =
        "a: automatic\n"*
        "s: set a one-part window\n"*
        "m: set a multi-part window",
        actions = Dict(
            "a" => allAutoBlankWindows!,
            "s" => "allSingleBlankWindows",
            "m" => "allMultiBlankWindows"
        )
    ),
    "allSignalWindows" => (
        message =
        "a: automatic\n"*
        "s: set a one-part window\n"*
        "m: set a multi-part window",
        actions = Dict(
            "a" => allAutoSignalWindows!,
            "s" => "allSingleSignalWindows",
            "m" => "allMultiSignalWindows"
        )
    ),
    "allSingleBlankWindows" => (
        message =
        "Enter the start and end point of the selection window (in seconds) "*
        "as a comma-separated pair of numbers. For example: 0,20 marks a blank "*
        "window from 0 to 20 seconds",
        actions = allSingleBlankWindows!
    ),
    "allSingleSignalWindows" => (
        message =
        "Enter the start and end point of the selection window (in seconds) "*
        "as a comma-separated pair of numbers. For example: 0,20 marks a blank "*
        "window from 0 to 20 seconds",
        actions = allSingleSignalWindows!
    ),
    "allMultiBlankWindows" => (
        message =
        "Enter the start and end points of the multi-part selection window "*
        "(in seconds) as a comma-separated list of bracketed pairs of numbers. "*
        "For example: (0,20),(25,30) marks a two-part selection window from "*
        "blank 0 to 20s, and from 25 to 30s.",
        actions = allMultiBlankWindows!
    ),
    "allMultiSignalWindows" => (
        message =
        "Enter the start and end points of the multi-part selection window "*
        "(in seconds) as a comma-separated list of bracketed pairs of numbers. "*
        "For example: (0,20),(25,30) marks a two-part selection window from "*
        "blank 0 to 20s, and from 25 to 30s.",
        actions = allMultiSignalWindows!
    ),
    "setStandardPrefixes" => (
        message =
        "s: Use a single primary reference material\n"*
        "m: Use multiple primary reference materials",
        actions = Dict(
            "s" => "setSingleStandardPrefix",
            "m" => "setMultipleStandardPrefixes"
        )
    ),
    "setSamplePrefixes" => (
        message =
        "s. Export one sample to a single table\n"*
        "m. Export multiple samples to multiple tables\n"*
        "a. Export all samples to a single table",
        actions = Dict(
            "s" => "exportOneSample",
            "m" => "exportMultipleSamples",
            "a" => clearSamplePrefixes!
        )
    ),
    "setSingleStandardPrefix" => (
        message = "Enter the prefix of the reference material:",
        actions = setStandardPrefixes!
    ),
    "setMultipleStandardPrefixes" => (
        message =
        "Enter the prefixes of the reference material as"*
        "a comma-separated list of names:",
        actions = setStandardPrefixes!
    ),
    "exportOneSample" => (
        message = "Enter the prefix of the sample to export:",
        actions = setSamplePrefixes!
    ),
    "exportMultipleSamples" => (
        message =
        "Enter the prefixes of the samples to export as a "*
        "comma-separated list of strings:",
        actions = setSamplePrefixes!
    ),
    "read" => (
        message =
        "Enter the full path of the data directory:",
        actions = loader!
    ),
    "channels" => (
        message = chooseChannelMessage,
        actions = chooseChannels!
    ),
    "viewChannels" => (
        message = viewChannelMessage,
        actions = viewChannels!
    ),
    "setDen" => (
        message = setDenMessage,
        actions = setDen!
    ),
    "refmat" => (
        message = chooseRefMatMessage,
        actions = chooseRefMat!
    ),
    "json" => (
        message = 
        "Enter the path and name of the .json file:",
        actions = unsupported
    ),  
    "csv" => (
        message = 
        "Enter the path and name of the .csv file:",
        actions = export2csv
    )
)

function PT() PT!() end
export PT

function PT!(fpath::String)
    logbook = CSV.read(fpath,DataFrame)
    myrun, pars = PT!(logbook)
    myrun
end

function PT!(logbook::Union{Nothing,DataFrame}=nothing)
    println(tree["welcome"])
    myrun = run()
    pars = TUIpars(["top"],DataFrame(task=String[],action=String[]),
                   1,nothing,nothing,nothing,nothing,[2,1])
    if isnothing(logbook)
        while true
            println()
            out = arbeid!(myrun,pars=pars,verbatim=false)
            if out == "exit" return end
            if out == "restorelog"
                myrun, pars = PT!(pars.history)
                pop!(pars.chain)
            end
        end
    else
        for row in eachrow(logbook)
            arbeid!(myrun,pars=pars,task=row[1],action=row[2],verbatim=false)
        end
        return myrun, pars
    end
end
export PT!

function arbeid!(pd::run;pars::TUIpars,
                 task=nothing,action=nothing,verbatim=false)
#    try
        if isempty(pars.chain) return "exit" end
        if isnothing(task) task = pars.chain[end] end
        out = dispatch!(pd,pars=pars,task=task,action=action,verbatim=verbatim)
        if isnothing(action) action = out.action end
        if out.next=="x"
            pop!(pars.chain)
        elseif out.next=="xx"
            pop!(pars.chain)
            pop!(pars.chain)
        elseif out.next=="xxx"
            pop!(pars.chain)
            pop!(pars.chain)
            pop!(pars.chain)
        elseif out.next=="restorelog"
            return "restorelog"
        elseif !isnothing(out.next)
            push!(pars.chain,out.next)
        end
        push!(pars.history,[task,action])
#    catch e
#        println(e)
#    end
    return nothing
end

function dispatch!(pd::Union{Nothing,run};
                   pars::TUIpars,task,action=nothing,verbatim=false)
    if verbatim
        println(pars.chain)
        println(pars.history)
    end
    todo = tree[task]
    if isa(todo.message,Function)
        todo.message(pd,pars)
    else
        println(todo.message)
    end
    if isnothing(action) action = readline()
    else println(action) end
    if (verbatim)
        println(todo.actions)
    end
    if isa(todo.actions,Function)
        next = todo.actions(pd,pars,action)
    elseif isa(todo.actions[action],Function)
        next = todo.actions[action](pd,pars,action)
    else
        next = todo.actions[action]
    end
    (action=action,next=next)
end
