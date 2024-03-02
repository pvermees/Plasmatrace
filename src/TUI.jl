function PT(logbook="")
    welcome()
    ctrl = Dict(
        "priority" => Dict("load" => true, "method" => true,
                           "standards" => true, "process" => true),
        "history" => DataFrame(task=String[],action=String[]),
        "chain" => ["top"],
        "i" => 1,
        "den" => nothing,
        "options" => Dict("blank" => 2, "drift" => 1, "down" => 1),
        "mf" => nothing
    )
    if logbook != ""
        TUIimport!(ctrl,logbook)
    end
    while true
        if length(ctrl["chain"])<1 return end
        try
            dispatch!(ctrl)
        catch e
            println(e)
        end
    end
end
export PT

function dispatch!(ctrl::AbstractDict;key=nothing,response=nothing)
    if isnothing(key) key = ctrl["chain"][end] end
    (message,action) = tree(key,ctrl)
    if isa(message,Function)
        println("\n"*message(ctrl))
    else
        println("\n"*message)
    end
    if isnothing(response) response = readline() end
    if isa(action,Function)
        next = action(ctrl,response)
    else
        next = action[response]
    end
    if isa(next,Function)
        next(ctrl)
    elseif next == "x"
        if length(ctrl["chain"])<1 return end
        pop!(ctrl["chain"])
    elseif next == "xx"
        if length(ctrl["chain"])<2 return end
        pop!(ctrl["chain"])
        pop!(ctrl["chain"])
    elseif next == "xxx"
        if length(ctrl["chain"])<3 return end
        pop!(ctrl["chain"])
        pop!(ctrl["chain"])
        pop!(ctrl["chain"])
    elseif isnothing(next)
        if length(ctrl["chain"])<1 return end
    else
        push!(ctrl["chain"],next)
    end
    if key != "import"
        push!(ctrl["history"],[key,response])
    end
end

