function PT(debug=false)
    welcome()
    control = Dict(
        "priority" => Dict("load" => true, "standards" => true,
                           "process" => true, "method" => true),
        "history" => DataFrame(task=String[],action=String[]),
        "chain" => ["top"]
    )
    while true
        dispatch!(control)
        if debug
            println(control["history"])
            println(control["chain"])
            println(keys(control))
        end
        if length(control["chain"])==0 return end
    end
end
export PT

function dispatch!(ctrl::AbstractDict)
    key = ctrl["chain"][end]
    (message,action) = tree(key,ctrl)
    if isa(message,Function)
        println(message(ctrl))
    else
        println(message)
    end
    response = readline()
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
    else
        push!(ctrl["chain"],next)
    end
    push!(ctrl["history"],[key,response])
end

function tree(key::AbstractString,ctrl::AbstractDict)
    branches = Dict(
        "top" => (
            message =
            "r: Read data files"*check(ctrl,"load")*"\n"*
            "m: Specify the method"*check(ctrl,"load")*"\n"*
            "t: Tabulate the samples\n"*
            "s: Mark standards"*check(ctrl,"standards")*"\n"*
            "b: Bulk settings\n"*
            "v: View and adjust each sample\n"*
            "p: Process the data"*check(ctrl,"process")*"\n"*
            "e: Export the results\n"*
            "l: Import/export a session log\n"*
            "x: Exit",
            action = Dict(
                "r" => "instrument",
                "m" => "method",
                "t" => TUItabulate,
                "s" => "standards",
                "b" => "bulk",
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
            message = "Enter the full path of the data directory, or x to exit:",
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

# /home/pvermees/git/Plasmatrace/test/data
function TUIload!(ctrl::AbstractDict,response::AbstractString)
    if response=="x"
        # do nothing
    else
        ctrl["run"] = load(response,instrument=ctrl["instrument"])
        ctrl["priority"]["load"] = false
    end
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
    end
    return "xx"
end

function TUItabulate(ctrl::AbstractDict)
    summarise(ctrl["run"])
end
