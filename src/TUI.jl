function prompt(key)
    messages = Dict(
        "welcome" =>
        "===========\n"*
        "Plasmatrace\n"*
        "===========\n",
        "top" =>
        "f: Load the data files\n"*
        "m: Specify a method\n"*
        "s: Mark mineral standards\n"*
        "v: View the data\n"*
        "j: Save the data as .json\n"*
        "c: Save the data as .csv\n"*
        "l: Save a log of the current session\n"*
        "r: Restore the log of a previous session\n"*
        "x: Exit",
        "load" =>
        "i. Specify your instrument [default=Agilent]\n"*
        "r. Read the data\n"*
        "l. List all the samples in the session\n"*
        "x. Exit",
        "method" =>
        "Choose an application:\n"*
        "1. Lu-Hf",
        "channels" => "",
        "standards" =>
        "p. Add a standard by prefix\n"*
        "r. Remove a standard\n"*
        "l. List all the standards\n"*
        "x. Exit",
        "view" =>
        "n,[Enter]: next\n"*
        "p,[Space]: previous\n"*
        "c: Choose which channels to show\n"*
        "r: Switch between ratios and raw signals\n"*
        "b: Select blank window(s)\n"*
        "w: Select signal window(s)\n"*
        "s: Mark as standard\n"*
        "x: Exit",
        "instrument" =>
        "Choose a file format:\n"*
        "1. Agilent",
        "read" =>
        "Enter the full path of the data directory:"
    )
    println(messages[key])
end

function dispatch!(pd::Union{Nothing,run};
                   pars::TUIpars,task,action=nothing,verbatim=false)
    prompt(task)
    if isnothing(action) action = readline()
    else println(action) end
    next = "x"
    if task=="top"
        if action=="f"
            next = "load"
        elseif action=="m"
            next = "method"
        elseif action=="s"
            next = "standards"
        elseif action=="v"
            next = "view"
        elseif action=="j"
            next = unsupported()
        elseif action=="c"
            next = unsupported()
        elseif action=="l"
            next = "savelog"
        elseif action=="r"
            next = "restorelog"
        elseif action!="x"
            next = unsupported()
        end
    elseif task=="method"
        next = chooseMethod!(pd,action)
    elseif task=="channels"
        next = chooseChannels!(pd,action)
    elseif task=="load"
        if action=="i"
            next = "instrument"
        elseif action=="r"
            next = "read"
        elseif action=="l"
            listSamples(pd)
        elseif action!="x"
            next = unsupported()
        end
    elseif task=="application"
        method_a!(pd,action)
    elseif task=="view"
        samples = getSamples(pd)
        ns = size(samples,1)
        p = plot(samples[pars.i])
        display(p)
        next = nothing
        if action=="" || action=="n"
            pars.i = pars.i<ns ? pars.i+1 : 1
            action = "n" # easier to recognise in session log
        elseif action==" " || action=="p"
            pars.i = pars.i>1 ? pars.i-1 : ns
            action = "p" # easier to recognise in session log
        elseif action=="b"
            next = unsupported()
        elseif action=="w"
            next = unsupported()
        elseif action=="w"
            next = unsupported()
        elseif action=="s"
            next = unsupported()
        elseif action=="x"
            next = "x"
        else
            next = unsupported()
        end
    elseif task=="instrument"
        load_i!(pd,action)
    elseif task=="read"
        load!(pd,dname=action)
    elseif task=="standards"
        if action=="p"
            addStandardPrefix!(pd)
        elseif action=="r"
            deleteStandards!(pd)
        elseif action=="l"
            listStandards(pd)
        elseif action!="x"
            next = unsupported()
        end
    else
        next = unsupported()
    end
    (action=action,next=next)
end

function PT()
    PT!()
end
export PT

function PT!(logbook::Union{Nothing,DataFrame}=nothing)
    prompt("welcome")
    pars = TUIpars(["top"],DataFrame(task=String[],action=String[]),1)
    myrun = run()
    if isnothing(logbook)
        while true
            out = arbeid!(myrun,pars=pars,verbatim=true)
            if out == "exit" return end
            if out == "restorelog"
                restorelog!(pars)
                myrun = PT!(pars.history)
            end
        end
    else
        for row in eachrow(logbook)
            arbeid!(myrun,pars=pars,task=row[1],action=row[2],
                    restore=true,verbatim=true)
        end
        return myrun
    end
end

function arbeid!(pd::run;pars::TUIpars,task=nothing,
                 action=nothing,restore=false,verbatim=false)
    try
        if isempty(pars.chain) return "exit" end
        if !restore # new run
            task = pars.chain[end]
            action = nothing
        end
        out = dispatch!(pd,pars=pars,task=task,action=action,verbatim=verbatim)
        if isnothing(action) action = out.action end
        if out.next=="x"
            pop!(pars.chain)
        elseif out.next=="xx"
            pop!(pars.chain)
            pop!(pars.chain)
        elseif out.next=="savelog"
            savelog(pars.history)
        elseif out.next=="restorelog"
            return "restorelog"
        elseif !isnothing(out.next)
            push!(pars.chain,out.next)
        end
        push!(pars.history,[task,action])
    catch e
        println(e)
    end
    if size(pars.chain,1)<1 return "exit" end
    return "continue"
end

function unsupported()
    println("This feature is not available yet.\n")
    return nothing
end

function chooseMethod!(pd,action)
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
        println("Select the data columns (as a comma-separated list of numbers)\n")
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

function chooseChannels!(pd,response)
    samples = getSamples(pd)
    selected = parse.(Int,split(response,","))
    labels = names(getDat(samples[1]))[3:end]
    DRSchannels!(pd,channels=labels[selected])
    return "xx"
end

function load_i!(pd,action)
    if action=="1" instrument = "Agilent"
    else return end
    setInstrument!(pd,instrument)
end

function listSamples(pd)
    snames = getSnames(pd)
    for sname in snames
        println(sname)
    end
end

function addStandardPrefix!(pd)
    println("Enter the prefix of the standards:")
    prefix = readline()
    println("Enter the number of the standard")
    
    number = readline()
    markStandards!(pd,prefix=response,standard=parse(Int,number))
end

function deleteStandard!(pd)
    
end

function listStandards(pd)
    samples = getSnames(pd)
    standards = getStandard(pd)
    println(standards)
end

function savelog(history)
    println("Name the log file "*
            "(e.g., history.log or /home/johndoe/mydata/mylog.txt):")
    fpath = readline()
    println(history)
    CSV.write(fpath,history)
end

function restorelog!(pars::TUIpars)
    println("Provide the path of the log file "*
            "(e.g., history.log or /home/johndoe/mydata/mylog.txt):")
    fpath = readline()
    hist = CSV.read(fpath,DataFrame)
    empty!(pars.history)
    append!(pars.history,hist)
end