function tree(key::AbstractString,ctrl::AbstractDict)
    branches = Dict(
        "top" => (
            message =
            "r: Read data files"*check(ctrl,"load")*"\n"*
            "m: Specify the method"*check(ctrl,"method")*"\n"*
            "t: Tabulate the samples\n"*
            "s: Mark standards"*check(ctrl,"standards")*"\n"*
            "v: View and adjust each sample\n"*
            "p: Process the data"*check(ctrl,"process")*"\n"*
            "e: Export the isotope ratios\n"*
            "l: Import/export a session log\n"*
            "o: Options\n"*
            "x: Exit",
            action = Dict(
                "r" => "instrument",
                "m" => "method",
                "t" => TUItabulate,
                "s" => "standards",
                "v" => TUIviewer!,
                "p" => TUIprocess!,
                "e" => "export",
                "l" => "log",
                "o" => "options",
                "x" => "x"
            )
        ),
        "instrument" => (
            message =
            "Choose a file format:\n"*
            "1. Agilent\n"*
            "x. Exit",
            action = TUIinstrument!
        ),
        "load" => (
            message = "Enter the full path of the data directory:",
            action = TUIload!,
        ),
        "method" => (
            message =
            "Choose a method:\n"*
            "1. Lu-Hf\n"*
            "x. Exit",
            action = TUImethod!
        ),
        "columns" => (
            message = TUIcolumnMessage,
            action = TUIcolumns!
        ),
        "iratio" => (
            message = TUIiratioMessage,
            action = TUIiratio!
        ),
        "standards" => (
            message =
            "Choose an option:\n"*
            "t. Tabulate all the samples\n"*
            "p. Add a standard by prefix\n"*
            "n. Add a standard by number\n"*
            "N. Remove a standard by number\n"*
            "r. Remove all standards\n"*
            "x. Exit",
            action = Dict(
                "t" => TUItabulate,
                "p" => "addStandardsByPrefix",
                "n" => "addStandardsByNumber",
                "N" => "removeStandardsByNumber",
                "r" => TUIresetStandards!,
                "x" => "x"
            )
        ),
        "addStandardsByPrefix" => (
            message = "Specify the prefix of the standard:",
            action = TUIaddStandardsByPrefix!
        ),
        "addStandardsByNumber" => (
            message = "Select the standards as a comma-separated list of numbers:",
            action = TUIaddStandardsByNumber!
        ),
        "removeStandardsByNumber" => (
            message = "Select the standards as a comma-separated list of numbers:",
            action = TUIremoveStandardsByNumber!
        ),
        "refmat" => (
            message = TUIshowRefmats,
            action = TUIsetStandards!
        ),
        "view" => (
            message = 
            "n: Next\n"*
            "p: Previous\n"*
            "g: Go to\n"*
            "t: Tabulate all the samples in the session\n"*
            "r: Plot signals or ratios?\n"*
            "b: Select blank window(s)\n"*
            "s: Select signal window(s)\n"*
            "x: Exit",
            action = Dict(
                "n" => TUInext!,
                "p" => TUIprevious!,
                "g" => "goto",
                "t" => TUItabulate,
                "r" => "setDen",
                "b" => "Bwin",
                "s" => "Swin",
                "x" => "x"
            )
        ),
        "goto" => (
            message = "Enter the number of the sample to plot:",
            action = TUIgoto!
        ),
        "setDen" => (
            message = TUIratioMessage,
            action = TUIratios!
        ),
        "Bwin" => (
            message =
            "Choose an option to set the blank window(s):\n"*
            "a: Automatic (current sample)\n"*
            "s: Manually set a one-part window (current sample)\n"*
            "m: Manually set a multi-part window (current sample)\n"*
            "A: Automatic (all samples)\n"*
            "S: Manually set a one-part window (all samples)\n"*
            "M: Manually set a multi-part window (all samples)\n"*
            "x: Exit",
            action = Dict(
                "a" => TUIoneAutoBlankWindow!,
                "s" => "oneSingleBlankWindow",
                "m" => "oneMultiBlankWindow",
                "A" => TUIallAutoBlankWindow!,
                "S" => "allSingleBlankWindow",
                "M" => "allMultiBlankWindow",
                "x" => "x"
            )
        ),
        "Swin" => (
            message =
            "Choose an option to set the signal window(s):\n"*
            "a: Automatic (current sample)\n"*
            "s: Manually set a one-part window (current sample)\n"*
            "m: Manually set a multi-part window (current sample)\n"*
            "A: Automatic (all samples)\n"*
            "S: Manually set a one-part window (all samples)\n"*
            "M: Manually set a multi-part window (all samples)\n"*
            "x: Exit",
            action = Dict(
                "a" => TUIoneAutoSignalWindow!,
                "s" => "oneSingleSignalWindow",
                "m" => "oneMultiSignalWindow",
                "A" => TUIallAutoSignalWindow!,
                "S" => "allSingleSignalWindow",
                "M" => "allMultiSignalWindow",
                "x" => "x"
            )
        ),
        "oneSingleBlankWindow" => (
            message =
            "Enter the start and end point of the selection window (in seconds)\n"*
            "Type 'h' for help.",
            action = TUIoneSingleBlankWindow!
        ),
        "oneMultiBlankWindow" => (
            message =
            "Enter the start and end points of the multi-part "*
            "selection window (in seconds)\n"*
            "Type 'h' for help.",
            action = TUIoneMultiBlankWindow!
        ),
        "allSingleBlankWindow" => (
            message =
            "Enter the start and end point of the selection window (in seconds)\n"*
            "Type 'h' for help.",
            action = TUIallSingleBlankWindow!
        ),
        "allMultiBlankWindow" => (
            message =
            "Enter the start and end points of the multi-part "*
            "selection window (in seconds)\n"*
            "Type 'h' for help.",
            action = TUIallMultiBlankWindow!
        ),
        "oneSingleSignalWindow" => (
            message =
            "Enter the start and end point of the selection window (in seconds)\n"*
            "Type 'h' for help.",
            action = TUIoneSingleSignalWindow!
        ),
        "oneMultiSignalWindow" => (
            message =
            "Enter the start and end points of the multi-part "*
            "selection window (in seconds)\n"*
            "Type 'h' or help.",
            action = TUIoneMultiSignalWindow!
        ),
        "allSingleSignalWindow" => (
            message =
            "Enter the start and end point of the selection windows (in seconds)\n"*
            "Type 'h' for help.",
            action = TUIallSingleSignalWindow!
        ),
        "allMultiSignalWindow" => (
            message =
            "Enter the start and end points of the multi-part "*
            "selection windows (in seconds)\n"*
            "Type 'h' for help.",
            action = TUIallMultiSignalWindow!
        ),
        "options" => (
            message =
            "Set one of the following parameters:\n"*
            "b. Polynomial order of the blank correction\n"*
            "d. Polynomial order of the drift correction\n"*
            "h. Polynomial order of the down hole fractionation correction\n"*
            "f. Fix or fit the fractionation factor\n"*
            "x. Exit",
            action = Dict(
                "b" => "setNblank",
                "d" => "setNdrift",
                "h" => "setNdown",
                "f" => "setmf",
                "x" => "x"
            )
        ),
        "setNblank" => (
            message = "Enter a non-negative integer (current value = "*
            string(ctrl["options"]["blank"])*"):",
            action = TUIsetNblank!
        ),
        "setNdrift" => (
            message = "Enter a non-negative integer (current value = "*
            string(ctrl["options"]["drift"])*")",
            action = TUIsetNdrift!
        ),
        "setNdown" => (
            message = "Enter a non-negative integer (current value = "*
            string(ctrl["options"]["down"])*")",
            action = TUIsetNdown!
        ),
        "setmf" => (
            message = "Click [Enter] to treat the mass fractionation as a free "*
            "parameter, or enter a decimal number (currently "*
            (isnothing(ctrl["mf"]) ? "fitted" : ("fixed at "*string(ctrl["mf"])))*")",
            action = TUIsetmf!
        ),
        "export" => (
            message =
            "Choose an option:\n"*
            "c. Export to .csv\n"*
            "j. Export to .json\n"*
            "x. Exit",
            action = Dict(
                "c" => "csv",
                "j" => "json",
                "x" => "x"
            )
        ),
        "csv" => (
            message = "Enter the path and name of the .csv file:",
            action = TUIexport2csv
        ),
        "json" => (
            message = "Enter the path and name of the .json file:",
            action = TUIexport2json
        ),
        "log" => (
            message =
            "Choose an option:\n"*
            "i. Import a session log\n"*
            "e. Export the session log\n"*
            "x. Exit",
            action = Dict(
                "i" => "importLog",
                "e" => "exportLog",
                "x" => "x"
            )
        ),
        "importLog" => (
            message = "Enter the path and name of the log file:",
            action = TUIimport!
        ),
        "exportLog" => (
            message = "Enter the path and name of the log file:",
            action = TUIexport
        )
    )
    return branches[key]
