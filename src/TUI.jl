function PT(;logbook="",debug=false)
    welcome()
    ctrl = Dict(
        "priority" => Dict("load" => true, "standards" => true,
                           "process" => true, "method" => true),
        "history" => DataFrame(task=String[],action=String[]),
        "chain" => ["top"]
    )
    if logbook != ""
        TUIimport!(ctrl,logbook)
    end
    while true
        dispatch!(ctrl)
        if debug
            println(ctrl["history"])
            println(ctrl["chain"])
            println(keys(ctrl))
        end
        if length(ctrl["chain"])==0 return end
    end
end
export PT

function dispatch!(ctrl::AbstractDict;key=nothing,response=nothing)
    if isnothing(key) key = ctrl["chain"][end] end
    (message,action) = tree(key,ctrl)
    if isa(message,Function)
        println(message(ctrl))
    else
        println(message)
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
        pop!(ctrl["chain"])
    elseif next == "xx"
        pop!(ctrl["chain"])
        pop!(ctrl["chain"])
    elseif next == "restored"
        # do nothing
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
            "x: Exit",
            action = Dict(
                "r" => "instrument",
                "m" => "method",
                "t" => TUItabulate,
                "s" => "standards",
                "v" => "view",
                "p" => "process",
                "e" => "export",
                "l" => "log",
                "x" => "x"
            )
        ),
        "instrument" => (
            message = "Choose a file format:\n"*
            "1. Agilent\n"*
            "x. Exit",
            action = TUIinstrument!
        ),
        "load" => (
            message = "Enter the full path of the data directory:",
            action = TUIload!,
        ),
        "method" => (
            message = "Choose a method:\n"*
            "1. Lu-Hf\n"*
            "x. Exit",
            action = TUImethod!
        ),
        "columns" => (
            message = TUIcolumnMessage,
            action = TUIcolumns!
        ),
        "log" => (
            message = "Choose an option:\n"*
            "i. Import a session log\n"*
            "e. Export the session log\n"*
            "x. Exit",
            action = Dict(
                "i" => "import",
                "e" => "export",
                "x" => "x"
            )
        ),
        "import" => (
            message = "Enter the path and name of the log file:",
            action = TUIimport!
        ),
        "export" => (
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
        ctrl["method"] = "Lu-Hf"
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
    if ctrl["method"]=="Lu-Hf"
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
    if ctrl["method"]=="Lu-Hf"
        ctrl["channels"] = Dict("d" => PDd[3], "D" => PDd[2], "P" => PDd[3])
        ctrl["priority"]["method"] = false
    end
    return "xx"
end

function TUItabulate(ctrl::AbstractDict)
    summarise(ctrl["run"])
end

function TUIimport!(ctrl::AbstractDict,response::AbstractString)
    history = CSV.read(response,DataFrame)
    ctrl["history"] = DataFrame(task=String[],action=String[])
    ctrl["chain"] = String[]
    for row in eachrow(history)
        dispatch!(ctrl,key=row[1],response=row[2])
    end
    ctrl["chain"] = ["top"]
    return "restored"
end

function TUIexport(ctrl::AbstractDict,response::AbstractString)
    pop!(ctrl["history"])
    pop!(ctrl["history"])
    CSV.write(response,ctrl["history"])
    return "xx"
end
