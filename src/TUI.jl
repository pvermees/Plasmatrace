function unsupported(pd,pars,action)
    println("This feature is not available yet.\n")
    return nothing
end,

function chooseMethod!(pd,pars,action)
    if action=="1"
        method = "LuHf"
    else
        return
    end
    DRSmethod!(pd,method=method)
    isotopes = getIsotopes(pd)
    samples = getSamples(pd)
    out = "x"
    if isnothing(isotopes)
        println("Choose a geochronometer first.")
    elseif isnothing(samples)
        println("Load the data first.")
    else
        println("Select the data columns as a comma-separated list of numbers\n")
        labels = names(getDat(samples[1]))[3:end]
        for i in eachindex(labels)
            println(string(i)*". "*labels[i])
        end
        println("\ncorresponding to the following isotopes or their proxies:")
        println(join(isotopes,","))
        println("For example: "*join(1:size(isotopes,1),","))
        out = "channels"
    end
    out
end

function chooseChannels!(pd,pars,action)
    samples = getSamples(pd)
    selected = parse.(Int,split(action,","))
    labels = names(getDat(samples[1]))[3:end]
    DRSchannels!(pd,channels=labels[selected])
    pars.channels = labels[selected]
    return "xx"
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
    p = plot(samp,channels=pars.channels)
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
        "s: Mark mineral standards\n"*
        "v: View the data\n"*
        "e: Export the results\n"*
        "l: Import/export a session log\n"*
        "x: Exit",
        actions = Dict(
            "f" => "load",
            "m" => "method",
            "s" => "standards",
            "v" => "view",
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
    "standards" => (
        message =
        "p. Add a standard by prefix\n"*
        "r. Remove a standard\n"*
        "l. List all the standards\n"*
        "x. Exit",
        actions = Dict(
            "p" => unsupported,
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
        "r: Switch between ratios and raw signals\n"*
        "b: Select blank window(s)\n"*
        "w: Select signal window(s)\n"*
        "s: Mark as standard\n"*
        "x: Exit",
        actions = Dict(
            "n" => viewnext!,
            "p" => viewprevious!,
            "c" => unsupported,
            "r" => unsupported,
            "b" => unsupported,
            "w" => unsupported,
            "s" => unsupported,
            "x" => "x"
        )
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
    "read" => (
        message =
        "Enter the full path of the data directory:",
        actions = loader!
    ),
    "channels" => (
        message = "",
        actions = chooseChannels!
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
    pars = TUIpars(["top"],DataFrame(task=String[],action=String[]),1,nothing)
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
    println(todo.message)
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