end

function welcome()
    version = string(pkgversion(@__MODULE__))
    title = " Plasmatrace "*version*" \n"
    width = Base.length(title)-1
    println('-'^width*"\n"*title*'-'^width)
end

function check(ctrl::AbstractDict,action::AbstractString)
    return ctrl["priority"][action] ? "[*]" : ""
end

function TUIinstrument!(ctrl::AbstractDict,response::AbstractString)
    if response=="1"
        ctrl["instrument"] = "Agilent"
    else
        return "x"
    end
    return "load"
end

function TUIload!(ctrl::AbstractDict,response::AbstractString)
    ctrl["run"] = load(response,instrument=ctrl["instrument"])
    ctrl["priority"]["load"] = false
    return "xx"
end

function TUImethod!(ctrl::AbstractDict,response::AbstractString)
    if response=="1"
        ctrl["method"] = "LuHf"
    else
        return "x"
    end
    return "columns"
end

function TUIcolumnMessage(ctrl::AbstractDict)
    msg = "Choose from the following list of channels:\n"
    labels = names(ctrl["run"][1].dat)[3:end]
    for i in eachindex(labels)
        msg *= string(i)*". "*labels[i]*"\n"
    end
    msg *= "and select the channels corresponding to "*
    "the following isotopes or their proxies:\n"
    if ctrl["method"]=="LuHf"
        msg *= "176Lu, 176Hf, 177Hf\n"
    end
    msg *= "Specify your selection as a "*
    "comma-separated list of numbers:\n"
    return msg
