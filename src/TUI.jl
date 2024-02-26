function PT(debug=false)
    welcome()
    control = Dict(
        "priority" => Dict("load" => true, "standards" => true, "process" => true),
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
    println(message)
    response = readline()
    if isa(action,Function)
        next = action(ctrl,response)
    else
        next = action[response]
    end
    if next == "x"
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
            "s: Mark standards"*check(ctrl,"standards")*"\n"*
            "b: Bulk settings\n"*
            "v: View and adjust each sample\n"*
            "p: Process the data"*check(ctrl,"process")*"\n"*
            "e: Export the results\n"*
            "l: Import/export a session log\n"*
            "x: Exit",
            action = Dict(
                "r" => "instrument",
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
    if response=="x"
        # do nothing
    else
        ctrl["run"] = load(response,instrument=ctrl["instrument"])
    end
    return "xx"
end
