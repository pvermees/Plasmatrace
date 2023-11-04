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
            "the following isotopes or their proxies:")
    println(join(isotopes,","))
    println("\nSpecify your selection as a comma-separated list of numbers.")
    println("For example: "*join(1:size(isotopes,1),","))
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
    println("\nSpecify your selection as a comma-separated list of numbers.")
end

function viewChannels!(pd,pars,action)
    selectChannels!(pd,pars,action)
    viewer(pd=pd,pars=pars)
    return "x"
end

function string2windows(pd,pars,action)
    parts = split(action,['(',')',','])
    stime = parse.(Int,parts[2:4:end])
    ftime = parse.(Int,parts[3:4:end])
    nw = Int(round(size(parts,1)/4))
    windows = Vector{window}(undef,nw)
    t = getDat(pd,i=pars.i)[:,2]
    nt = size(t,1)
    maxt = t[end]
    for i in 1:nw
        start = Int(ceil(nt*stime[i]/maxt))
        finish = Int(floor(nt*ftime[i]/maxt))
        windows[i] = (start,finish)
    end
    println(windows)
    windows
end

function allBlankWindows!(pd,pars,action)
    if action=="a"
        setBlanks!(pd)
    else
        windows = string2windows(pd,pars,action)
        setBlanks!(pd,windows=windows)
    end
    return "x"
end

function allSignalWindows!(pd,pars,action)
    if action=="a"
        setSignals!(pd)
    else
        windows = string2windows(pd,pars,action)
        setSignals!(pd,windows=windows)
    end
    return "x"
end

function load_i!(pd,pars,action)
    if action=="1" instrument = "Agilent"
    else return end
    setInstrument!(pd,instrument)
    return nothing
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
    println("To plot as ratios, choose one of the following "*
            "channels as a denominator:")
    for i in eachindex(pars.channels)
        println(string(i)*". "*pars.channels[i])
    end
    println("Enter one number or leave empty to plot raw signals")
end

function setDen!(pd,pars,action)
    i = parse(Int,action)
    pars.den = action=="" ? nothing : [pars.channels[i]]
    viewer(pd=pd,pars=pars)
    return "x"
end

function setStandardPrefixes!(pd,pars,action)
    prefixes = string.(split(action,","))
    for i in eachindex(prefixes)
        markStandards!(pd,prefix=prefixes[i],standard=i)
    end
    return "refmat"
end

function chooseRefMatMessage(pd,pars)
    println("Now match this/these prefix(es) with the following reference materials:")
    method = getMethod(pd)
    refMats = collect(keys(referenceMaterials[method]))
    for i in eachindex(refMats)
        println(string(i)*". "*refMats[i])
    end
    println("Enter your choice(s) as number or a comma-separated list of numbers,")
    println("matching the order in which you entered the prefixes.")
end

function chooseRefMat!(pd,pars,action)
    method = getMethod(pd)
    refmats = collect(keys(referenceMaterials[method]))
    i = parse.(Int,split(action,","))
    pars.refmats = refmats[i]
    return "xx"
end

function process!(pd,pars,action)
    if action=="Y"
        println("Fitting blanks...")
        fitBlanks!(pd,n=pars.n[1])
        println("Fitting standards...")
        fitStandards!(pd,refmat=pars.refmats,n=pars.n[2])
    end
    return "x"
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
    "===========\n",
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
            "p" => "process",
            "e" => "export",
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
        "r: Signals or ratios?\n"*
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
    "process" => (
        message = "Reprocess the data? [Y,n]",
        actions = process!
    ),
    "export" => (
        message = 
        "j: export to .json\n"*
        "c: export to .csv\n"*
        "x. Exit",
        actions = Dict(
            "j" => "json",
            "c" => "csv",
            "x" => "x"
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
        "Specify the blank windows. The following are all valid entries:\n\n"*
        "a: automatically select all the windows\n"*
        "(m,M): set a single window from m to M seconds, e.g. (0,20)\n"*
        "(m1,M1),(m2,M2): set multiple windows, e.g. (0,20),(25,30)",
        actions = allBlankWindows!
    ),
    "allSignalWindows" => (
        message =
        "Specify the signal windows. The following are all valid entries:\n\n"*
        "a: automatically select all the windows\n"*
        "(m,M): set a single window from m to M seconds, e.g. (0,20)\n"*
        "(m1,M1),(m2,M2): set multiple windows, e.g. (0,20),(25,30)",
        actions = allSignalWindows!
    ),
    "setStandardPrefixes" => (
        message =
        "Enter the prefix(es) of the primary standard(s) as "*
        "a comma-separated list of strings. For example:\n"*
        "hogsbo_\n"*
        "hogsbo_,BP -",
        actions = setStandardPrefixes!
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
        actions = unsupported
    )
)

function PT() PT!() end
export PT

function PT!(logbook::Union{Nothing,DataFrame}=nothing)
    println(tree["welcome"])
    myrun = run()
    pars = TUIpars(["top"],DataFrame(task=String[],action=String[]),
                   1,nothing,nothing,nothing,[2,1])
    if isnothing(logbook)
        while true
            out = arbeid!(myrun,pars=pars,verbatim=false)
            if out == "exit" return end
            if out == "restorelog"
                myrun, pars = PT!(pars.history)
            end
        end
    else
        for row in eachrow(logbook)
            arbeid!(myrun,pars=pars,task=row[1],action=row[2],verbatim=false)
        end
        return myrun, pars
    end
end

function arbeid!(pd::run;pars::TUIpars,
                 task=nothing,action=nothing,verbatim=false)
    try
        if isempty(pars.chain) return "exit" end
        if isnothing(task) task = pars.chain[end] end
        out = dispatch!(pd,pars=pars,task=task,action=action,verbatim=verbatim)
        if isnothing(action) action = out.action end
        if out.next=="x"
            pop!(pars.chain)
        elseif out.next=="xx"
            pop!(pars.chain)
            pop!(pars.chain)
        elseif out.next=="restorelog"
            return "restorelog"
        elseif !isnothing(out.next)
            push!(pars.chain,out.next)
        end
        push!(pars.history,[task,action])
    catch e
        println(e)
    end
    return "continue"
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