end

function TUIcolumns!(ctrl::AbstractDict,response::AbstractString)
    labels = names(ctrl["run"][1].dat)[3:end]
    selected = parse.(Int,split(response,","))
    PDd = labels[selected]
    next = "xx"
    if ctrl["method"]=="LuHf"
        ctrl["channels"] = Dict("d" => PDd[3], "D" => PDd[2], "P" => PDd[1])
        ctrl["priority"]["method"] = false
        next = "iratio"
    end
    return next
end

function TUIiratioMessage(ctrl::AbstractDict)
    if ctrl["method"]=="LuHf"
        msg = "Which Hf-isotope is measured as "*ctrl["channels"]["d"]*"?\n"*
        "1. 174Hf\n"*
        "2. 177Hf\n"*
        "3. 178Hf\n"*
        "4. 179Hf\n"*
        "5. 180Hf\n"
    end
    return msg
end

function TUIiratio!(ctrl::AbstractDict,response::AbstractString)
    if ctrl["method"]=="LuHf"
        if response=="1"
            ctrl["mf"] = _PT["iratio"]["Hf174Hf177"]
        elseif response=="3"
            ctrl["mf"] = _PT["iratio"]["Hf178Hf177"]
        elseif response=="4"
            ctrl["mf"] = _PT["iratio"]["Hf179Hf177"]
        elseif response=="5"
            ctrl["mf"] = _PT["iratio"]["Hf180Hf177"]
        else # "2"
            ctrl["mf"] = nothing
        end
    end
    return "xxx"
end

function TUItabulate(ctrl::AbstractDict)
    summarise(ctrl["run"])
end

function TUIaddStandardsByPrefix!(ctrl::AbstractDict,response::AbstractString)
    snames = getSnames(ctrl["run"])
    ctrl["selection"] = findall(contains(response),snames)
    return "refmat"
end

function TUIaddStandardsByNumber!(ctrl::AbstractDict,response::AbstractString)
    ctrl["selection"] = parse.(Int,split(response,","))
    return "refmat"    
end

function TUIremoveStandardsByNumber!(ctrl::AbstractDict,response::AbstractString)
    selection = parse.(Int,split(response,","))
    resetStandards!(ctrl["run"],selection)
    return "x"
end

function TUIresetStandards!(ctrl::AbstractDict)
    setStandards!(ctrl["run"])
    return "x"
end

function TUIshowRefmats(ctrl::AbstractDict)
    if ctrl["method"]=="LuHf"
        msg = "Which of the following standards did you select?\n"*
        "1. Hogsbo\n"*
        "2. BP"
    end
    return msg
end

function TUIsetStandards!(ctrl::AbstractDict,response::AbstractString)
    if ctrl["method"]=="LuHf"
        if response=="1"
            setStandards!(ctrl["run"],ctrl["selection"],"Hogsbo")
        elseif response=="2"
            setStandards!(ctrl["run"],ctrl["selection"],"BP")
        end
    end
    ctrl["priority"]["standards"] = false
    return "xxx"
end

function TUIviewer!(ctrl::AbstractDict)
    TUIplotter(ctrl)
    push!(ctrl["chain"],"view")
end

function TUIprocess!(ctrl::AbstractDict)
    println("Fitting blanks...")
    ctrl["blank"] = fitBlanks(ctrl["run"],n=ctrl["options"]["blank"])
    groups = unique(getGroups(ctrl["run"]))
    stds = groups[groups.!="sample"]
    ctrl["anchors"] = getAnchor(ctrl["method"],stds)
    println("Fractionation correction...")
    ctrl["par"] = fractionation(ctrl["run"],blank=ctrl["blank"],
                                channels=ctrl["channels"],
                                anchors=ctrl["anchors"],mf=ctrl["mf"])
    ctrl["priority"]["process"] = false
    println("Done")
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

function TUIplotter(ctrl::AbstractDict)
    i = ctrl["i"]
    if haskey(ctrl,"channels")
        channels = ctrl["channels"]
    else
        channels = names(ctrl["run"][i].dat)[3:end]
        println(channels)
    end
    p = plot(ctrl["run"][i],channels,den=ctrl["den"])
    display(p)
end

function TUIratioMessage(ctrl::AbstractDict)
    if haskey(ctrl,"channels")
        channels = collect(values(ctrl["channels"]))
    else
        channels = names(ctrl["run"][ctrl["i"]].dat)[3:end]
    end
    msg = "Choose one of the following denominators:\n"
    for i in 1:length(channels)
        msg *= string(i)*". "*channels[i]*"\n"
    end
    msg *= "or\n"
    msg *= "n. No denominator. Plot the raw signals"
end

function TUIratios!(ctrl::AbstractDict,response::AbstractString)
    if response=="n"
        ctrl["den"] = nothing
    else
        i = parse(Int,response)
        if haskey(ctrl,"channels")
            channels = collect(values(ctrl["channels"]))
        else
            channels = names(ctrl["run"][ctrl["i"]].dat)[3:end]
        end
        ctrl["den"] = [channels[i]]
    end
    TUIplotter(ctrl)
    return "x"
end

function TUIoneAutoBlankWindow!(ctrl::AbstractDict)
    setBwin!(ctrl["run"][ctrl["i"]])
    TUIplotter(ctrl)
end

function TUIoneSingleBlankWindow!(ctrl::AbstractDict,response::AbstractString)
    response = TUIhelp("TUIoneSingleBlankWindow!",response)
    samp = ctrl["run"][ctrl["i"]]
    bwin = string2windows(samp,text=response,single=true)
    setBwin!(samp,bwin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIoneMultiBlankWindow!(ctrl::AbstractDict,response::AbstractString)
    response = TUIhelp("TUIoneMultiBlankWindow!",response)
    samp = ctrl["run"][ctrl["i"]]
    bwin = string2windows(samp,text=response,single=false)
    setBwin!(samp,bwin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIallAutoBlankWindow!(ctrl::AbstractDict)
    setBwin!(ctrl["run"])
    TUIplotter(ctrl)
end

function TUIallSingleBlankWindow!(ctrl::AbstractDict,response::AbstractString)
    response = TUIhelp("TUIallSingleBlankWindow!",response)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        bwin = string2windows(samp,text=response,single=true)
        setBwin!(samp,bwin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUIallMultiBlankWindow!(ctrl::AbstractDict,response::AbstractString)
    response = TUIhelp("TUIallMultiBlankWindow!",response)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        bwin = string2windows(samp,text=response,single=false)
        setBwin!(samp,bwin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUIoneAutoSignalWindow!(ctrl::AbstractDict)
    setSwin!(ctrl["run"][ctrl["i"]])
    TUIplotter(ctrl)
end

function TUIoneSingleSignalWindow!(ctrl::AbstractDict,response::AbstractString)
    response = TUIhelp("TUIoneSingleSignalWindow!",response)
    samp = ctrl["run"][ctrl["i"]]
    swin = string2windows(samp,text=response,single=true)
    setSwin!(samp,swin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIoneMultiSignalWindow!(ctrl::AbstractDict,response::AbstractString)
    response = TUIhelp("TUIoneMultiSignalWindow!",response)
    samp = ctrl["run"][ctrl["i"]]
    swin = string2windows(samp,text=response,single=false)
    setSwin!(samp,swin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIallAutoSignalWindow!(ctrl::AbstractDict)
    setSwin!(ctrl["run"])
    TUIplotter(ctrl)
end

function TUIallSingleSignalWindow!(ctrl::AbstractDict,response::AbstractString)
    response = TUIhelp("TUIallSingleSignalWindow!",response)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        swin = string2windows(samp,text=response,single=true)
        setSwin!(samp,swin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUIallMultiSignalWindow!(ctrl::AbstractDict,response::AbstractString)
    response = TUIhelp("TUIallMultiSignalWindow!",response)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        swin = string2windows(samp,text=response,single=false)
        setSwin!(samp,swin)
    end
    TUIplotter(ctrl)
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

function TUIsetmf!(ctrl::AbstractDict,response::AbstractString)
    ctrl["mf"] = response=="" ? nothing : parse(Float64,response)
    return "x"
end

function TUIimport!(ctrl::AbstractDict,response::AbstractString)
    history = CSV.read(response,DataFrame)
    ctrl["history"] = DataFrame(task=String[],action=String[])
    for row in eachrow(history)
        try
            dispatch!(ctrl,key=row[1],response=row[2])
        catch e
            println(e)
        end
    end
    return nothing
end

function TUIexport(ctrl::AbstractDict,response::AbstractString)
    pop!(ctrl["history"])
    pop!(ctrl["history"])
    CSV.write(response,ctrl["history"])
    return "xx"
end

function TUIexport2csv(ctrl::AbstractDict,response::AbstractString)
    ratios = averat(ctrl["run"],channels=ctrl["channels"],
                    pars=ctrl["par"],blank=ctrl["blank"])
    fname = splitext(response)[1]*".csv"
    CSV.write(fname,ratios)
    return "xx"
end

function TUIexport2json(ctrl::AbstractDict,response::AbstractString)
    ratios = averat(ctrl["run"],channels=ctrl["channels"],
                    pars=ctrl["par"],blank=ctrl["blank"])
    fname = splitext(response)[1]*".json"
    println("Not implemented yet.")
    return "xx"
end

function TUIhelp(fun::AbstractString,response::AbstractString)
    prompt = Dict(
        "TUIoneSingleBlankWindow!" =>
        "Specify the start and end point of the blank window "*
        "as a comma-separated pair of numbers. For example: 0,20 marks "*
        "a blank window from 0 to 20 seconds.",
        "TUIoneMultiBlankWindow!" =>
        "Specify the start and end points of the blank window "*
        "as a comma-separated list of bracketed pairs "*
        " of numbers. For example: (0,20),(25,30) marks a two-part "*
        "selection window from 0 to 20s, and from 25 to 30s.",
        "TUIallSingleBlankWindow!" =>
        "Specify the start and end point of the blank windows "*
        "as a comma-separated pair of numbers. For example: 0,20 marks "*
        "a blank window from 0 to 20 seconds.",
        "TUIallMultiBlankWindow!" =>
        "Specify the start and end points of the blank windows "*
        "as a comma-separated list of bracketed pairs "*
        " of numbers. For example: (0,20),(25,30) marks a two-part "*
        "selection window from 0 to 20s, and from 25 to 30s.",
        "TUIoneSingleSignalWindow!" =>
        "Specify the start and end points of the signal window "*
        "as a comma-separated pair of numbers. For example: 30,60 marks "*
        "a signal window from 30 to 60 seconds.",
        "TUIoneMultiSignalWindow!" =>
        "Specify the start and end points of the signal window "*
        "as a comma-separated list of bracketed pairs "*
        "of numbers. For example: (40,45),(50,60) marks a two-part "*
        "signal window from 40 to 45s, and from 50 to 60s.",
        "TUIallSingleSignalWindow!" =>
        "Specify the start and end points of the signal windows "*
        "as a comma-separated pair of numbers. For example: 30,60 marks "*
        "a signal window from 30 to 60 seconds.",
        "TUIallMultiSignalWindow!" =>
        "Specify the start and end points of the signal windows "*
        "as a comma-separated list of bracketed pairs "*
        "of numbers. For example: (40,45),(50,60) marks a two-part "*
        "signal window from 40 to 45s, and from 50 to 60s."
    )
    if response == "h"
        println(prompt[fun])
        response = readline()
    end
    return response
end
